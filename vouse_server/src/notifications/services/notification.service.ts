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

    // Validate userId is not empty
    if (!userId || userId.trim() === '') {
      throw new Error('User ID cannot be empty');
    }

    // Check if token already exists
    let deviceToken = await this.deviceTokenRepository.findOne({
      where: { token },
    });

    // If not, create a new one
    if (!deviceToken) {
      // Create with Repository to ensure proper entity creation
      deviceToken = this.deviceTokenRepository.create({
        userId,
        token,
        platform,
      });

      // Double-check userId is set properly
      if (deviceToken.userId !== userId) {
        this.logger.warn(
          `userId mismatch after creation: ${deviceToken.userId} vs expected ${userId}`,
        );
        // Force set it again
        deviceToken.userId = userId;
      }
    } else {
      // Update user ID and platform if needed
      deviceToken.userId = userId;
      deviceToken.platform = platform;
    }

    // Log the device token before saving to verify userId is set
    this.logger.log(
      `Saving device token with userId: ${deviceToken.userId}, token: ${deviceToken.token.substring(0, 10)}...`,
    );

    // Use query builder for more control over the insert operation
    try {
      // First check if the user exists in users table
      const userExists = await this.deviceTokenRepository.query(
        `SELECT 1 FROM users WHERE user_id = $1 LIMIT 1`,
        [userId],
      );

      if (!userExists || userExists.length === 0) {
        this.logger.error(
          `Failed to register device token: User ${userId} does not exist in the database`,
        );
        throw new Error(`User ${userId} does not exist in the database`);
      }

      if (!deviceToken.id) {
        // For new tokens, use direct query to ensure correct parameters
        this.logger.log(
          `Executing direct SQL insert for device token: userId=${userId}, token=${token.substring(0, 10)}...`,
        );

        const result = await this.deviceTokenRepository.query(
          `INSERT INTO device_tokens (user_id, token, platform, created_at, updated_at) 
           VALUES ($1, $2, $3, $4, $5) 
           RETURNING id`,
          [userId, token, platform, new Date(), new Date()],
        );

        if (!result || result.length === 0) {
          this.logger.error(
            'Device token insertion failed: No result returned from query',
          );
          throw new Error('Failed to insert device token');
        }

        deviceToken.id = result[0]?.id;
        this.logger.log(
          `Successfully inserted device token with ID: ${deviceToken.id}`,
        );
        return deviceToken;
      } else {
        // For existing tokens, use normal save
        this.logger.log(
          `Updating existing device token with ID: ${deviceToken.id}`,
        );
        return this.deviceTokenRepository.save(deviceToken);
      }
    } catch (error) {
      this.logger.error(
        `Failed to save device token: ${error.message}`,
        error.stack,
      );
      throw error;
    }
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
        `Sending post published notification for post ${post.id} (userId: ${post.userId}, postIdX: ${post.postIdX})`,
      );

      // Get all device tokens for this user
      const deviceTokens = await this.deviceTokenRepository.find({
        where: { userId: post.userId },
      });

      this.logger.log(
        `Found ${deviceTokens.length} device tokens for user ${post.userId}`,
      );

      if (deviceTokens.length === 0) {
        this.logger.log(`No device tokens found for user ${post.userId}`);
        return;
      }

      // Extract tokens
      const tokens = deviceTokens.map((dt) => dt.token);
      this.logger.log(
        `Processing tokens: ${tokens.map((t) => t.substring(0, 10) + '...').join(', ')}`,
      );

      // Get emoji based on post content
      const emoji = this.getPostEmoji(post.content);

      // Process tokens one by one to avoid type errors
      let successCount = 0;
      let failureCount = 0;
      const failedTokens: string[] = [];

      for (const token of tokens) {
        try {
          this.logger.log(
            `Preparing notification for token: ${token.substring(0, 10)}...`,
          );

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

          // Log the message for debugging
          this.logger.log(
            `Notification message: ${JSON.stringify({
              title: message.notification?.title,
              body: message.notification?.body,
              data: message.data,
            })}`,
          );

          // Add image URL if available
          const imageUrl = this.getImageUrlFromPost(post);
          if (imageUrl && message.apns) {
            message.apns.fcmOptions = {
              imageUrl,
            };
          }

          // Send the message
          this.logger.log(
            `Sending FCM message to Firebase for token: ${token.substring(0, 10)}...`,
          );
          const response = await admin.messaging().send(message);
          this.logger.log(`FCM message sent successfully: ${response}`);
          successCount++;
        } catch (error) {
          failureCount++;
          failedTokens.push(token);
          this.logger.error(
            `Failed to send notification to token: ${token.substring(0, 10)}..., error: ${error.message}`,
            error.stack,
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
