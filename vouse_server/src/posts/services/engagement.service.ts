// src/posts/services/engagement.service.ts
import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Not, IsNull } from 'typeorm';

import { PostEngagement } from '../entities/engagement.entity';
import { Post } from '../entities/post.entity';
import { PostStatus } from '../entities/post.entity';
import { XClientService } from '../../x/services/x-client.service';

/**
 * Service for managing post engagement metrics
 * Enhanced with batch operations and utility methods
 */
@Injectable()
export class EngagementService {
  public readonly logger = new Logger(EngagementService.name);

  constructor(
    @InjectRepository(PostEngagement)
    private engagementRepository: Repository<PostEngagement>,
    @InjectRepository(Post)
    private postRepository: Repository<Post>,
    private xClientService: XClientService,
  ) {}

  /**
   * Initialize engagement tracking for a newly published post
   * Creates an empty record with default values
   *
   * @param postIdX Twitter post ID
   * @param postIdLocal Local app-generated post ID
   * @param userId User who owns the post
   * @returns The created engagement record
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

    // No automatic scheduling of metrics collection
    return savedEngagement;
  }

  /**
   * Get engagement metrics for a post by Twitter ID
   *
   * @param postIdX Twitter post ID
   * @param userId User who owns the post
   * @returns The engagement record
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
   *
   * @param postIdLocal Local app-generated post ID
   * @param userId User who owns the post
   * @returns The engagement record
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
   *
   * @param userId User ID to get engagements for
   * @param limit Optional limit on number of results
   * @returns Array of engagement records
   */
  async getAllUserEngagements(
    userId: string,
    limit?: number,
  ): Promise<PostEngagement[]> {
    const query = this.engagementRepository
      .createQueryBuilder('engagement')
      .where('engagement.userId = :userId', { userId })
      .orderBy('engagement.updatedAt', 'DESC');

    if (limit) {
      query.take(limit);
    }
    const a = await query.getMany();
    return a;
  }

  /**
   * Update engagement metrics for a post
   *
   * @param postIdX Twitter post ID
   * @param metrics Object containing metrics to update
   * @returns Updated engagement record
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
   *
   * @param postIdX Twitter post ID
   * @param accessToken User's Twitter access token
   * @param userId User's Firebase ID (for token refresh)
   * @returns Updated engagement record
   */
  async collectFreshMetrics(
    postIdX: string,
    accessToken: string,
    userId?: string,
  ): Promise<PostEngagement> {
    try {
      this.logger.log(`Collecting fresh metrics for tweet ${postIdX}`);

      // Fetch metrics from Twitter API - now passing userId for token refresh
      const response = await this.xClientService.getTweetMetrics(
        postIdX,
        accessToken,
        userId,
      );

      // Log the full response for debugging
      this.logger.log(`Full Twitter response: ${JSON.stringify(response)}`);

      // Check if we have data in the response
      if (!response.data) {
        throw new Error(`No data in Twitter response for tweet ${postIdX}`);
      }

      // Initialize metrics with default values
      let likes = 0,
        retweets = 0,
        quotes = 0,
        replies = 0,
        impressions = 0;

      // Extract from public_metrics (always available)
      if (response.data.public_metrics) {
        const metrics = response.data.public_metrics;
        this.logger.log(`Public metrics: ${JSON.stringify(metrics)}`);

        likes = metrics.like_count || 0;
        retweets = metrics.retweet_count || 0;
        quotes = metrics.quote_count || 0;
        replies = metrics.reply_count || 0;
        impressions = metrics.impression_count || 0;
      }

      // Try to get non-public metrics and use if higher
      if (response.data.non_public_metrics) {
        const metrics = response.data.non_public_metrics;
        this.logger.log(`Non-public metrics: ${JSON.stringify(metrics)}`);

        // Use the higher value for impressions
        if (
          metrics.impression_count &&
          metrics.impression_count > impressions
        ) {
          impressions = metrics.impression_count;
        }
      }

      // Also try organic metrics and use if higher
      if (response.data.organic_metrics) {
        const metrics = response.data.organic_metrics;
        this.logger.log(`Organic metrics: ${JSON.stringify(metrics)}`);

        // Use higher values for all metrics
        if (metrics.like_count && metrics.like_count > likes) {
          likes = metrics.like_count;
        }
        if (metrics.retweet_count && metrics.retweet_count > retweets) {
          retweets = metrics.retweet_count;
        }
        if (metrics.quote_count && metrics.quote_count > quotes) {
          quotes = metrics.quote_count;
        }
        if (metrics.reply_count && metrics.reply_count > replies) {
          replies = metrics.reply_count;
        }
        if (
          metrics.impression_count &&
          metrics.impression_count > impressions
        ) {
          impressions = metrics.impression_count;
        }
      }

      // Log the metrics we're about to save
      this.logger.log(
        `Saving metrics: likes=${likes}, retweets=${retweets}, quotes=${quotes}, replies=${replies}, impressions=${impressions}`,
      );

      // Update engagement in database with a direct query to ensure it works
      const engagement = await this.updateEngagement(postIdX, {
        likes,
        retweets,
        quotes,
        replies,
        impressions,
      });

      // Double-check that we actually updated the database
      const updatedEngagement = await this.engagementRepository.findOne({
        where: { postIdX },
      });

      this.logger.log(
        `Updated engagement in database: ${JSON.stringify(updatedEngagement)}`,
      );

      return engagement;
    } catch (error) {
      this.logger.error(
        `Failed to collect metrics for post ${postIdX}: ${error.message}`,
        error.stack,
      );
      throw error;
    }
  }
}
