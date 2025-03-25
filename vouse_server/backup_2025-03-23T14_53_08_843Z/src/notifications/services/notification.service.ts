// src/notifications/services/notification.service.ts

import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DeviceToken } from '../entities/device-token.entity';
import * as admin from 'firebase-admin';
import { Post } from '../../posts/entities/post.entity';

/**
 * Service responsible for managing device tokens and sending push notifications
 */
@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    @InjectRepository(DeviceToken)
    private readonly deviceTokenRepository: Repository<DeviceToken>,
  ) {}

  /**
   * Register a device token for push notifications
   */
  async registerDeviceToken(
    userId: string,
    token: string,
    platform: string,
  ): Promise<DeviceToken> {
    this.logger.log(`Registering device token for user ${userId}`);

    // Check if token already exists
    let deviceToken = await this.deviceTokenRepository.findOne({
      where: { token },
    });

    // If not, create a new one
    if (!deviceToken) {
      deviceToken = this.deviceTokenRepository.create({
        userId,
        token,
        platform,
      });
    } else {
      // Update user ID and platform if needed
      deviceToken.userId = userId;
      deviceToken.platform = platform;
    }

    return this.deviceTokenRepository.save(deviceToken);
  }

  /**
   * Unregister a device token
   */
  async unregisterDeviceToken(userId: string, token: string): Promise<void> {
    this.logger.log(`Unregistering device token for user ${userId}`);

    await this.deviceTokenRepository.delete({
      userId,
      token,
    });
  }

  /**
   * Send a notification when a post is published
   */
  async sendPostPublishedNotification(post: Post): Promise<void> {
    try {
      this.logger.log(
        `Sending post published notification for post ${post.id}`,
      );

      // Get all device tokens for this user
      const deviceTokens = await this.deviceTokenRepository.find({
        where: { userId: post.userId },
      });

      if (deviceTokens.length === 0) {
        this.logger.log(`No device tokens found for user ${post.userId}`);
        return;
      }

      // Extract tokens
      const tokens = deviceTokens.map((dt) => dt.token);

      // Get emoji based on post content
      const emoji = this.getPostEmoji(post.content);

      // Process tokens one by one to avoid type errors
      let successCount = 0;
      let failureCount = 0;
      const failedTokens: string[] = [];

      for (const token of tokens) {
        try {
          // Create the message for a single token
          const message: admin.messaging.Message = {
            token: token,
            notification: {
              title: `Post Published! ${emoji}`,
              body: post.title
                ? `Your post "${post.title}" has been published to Twitter.`
                : 'Your post has been published to Twitter.',
            },
            data: {
              postIdLocal: post.postIdLocal,
              postIdX: post.postIdX || '',
              type: 'post_published',
              createdAt: new Date().toISOString(),
            },
            android: {
              notification: {
                channelId: 'post_published_channel',
                color: '#6C56F9',
                priority: 'high',
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1,
                },
              },
            },
          };

          // Add image URL if available
          const imageUrl = this.getImageUrlFromPost(post);
          if (imageUrl && message.apns) {
            message.apns.fcmOptions = {
              imageUrl,
            };
          }

          // Send the message
          await admin.messaging().send(message);
          successCount++;
        } catch (error) {
          failureCount++;
          failedTokens.push(token);
          this.logger.error(
            `Failed to send notification to token: ${token}, error: ${error.message}`,
          );
        }
      }

      this.logger.log(
        `Notification sent to ${successCount} devices, failed: ${failureCount}`,
      );

      // Remove failed tokens
      if (failedTokens.length > 0) {
        this.logger.log(`Removing ${failedTokens.length} failed tokens`);
        await Promise.all(
          failedTokens.map((token) =>
            this.deviceTokenRepository.delete({ token }),
          ),
        );
      }
    } catch (error) {
      this.logger.error(
        `Error sending notification for post ${post.id}: ${error.message}`,
        error.stack,
      );
    }
  }

  /**
   * Get an appropriate emoji for the post content
   */
  private getPostEmoji(content: string): string {
    const contentLower = content.toLowerCase();

    if (
      contentLower.includes('celebrate') ||
      contentLower.includes('achievement') ||
      contentLower.includes('win') ||
      contentLower.includes('congratulations')
    ) {
      return '🎉';
    } else if (
      contentLower.includes('announcement') ||
      contentLower.includes('news')
    ) {
      return '📢';
    } else if (
      contentLower.includes('launch') ||
      contentLower.includes('release')
    ) {
      return '🚀';
    } else if (
      contentLower.includes('update') ||
      contentLower.includes('upgrade')
    ) {
      return '⬆️';
    } else if (
      contentLower.includes('idea') ||
      contentLower.includes('thought')
    ) {
      return '💡';
    } else {
      return '🐦'; // Default Twitter bird
    }
  }

  /**
   * Get an image URL from the post if available
   */
  private getImageUrlFromPost(post: Post): string | undefined {
    if (post.cloudImageUrls && post.cloudImageUrls.length > 0) {
      return post.cloudImageUrls[0]; // Return the first image URL
    }
    return undefined;
  }
}
