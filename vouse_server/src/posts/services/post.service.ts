// src/posts/services/post.service.ts
import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, MoreThan } from 'typeorm';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';

import { Post, PostStatus } from '../entities/post.entity';
import { CreatePostDto, UpdatePostDto } from '../dto/post.dto';

@Injectable()
export class PostService {
  private readonly logger = new Logger(PostService.name);

  constructor(
    @InjectRepository(Post)
    private readonly postRepository: Repository<Post>,
    @InjectQueue('post-publish')
    private readonly postPublishQueue: Queue,
  ) {}

  /**
   * Create a new post for a user
   *
   * By default, posts are scheduled according to their scheduledAt date.
   * Setting immediatePublish to true will bypass the queue and publish immediately.
   */
  async create(
    userId: string,
    createPostDto: CreatePostDto,
    immediatePublish: boolean = false,
  ): Promise<Post> {
    // Validate userId is not empty
    if (!userId || userId.trim() === '') {
      this.logger.error('Attempted to create post with empty userId');
      throw new Error('User ID cannot be empty');
    }

    this.logger.log(`Creating post for user ${userId}`);

    try {
      // Create post entity from DTO
      const post = this.postRepository.create({
        ...createPostDto,
        userId,
        status: PostStatus.SCHEDULED, // All posts start as scheduled
        // Convert scheduledAt string to Date if provided
        scheduledAt: createPostDto.scheduledAt
          ? new Date(createPostDto.scheduledAt)
          : null,
        // Parse arrays from strings if needed
        cloudImageUrls: Array.isArray(createPostDto.cloudImageUrls)
          ? createPostDto.cloudImageUrls
          : createPostDto.cloudImageUrls
            ? JSON.parse(createPostDto.cloudImageUrls as unknown as string)
            : [],
      });

      // Double-check that userId is properly set
      if (post.userId !== userId) {
        this.logger.warn(
          `userId mismatch after creation: ${post.userId} vs expected ${userId}`,
        );
        // Force set it again to ensure it's correct
        post.userId = userId;
      }

      // Log the post we're about to save
      this.logger.log(
        `Saving post with userId: ${post.userId}, postIdLocal: ${post.postIdLocal}`,
      );

      // Save post to database
      const savedPost = await this.postRepository.save(post);

      // If post is scheduled, add it to the publishing queue
      if (savedPost.status === PostStatus.SCHEDULED) {
        if (immediatePublish) {
          // Bypass the queue and publish immediately
          this.logger.log(
            `Immediate publishing requested for post ${savedPost.id}`,
          );

          try {
            // Import and use the post publish processor directly
            const { PostPublishProcessor } = await import(
              '../processors/post-publish.processor'
            );
            const xAuthService = await import(
              '../../x/services/x-auth.service'
            ).then((m) => m.XAuthService);
            const xClientService = await import(
              '../../x/services/x-client.service'
            ).then((m) => m.XClientService);
            const engagementService = await import(
              '../services/engagement.service'
            ).then((m) => m.EngagementService);
            const notificationService = await import(
              '../../notifications/services/notification.service'
            ).then((m) => m.NotificationService);

            // Create a temporary processor instance
            const processor = new PostPublishProcessor(
              this,
              new engagementService['__proto__.constructor'](),
              new xClientService['__proto__.constructor'](),
              new xAuthService['__proto__.constructor'](),
              new notificationService['__proto__.constructor'](),
            );

            // Create a mock job
            const mockJob = {
              id: `immediate-${savedPost.id}`,
              data: {
                postId: savedPost.id,
                userId: userId,
              },
            };

            // Process the job
            await processor.handlePublish(mockJob as any);
            this.logger.log(`Post ${savedPost.id} published immediately`);

            // Refresh post data
            return this.findOne(savedPost.id, userId);
          } catch (error) {
            this.logger.error(
              `Failed to publish post immediately: ${error.message}`,
              error.stack,
            );
            // Fall back to queue method
            await this.schedulePost(savedPost);
          }
        } else {
          // Normal queue-based scheduling
          await this.schedulePost(savedPost);
        }
      }

      return savedPost;
    } catch (error) {
      this.logger.error(`Failed to create post: ${error.message}`, error.stack);
      throw error;
    }
  }

