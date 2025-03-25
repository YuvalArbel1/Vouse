// src/posts/processors/post-publish.processor.ts
import { Process, Processor } from '@nestjs/bull';
import { Logger, NotFoundException } from '@nestjs/common';
import { Job } from 'bull';
import axios from 'axios';

import { PostService } from '../services/post.service';
import { EngagementService } from '../services/engagement.service';
import { XClientService } from '../../x/services/x-client.service';
import { XAuthService } from '../../x/services/x-auth.service';
import { PostStatus } from '../entities/post.entity';
import { NotificationService } from '../../notifications/services/notification.service';

/**
 * Processor for handling post publishing queue jobs
 *
 * This processor:
 * - Manages the tweet publishing workflow
 * - Handles media uploads for images
 * - Supports location data in tweets as text
 * - Creates engagement tracking for published posts
 * - Manages error handling and retry logic
 */
@Processor('post-publish')
export class PostPublishProcessor {
  private readonly logger = new Logger(PostPublishProcessor.name);

  constructor(
    private readonly postService: PostService,
    private readonly engagementService: EngagementService,
    private readonly xClientService: XClientService,
    private readonly xAuthService: XAuthService,
    private readonly notificationService: NotificationService,
  ) {}

  /**
   * Downloads an image from a Firebase Storage URL
   * @param url Firebase Storage URL
   * @returns Base64 encoded image and MIME type
   */
  private async downloadImageFromUrl(
    url: string,
  ): Promise<{ base64Image: string; contentType: string }> {
    try {
      this.logger.log(`Downloading image from ${url}`);
      const response = await axios.get(url, { responseType: 'arraybuffer' });

      // Get content type from response headers
      const contentType = response.headers['content-type'] || 'image/jpeg';

      // Convert array buffer to base64
      const base64Image = Buffer.from(response.data).toString('base64');

      return { base64Image, contentType };
    } catch (error) {
      this.logger.error(
        `Failed to download image from ${url}: ${error.message}`,
      );
      throw new Error(`Failed to download image: ${error.message}`);
    }
  }

