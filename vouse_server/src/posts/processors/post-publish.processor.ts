// src/posts/processors/post-publish.processor.ts
import { Process, Processor } from '@nestjs/bull';
import { Logger } from '@nestjs/common';
import { Job } from 'bull';
import axios from 'axios';

import { PostService } from '../services/post.service';
import { EngagementService } from '../services/engagement.service';
import { XClientService } from '../../x/services/x-client.service';
import { XAuthService } from '../../x/services/x-auth.service';
import { PostStatus } from '../entities/post.entity';

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

  @Process('publish')
  async handlePublish(job: Job<{ postId: string; userId: string }>) {
    const { postId, userId } = job.data;
    this.logger.log(`Starting to publish post ${postId} for user ${userId}`);

    try {
      // Get the post from the database
      const post = await this.postService.findOne(postId, userId);

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
      const mediaIds = [];
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
            this.logger.error(
              `Error processing image ${imageUrl}: ${error.message}`,
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
      const tweetId = result.data.id;

      // Update post status to PUBLISHED
      const updatedPost = await this.postService.updateAfterPublishing(
        postId,
        tweetId,
        PostStatus.PUBLISHED,
      );

      // Initialize engagement tracking
      await this.engagementService.initializeEngagement(
        tweetId,
        post.postIdLocal,
        userId,
      );

      this.logger.log(
        `Successfully published post ${postId} as tweet ${tweetId}`,
      );
      return updatedPost;
    } catch (error) {
      this.logger.error(
        `Failed to publish post ${postId}: ${error.message}`,
        error.stack,
      );

      // Update post status to FAILED
      await this.postService.updateAfterPublishing(
        postId,
        null,
        PostStatus.FAILED,
        error.message,
      );

      // Rethrow to trigger retry mechanism if needed
      throw error;
    }
  }
}
