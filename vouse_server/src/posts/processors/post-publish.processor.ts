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

/**
 * Processor for handling post publishing queue jobs
 * Now only initializes engagement tracking without collecting initial metrics
 */
@Processor('post-publish')
export class PostPublishProcessor {
  private readonly logger = new Logger(PostPublishProcessor.name);

  constructor(
    private readonly postService: PostService,
    private readonly engagementService: EngagementService,
    private readonly xClientService: XClientService,
    private readonly xAuthService: XAuthService,
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

      // Update status to PUBLISHING
      await this.postService.update(postId, userId, {
        status: PostStatus.PUBLISHING,
      });

      // Get user's Twitter tokens
      const tokens = await this.xAuthService.getUserTokens(userId);
      if (!tokens || !tokens.accessToken) {
        throw new Error('Twitter tokens not found or invalid');
      }

      // Handle media uploads if present
      const mediaIds: string[] = [];
      if (post.cloudImageUrls && post.cloudImageUrls.length > 0) {
        for (const imageUrl of post.cloudImageUrls) {
          try {
            // Download the image from Firebase Storage URL
            const { base64Image, contentType } =
              await this.downloadImageFromUrl(imageUrl);

            // Upload to Twitter
            const mediaId = await this.xClientService.uploadMedia(
              tokens.accessToken,
              base64Image,
              contentType,
            );

            if (mediaId) {
              mediaIds.push(mediaId);
              this.logger.log(`Successfully uploaded media: ${mediaId}`);
            }
          } catch (error) {
            const errorMessage =
              error instanceof Error ? error.message : String(error);
            this.logger.error(
              `Error processing image ${imageUrl}: ${errorMessage}`,
            );
            // Continue with other images if one fails
          }
        }
      }

      // Publish the post to Twitter
      const result = await this.xClientService.postTweet(
        tokens.accessToken,
        post.content,
        mediaIds.length > 0 ? mediaIds : undefined,
      );

      // Get the tweet ID from the response
      const tweetId = result.data?.id || null;
      if (!tweetId) {
        throw new Error('Failed to get tweet ID from Twitter response');
      }

      // Update post status to PUBLISHED
      const updatedPost = await this.postService.updateAfterPublishing(
        postId,
        tweetId,
        PostStatus.PUBLISHED,
      );

      // Initialize engagement tracking without collecting initial metrics
      await this.engagementService.initializeEngagement(
        tweetId,
        post.postIdLocal,
        userId,
      );

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
