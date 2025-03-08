// src/posts/services/engagement.service.ts
import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';

import { PostEngagement } from '../entities/engagement.entity';
import { Post } from '../entities/post.entity';
import { XClientService } from '../../x/services/x-client.service';

@Injectable()
export class EngagementService {
  public readonly logger = new Logger(EngagementService.name);

  constructor(
    @InjectRepository(PostEngagement)
    private engagementRepository: Repository<PostEngagement>,
    @InjectRepository(Post)
    private postRepository: Repository<Post>,
    @InjectQueue('metrics-collector')
    private metricsQueue: Queue,
    private xClientService: XClientService,
  ) {}

  /**
   * Initialize engagement tracking for a newly published post
   */
  async initializeEngagement(
    postIdX: string,
    postIdLocal: string,
    userId: string,
  ): Promise<PostEngagement> {
    // Create a new engagement record
    const engagement = this.engagementRepository.create({
      postIdX,
      postIdLocal,
      userId,
      likes: 0,
      retweets: 0,
      quotes: 0,
      replies: 0,
      impressions: 0,
      hourlyMetrics: [],
    });

    // Save the record
    const savedEngagement = await this.engagementRepository.save(engagement);

    // Schedule the first metrics collection
    await this.scheduleMetricsCollection(postIdX, userId);

    return savedEngagement;
  }

  /**
   * Schedule a metrics collection job
   */
  private async scheduleMetricsCollection(
    postIdX: string,
    userId: string,
  ): Promise<void> {
    try {
      // Add job to the queue with 30 minute delay for first collection
      await this.metricsQueue.add(
        'collect',
        {
          postIdX,
          userId,
        },
        {
          delay: 30 * 60 * 1000, // 30 minutes
          attempts: 3,
          backoff: {
            type: 'exponential',
            delay: 60000,
          },
          removeOnComplete: true,
        },
      );
    } catch (error) {
      this.logger.error(
        `Failed to schedule metrics collection for post ${postIdX}: ${error.message}`,
        error.stack,
      );
    }
  }

  /**
   * Get engagement metrics for a post
   */
  async getEngagement(
    postIdX: string,
    userId: string,
  ): Promise<PostEngagement> {
    const engagement = await this.engagementRepository.findOne({
      where: { postIdX, userId },
    });

    if (!engagement) {
      throw new NotFoundException(
        `Engagement data for post ${postIdX} not found`,
      );
    }

    return engagement;
  }

  /**
   * Get engagement metrics for a post by its local ID
   */
  async getEngagementByLocalId(
    postIdLocal: string,
    userId: string,
  ): Promise<PostEngagement> {
    const engagement = await this.engagementRepository.findOne({
      where: { postIdLocal, userId },
    });

    if (!engagement) {
      throw new NotFoundException(
        `Engagement data for local post ${postIdLocal} not found`,
      );
    }

    return engagement;
  }

  /**
   * Get engagement metrics for all of a user's posts
   */
  async getAllUserEngagements(userId: string): Promise<PostEngagement[]> {
    return this.engagementRepository.find({
      where: { userId },
      order: { updatedAt: 'DESC' },
    });
  }

  /**
   * Update engagement metrics for a post
   */
  async updateEngagement(
    postIdX: string,
    metrics: {
      likes?: number;
      retweets?: number;
      quotes?: number;
      replies?: number;
      impressions?: number;
    },
  ): Promise<PostEngagement> {
    const engagement = await this.engagementRepository.findOne({
      where: { postIdX },
    });

    if (!engagement) {
      throw new NotFoundException(
        `Engagement data for post ${postIdX} not found`,
      );
    }

    // Update metrics
    if (metrics.likes !== undefined) engagement.likes = metrics.likes;
    if (metrics.retweets !== undefined) engagement.retweets = metrics.retweets;
    if (metrics.quotes !== undefined) engagement.quotes = metrics.quotes;
    if (metrics.replies !== undefined) engagement.replies = metrics.replies;
    if (metrics.impressions !== undefined)
      engagement.impressions = metrics.impressions;

    // Add to hourly metrics for time series data
    engagement.hourlyMetrics.push({
      timestamp: new Date().toISOString(),
      metrics: {
        likes: engagement.likes,
        retweets: engagement.retweets,
        quotes: engagement.quotes,
        replies: engagement.replies,
        impressions: engagement.impressions,
      },
    });

    // Save the updated engagement
    return this.engagementRepository.save(engagement);
  }

  /**
   * Collect fresh metrics for a post from Twitter API
   */
  async collectFreshMetrics(
    postIdX: string,
    accessToken: string,
  ): Promise<PostEngagement> {
    try {
      // Fetch metrics from Twitter API
      const tweetData = await this.xClientService.getTweetMetrics(postIdX);

      // Extract metrics from the response
      const publicMetrics = tweetData.data.public_metrics || {};
      const nonPublicMetrics = tweetData.data.non_public_metrics || {};

      // Update engagement in database
      return this.updateEngagement(postIdX, {
        likes: publicMetrics.like_count || 0,
        retweets: publicMetrics.retweet_count || 0,
        quotes: publicMetrics.quote_count || 0,
        replies: publicMetrics.reply_count || 0,
        impressions: nonPublicMetrics.impression_count || 0,
      });
    } catch (error) {
      this.logger.error(
        `Failed to collect metrics for post ${postIdX}: ${error.message}`,
        error.stack,
      );
      throw error;
    }
  }
}
