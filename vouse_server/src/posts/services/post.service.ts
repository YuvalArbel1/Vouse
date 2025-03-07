// src/posts/services/post.service.ts
import { Injectable, Logger, NotFoundException } from '@nestjs/common';
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
    private postRepository: Repository<Post>,
    @InjectQueue('post-publish')
    private postPublishQueue: Queue,
  ) {}

  /**
   * Create a new post for a user
   */
  async create(userId: string, createPostDto: CreatePostDto): Promise<Post> {
    // Create post entity from DTO
    const post = this.postRepository.create({
      ...createPostDto,
      userId,
      status: createPostDto.scheduledAt
        ? PostStatus.SCHEDULED
        : PostStatus.DRAFT,
      // Parse arrays from strings if needed
      localImagePaths: Array.isArray(createPostDto.localImagePaths)
        ? createPostDto.localImagePaths
        : createPostDto.localImagePaths
          ? JSON.parse(createPostDto.localImagePaths as unknown as string)
          : [],
      cloudImageUrls: Array.isArray(createPostDto.cloudImageUrls)
        ? createPostDto.cloudImageUrls
        : createPostDto.cloudImageUrls
          ? JSON.parse(createPostDto.cloudImageUrls as unknown as string)
          : [],
    });

    // Save post to database
    const savedPost = await this.postRepository.save(post);

    // If post is scheduled, add it to the publishing queue
    if (savedPost.status === PostStatus.SCHEDULED && savedPost.scheduledAt) {
      await this.schedulePost(savedPost);
    }

    return savedPost;
  }

  /**
   * Schedule a post for publishing
   */
  private async schedulePost(post: Post): Promise<void> {
    const now = new Date();
    const scheduledTime = new Date(post.scheduledAt);

    // Calculate delay in milliseconds
    const delayMs = Math.max(0, scheduledTime.getTime() - now.getTime());

    try {
      // Add job to the queue with the calculated delay
      await this.postPublishQueue.add(
        'publish',
        {
          postId: post.id,
          userId: post.userId,
        },
        {
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
        `Post ${post.id} scheduled for publishing at ${scheduledTime.toISOString()}`,
      );
    } catch (error) {
      this.logger.error(
        `Failed to schedule post ${post.id}: ${error.message}`,
        error.stack,
      );
      // Update post status to reflect scheduling failure
      await this.postRepository.update(post.id, {
        status: PostStatus.FAILED,
        failureReason: `Failed to schedule: ${error.message}`,
      });
    }
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
      throw new Error('Cannot update already published posts');
    }

    // Prepare update data
    const updateData: Partial<Post> = { ...updatePostDto };

    // Handle JSON fields
    if (updatePostDto.localImagePaths) {
      updateData.localImagePaths = Array.isArray(updatePostDto.localImagePaths)
        ? updatePostDto.localImagePaths
        : JSON.parse(updatePostDto.localImagePaths as unknown as string);
    }

    if (updatePostDto.cloudImageUrls) {
      updateData.cloudImageUrls = Array.isArray(updatePostDto.cloudImageUrls)
        ? updatePostDto.cloudImageUrls
        : JSON.parse(updatePostDto.cloudImageUrls as unknown as string);
    }

    // If scheduling changed, handle queue updates
    if (
      updatePostDto.scheduledAt &&
      (!post.scheduledAt ||
        new Date(updatePostDto.scheduledAt).getTime() !==
          post.scheduledAt.getTime())
    ) {
      // Update status to SCHEDULED if it was a draft
      if (post.status === PostStatus.DRAFT) {
        updateData.status = PostStatus.SCHEDULED;
      }

      // Remove existing job if it exists
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

    // Update the post
    await this.postRepository.update(id, updateData);

    // Get the updated post
    const updatedPost = await this.findOne(id, userId);

    // Reschedule if needed
    if (
      updatedPost.status === PostStatus.SCHEDULED &&
      updatedPost.scheduledAt
    ) {
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

    // If scheduled, remove from queue first
    if (post.status === PostStatus.SCHEDULED) {
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

    // Delete the post
    await this.postRepository.delete(id);
  }

  /**
   * Update a post's status after publishing
   */
  async updateAfterPublishing(
    id: string,
    postIdX: string,
    status: PostStatus,
    failureReason?: string,
  ): Promise<Post> {
    const updateData: Partial<Post> = {
      status,
      postIdX,
      publishedAt: status === PostStatus.PUBLISHED ? new Date() : undefined,
      failureReason,
    };

    await this.postRepository.update(id, updateData);

    return this.postRepository.findOne({ where: { id } });
  }

  /**
   * Get posts scheduled for a specific time range
   */
  async findScheduledInRange(startDate: Date, endDate: Date): Promise<Post[]> {
    return this.postRepository.find({
      where: {
        status: PostStatus.SCHEDULED,
        scheduledAt: Between(startDate, endDate),
      },
      order: { scheduledAt: 'ASC' },
    });
  }

  /**
   * Get recently published posts for metrics collection
   */
  async findRecentlyPublished(hoursAgo: number = 24): Promise<Post[]> {
    const cutoffDate = new Date();
    cutoffDate.setHours(cutoffDate.getHours() - hoursAgo);

    return this.postRepository.find({
      where: {
        status: PostStatus.PUBLISHED,
        publishedAt: MoreThan(cutoffDate),
      },
      order: { publishedAt: 'DESC' },
    });
  }
}