  /**
   * Schedule a post for publishing in the queue
   *
   * This method handles:
   * - Converting dates to UTC for consistent calculations
   * - Calculating proper delay for scheduled posts
   * - Detecting "post now" requests
   * - Adding the job to the BullMQ queue
   * - Error handling and status updates
   *
   * @param post The post entity to be scheduled
   * @returns Promise<void>
   */
  /**
   * Manually publish a post immediately, bypassing the queue
   * Useful for testing and for users when the queue isn't working
   */
  async publishImmediately(postId: string, userId: string): Promise<Post> {
    this.logger.log(`Manual immediate publish requested for post ${postId}`);

    // Get the post
    const post = await this.findOne(postId, userId);

    // Verify it's not already published
    if (post.status === PostStatus.PUBLISHED) {
      throw new Error('Post is already published');
    }

    // Add to queue with no delay and high priority
    await this.postPublishQueue.add(
      'publish',
      {
        postId: post.id,
        userId: post.userId,
      },
      {
        jobId: `immediate-${post.id}`,
        delay: 0,
        priority: 1, // Higher priority
        attempts: 3,
        backoff: {
          type: 'exponential',
          delay: 10000, // Short delay between retries
        },
        removeOnComplete: true,
      },
    );

    this.logger.log(
      `Post ${post.id} added to publishing queue for immediate publication`,
    );

    // Update status to indicate it's being processed
    await this.update(post.id, userId, { status: PostStatus.SCHEDULED });

    // Get and return the updated post
    return this.findOne(post.id, userId);
  }

  /**
   * Schedule a post for publishing using the Bull queue
   */
  private async schedulePost(post: Post): Promise<void> {
    // Get current time in UTC for consistent comparison
    const now = new Date();

    this.logger.log(`schedulePost raw scheduledAt value: ${post.scheduledAt}`);
    this.logger.log(
      `schedulePost raw scheduledAt type: ${typeof post.scheduledAt}`,
    );

    // Check if scheduledAt is null, which means post immediately
    if (!post.scheduledAt) {
      this.logger.log(
        `Post ${post.id} set for immediate publishing (null scheduledAt)`,
      );

      try {
        // Add job to queue with no delay
        await this.postPublishQueue.add(
          'publish',
          {
            postId: post.id,
            userId: post.userId,
          },
          {
            jobId: `publish-${post.id}`,
            delay: 0,
            attempts: 3,
            backoff: {
              type: 'exponential',
              delay: 60000,
            },
            removeOnComplete: true,
          },
        );

        this.logger.log(
          `Post ${post.id} added to publishing queue for immediate publication`,
        );
      } catch (error) {
        this.handleSchedulingError(post.id, error);
      }

      return;
    }

    // Convert to proper Date object if it's a string, ensuring UTC interpretation
    let scheduledAt: Date;
    if (post.scheduledAt instanceof Date) {
      // Keep as is - it should already be in UTC from client
      scheduledAt = post.scheduledAt;
      this.logger.log(
        `schedulePost scheduledAt as ISO: ${scheduledAt.toISOString()}`,
      );
      this.logger.log(
        `schedulePost scheduledAt timestamp: ${scheduledAt.getTime()}`,
      );
    } else {
      // Parse the string as UTC
      scheduledAt = new Date(post.scheduledAt as unknown as string);
    }

    // Calculate delay in milliseconds
    const delayMs = Math.max(0, scheduledAt.getTime() - now.getTime());

    // Log both times for debugging
    this.logger.log(
      `Scheduling with times - Server now: ${now.toISOString()}, Scheduled time (UTC): ${scheduledAt.toISOString()}`,
    );

    // If scheduled time is in the past or very close (within 2 minutes), post immediately
    if (delayMs < 120000) {
      this.logger.log(
        `Post ${post.id} set for immediate publishing (scheduled time is very soon)`,
      );

      try {
        // Add job to queue with no delay
        await this.postPublishQueue.add(
          'publish',
          {
            postId: post.id,
            userId: post.userId,
          },
          {
            jobId: `publish-${post.id}`,
            delay: 0,
            attempts: 3,
            backoff: {
              type: 'exponential',
              delay: 60000,
            },
            removeOnComplete: true,
          },
        );

        this.logger.log(
          `Post ${post.id} added to publishing queue for immediate publication`,
        );
      } catch (error) {
        this.handleSchedulingError(post.id, error);
      }

      return;
    }

    // Log the actual times for debugging
    this.logger.log(
      `Time debug - Current: ${now.toISOString()}, Scheduled: ${scheduledAt.toISOString()}, Delay: ${delayMs}ms`,
    );

    try {
      // Add job to the queue with the calculated delay
      await this.postPublishQueue.add(
        'publish',
        {
          postId: post.id,
          userId: post.userId,
        },
        {
          jobId: `publish-${post.id}`,
          delay: delayMs,
          attempts: 3, // Retry up to 3 times if publishing fails
          backoff: {
            type: 'exponential',
            delay: 60000, // Start with 1 minute delay between retries
          },
          removeOnComplete: true,
        },
      );

      this.logger.log(
        `Post ${post.id} scheduled for publishing at ${scheduledAt.toISOString()} (delay: ${delayMs}ms)`,
      );
    } catch (error) {
      this.handleSchedulingError(post.id, error);
    }
  }