  /**
   * Handle the publishing of a post to Twitter
   * Creates and uploads media if needed, publishes the post, and initializes engagement tracking
   *
   * @param job The Bull job containing postId and userId
   * @returns The updated post object after publishing
   */
  @Process('publish')
  async handlePublish(job: Job<{ postId: string; userId: string }>) {
    const { postId, userId } = job.data;
    this.logger.log(`Starting to publish post ${postId} for user ${userId}`);

    // Enhanced debugging for queue processing
    this.logger.log(
      `Job received: ${JSON.stringify({
        id: job.id,
        name: job.name,
        data: job.data,
        opts: job.opts,
      })}`,
    );

    try {
      // Get the post from the database with error handling
      let post;
      try {
        post = await this.postService.findOne(postId, userId);
      } catch (error) {
        if (error instanceof NotFoundException) {
          // Post doesn't exist anymore, log and exit gracefully
          this.logger.warn(
            `Post ${postId} for user ${userId} no longer exists, skipping publication`,
          );
          return null; // Return early, don't try to update a non-existent post
        }
        // For other errors, rethrow
        throw error;
      }

      // Update status to indicate publishing in progress
      await this.postService.update(postId, userId, {
        status: PostStatus.SCHEDULED, // Use SCHEDULED as intermediate state since PUBLISHING doesn't exist
      });

      // Get user's Twitter tokens
      const tokens = await this.xAuthService.getUserTokens(userId);
      if (!tokens || !tokens.accessToken) {
        throw new Error('Twitter tokens not found or invalid');
      }

      // Handle media uploads if present
      const mediaIds: string[] = [];
      let mediaUploadFailed = false;

      if (post.cloudImageUrls && post.cloudImageUrls.length > 0) {
        this.logger.log(
          `Post has ${post.cloudImageUrls.length} images to upload`,
        );

        for (const imageUrl of post.cloudImageUrls) {
          try {
            // Download the image from Firebase Storage URL
            this.logger.log(
              `Downloading image from ${imageUrl.substring(0, 50)}...`,
            );
            const { base64Image, contentType } =
              await this.downloadImageFromUrl(imageUrl);

            this.logger.log(
              `Successfully downloaded image, content type: ${contentType}, size: ${base64Image.length} bytes`,
            );

            // Upload to Twitter using v1.1 API
            this.logger.log(
              `Uploading media to Twitter using v1.1 API for user ${userId}`,
            );
            const mediaId = await this.xClientService.uploadMedia(
              userId,
              base64Image,
              contentType,
            );

            if (mediaId) {
              mediaIds.push(mediaId);
              this.logger.log(`Successfully uploaded media: ${mediaId}`);
            } else {
              this.logger.warn(
                `Twitter returned null media ID for image ${imageUrl.substring(0, 20)}...`,
              );
              mediaUploadFailed = true;
            }
          } catch (error) {
            mediaUploadFailed = true;
            const errorMessage =
              error instanceof Error ? error.message : String(error);
            this.logger.error(
              `Error processing image ${imageUrl.substring(0, 20)}...: ${errorMessage}`,
              error instanceof Error ? error.stack : undefined,
            );
            // Continue with other images if one fails
          }
        }
      }

      if (mediaUploadFailed && mediaIds.length === 0) {
        this.logger.warn(
          `All image uploads failed, proceeding with text-only post`,
        );
      } else if (mediaUploadFailed) {
        this.logger.warn(
          `Some image uploads failed, proceeding with ${mediaIds.length} images`,
        );
      }

      // Check for location data and log it if present
      let locationAddress = null;
      if (post.locationLat && post.locationLng && post.locationAddress) {
        this.logger.log(
          `Post has location data: ${post.locationLat},${post.locationLng} (${post.locationAddress})`,
        );
        locationAddress = post.locationAddress;
      }

      // Prepare post content with location if available
      let tweetText = post.content;
      if (locationAddress) {
        tweetText += `\n📍 ${locationAddress}`;
      }

      // Publish the post to Twitter
      this.logger.log(
        `Posting tweet with text: "${tweetText.substring(0, 30)}..." and ${mediaIds.length} media items`,
      );
      const result = await this.xClientService.postTweet(
        userId,
        tweetText,
        mediaIds.length > 0 ? mediaIds : undefined,
      );

      // Get the tweet ID from the response
      const tweetId = result && result.data ? result.data.id : null;
      if (!tweetId) {
        throw new Error('Failed to get tweet ID from Twitter response');
      }

      // Update post status to PUBLISHED
      this.logger.log(
        `Updating post status to PUBLISHED, tweet ID: ${tweetId}`,
      );
      const updatedPost = await this.postService.updateAfterPublishing(
        postId,
        tweetId,
        PostStatus.PUBLISHED,
      );

      // Initialize engagement tracking without collecting initial metrics
      try {
        this.logger.log(
          `Initializing engagement tracking for tweet ${tweetId}, local ID: ${post.postIdLocal}`,
        );
        await this.engagementService.initializeEngagement(
          tweetId,
          post.postIdLocal,
          userId,
        );
        this.logger.log(`Successfully initialized engagement tracking`);
      } catch (engagementError) {
        // Log but don't fail - post is still published
        this.logger.error(
          `Failed to initialize engagement tracking: ${engagementError.message}`,
          engagementError.stack,
        );
      }

      if (tweetId && updatedPost.status === PostStatus.PUBLISHED) {
        try {
          // Send notification
          await this.notificationService.sendPostPublishedNotification(
            updatedPost,
          );
          this.logger.log(
            `Sent post published notification for post ${postId}`,
          );
        } catch (error) {
          // Just log the error but don't fail the entire process
          this.logger.error(`Failed to send notification: ${error.message}`);
        }
      }
      // Log successful publication
      this.logger.log(
        `Successfully published post ${postId} as tweet ${tweetId}`,
      );
      return updatedPost;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      this.logger.error(
        `Failed to publish post ${postId}: ${errorMessage}`,
        error instanceof Error ? error.stack : undefined,
      );

      try {
        // Only try to update if the error wasn't a NotFoundException
        await this.postService.updateAfterPublishing(
          postId,
          null,
          PostStatus.FAILED,
          errorMessage,
        );
      } catch (updateError) {
        // Just log if the update fails too, don't throw a new error
        this.logger.warn(
          `Failed to update status for post ${postId}: ${updateError.message}`,
        );
      }

      // Rethrow to trigger retry mechanism if needed
      throw error;
    }
  }
}