  /**
   * Helper method to handle scheduling errors
   */
  private async handleSchedulingError(
    postId: string,
    error: any,
  ): Promise<void> {
    const errorMessage = error instanceof Error ? error.message : String(error);
    this.logger.error(
      `Failed to schedule post ${postId}: ${errorMessage}`,
      error instanceof Error ? error.stack : undefined,
    );

    // Update post status to reflect scheduling failure
    await this.postRepository.update(postId, {
      status: PostStatus.FAILED,
      failureReason: `Failed to schedule: ${errorMessage}`,
    });
  }

  /**
   * Get all posts for a user
   */
  async findAllByUser(userId: string): Promise<Post[]> {
    return this.postRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * Get a single post by ID, ensuring it belongs to the user
   */
  async findOne(id: string, userId: string): Promise<Post> {
    const post = await this.postRepository.findOne({
      where: { id, userId },
    });

    if (!post) {
      throw new NotFoundException(`Post with ID ${id} not found`);
    }

    return post;
  }

  /**
   * Get a post by its local ID
   */
  async findOneByLocalId(postIdLocal: string, userId: string): Promise<Post> {
    const post = await this.postRepository.findOne({
      where: { postIdLocal, userId },
    });

    if (!post) {
      throw new NotFoundException(
        `Post with local ID ${postIdLocal} not found`,
      );
    }

    return post;
  }

  /**
   * Update a post
   */
  async update(
    id: string,
    userId: string,
    updatePostDto: UpdatePostDto,
  ): Promise<Post> {
    // First check if post exists and belongs to user
    const post = await this.findOne(id, userId);

    // Cannot update already published posts
    if (post.status === PostStatus.PUBLISHED) {
      throw new BadRequestException('Cannot update already published posts');
    }

    // Prepare update data with proper type conversions
    const updateData: Partial<Post> = {
      ...updatePostDto,
      // Convert scheduledAt string to Date if provided
      scheduledAt: updatePostDto.scheduledAt
        ? new Date(updatePostDto.scheduledAt)
        : undefined,
    };

    if (updatePostDto.scheduledAt) {
      this.logger.log(
        `Update received scheduledAt: ${updatePostDto.scheduledAt}`,
      );
    }

    // Handle JSON fields
    if (updatePostDto.cloudImageUrls) {
      updateData.cloudImageUrls = Array.isArray(updatePostDto.cloudImageUrls)
        ? updatePostDto.cloudImageUrls
        : JSON.parse(updatePostDto.cloudImageUrls as unknown as string);
    }

    // If scheduling changed, handle queue updates
    if (
      updatePostDto.scheduledAt !== undefined &&
      (!post.scheduledAt ||
        new Date(updatePostDto.scheduledAt).getTime() !==
          (post.scheduledAt instanceof Date
            ? post.scheduledAt.getTime()
            : new Date(post.scheduledAt as unknown as string).getTime()))
    ) {
      // Log both times for debugging
      this.logger.log(
        `Update comparing dates - Old: ${post.scheduledAt?.toISOString()}, New: ${new Date(updatePostDto.scheduledAt).toISOString()}`,
      );

      // Update status to SCHEDULED if it was a draft
      if (post.status === PostStatus.DRAFT) {
        updateData.status = PostStatus.SCHEDULED;
      }

      try {
        const job = await this.postPublishQueue.getJob(`publish-${post.id}`);
        if (job) {
          await job.remove();
          this.logger.log(`Removed existing job for post ${post.id}`);
        }
      } catch (error) {
        this.logger.warn(
          `Error removing job for post ${post.id}: ${error.message}`,
        );

        // Fallback to old method as safety
        const existingJobs = await this.postPublishQueue.getJobs([
          'delayed',
          'waiting',
        ]);
        for (const job of existingJobs) {
          const jobData = job.data;
          if (jobData.postId === post.id) {
            await job.remove();
            break;
          }
        }
      }
    }

    // Update the post
    await this.postRepository.update(id, updateData);

    // Get the updated post
    const updatedPost = await this.findOne(id, userId);

    // Reschedule if needed
    if (updatedPost.status === PostStatus.SCHEDULED) {
      await this.schedulePost(updatedPost);
    }

    return updatedPost;
  }

  /**
   * Delete a post
   */
  async remove(id: string, userId: string): Promise<void> {
    // First check if post exists and belongs to user
    const post = await this.findOne(id, userId);

    // Only allow deleting posts that are not yet published
    if (post.status === PostStatus.PUBLISHED) {
      throw new BadRequestException('Cannot delete already published posts');
    }

    // If scheduled, remove from queue first
    if (post.status === PostStatus.SCHEDULED) {
      try {
        const job = await this.postPublishQueue.getJob(`publish-${post.id}`);
        if (job) {
          await job.remove();
          this.logger.log(`Removed job for deleted post ${post.id}`);
        }
      } catch (error) {
        this.logger.warn(
          `Error removing job for post ${post.id}: ${error.message}`,
        );

        // Fallback to old method as safety
        const existingJobs = await this.postPublishQueue.getJobs([
          'delayed',
          'waiting',
        ]);
        for (const job of existingJobs) {
          const jobData = job.data;
          if (jobData.postId === post.id) {
            await job.remove();
            break;
          }
        }
      }
    }

    // Delete the post
    await this.postRepository.delete(id);
  }

  /**
   * Update a post's status after publishing
   */
  async updateAfterPublishing(
    id: string,
    postIdX: string | null,
    status: PostStatus,
    failureReason?: string,
  ): Promise<Post> {
    const updateData: Partial<Post> = {
      status,
      postIdX,
      publishedAt: status === PostStatus.PUBLISHED ? new Date() : null,
      failureReason: failureReason || null,
    };

    await this.postRepository.update(id, updateData);

    const post = await this.postRepository.findOne({ where: { id } });
    if (!post) {
      throw new NotFoundException(`Post with ID ${id} not found`);
    }

    return post;
  }
}
