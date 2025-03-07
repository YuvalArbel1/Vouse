// src/posts/processors/metrics-collector.processor.ts
import { Process, Processor } from '@nestjs/bull';
import { Logger } from '@nestjs/common';
import { Job } from 'bull';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';

import { EngagementService } from '../services/engagement.service';
import { XAuthService } from '../../x/services/x-auth.service';

@Processor('metrics-collector')
export class MetricsCollectorProcessor {
  private readonly logger = new Logger(MetricsCollectorProcessor.name);

  constructor(
    private readonly engagementService: EngagementService,
    private readonly xAuthService: XAuthService,
    @InjectQueue('metrics-collector')
    private readonly metricsQueue: Queue,
  ) {}

  @Process('collect')
  async handleMetricsCollection(job: Job<{ postIdX: string; userId: string }>) {
    const { postIdX, userId } = job.data;
    this.logger.log(
      `Collecting metrics for tweet ${postIdX} for user ${userId}`,
    );

    try {
      // Get user's Twitter tokens
      const tokens = await this.xAuthService.getUserTokens(userId);
      if (!tokens || !tokens.accessToken) {
        throw new Error('Twitter tokens not found or invalid');
      }

      // Collect metrics from Twitter API
      const engagement = await this.engagementService.collectFreshMetrics(
        postIdX,
        tokens.accessToken,
      );

      this.logger.log(`Successfully collected metrics for tweet ${postIdX}`);

      // Schedule next collection after appropriate delay
      // First day: every 2 hours, after that: every 6 hours for a week
      const hoursSinceCreation =
        (Date.now() - engagement.createdAt.getTime()) / (1000 * 60 * 60);

      const nextDelayHours = hoursSinceCreation < 24 ? 2 : 6;
      const totalHours = Math.round(hoursSinceCreation);

      // Stop after a week (168 hours)
      if (totalHours < 168) {
        await this.metricsQueue.add(
          'collect',
          {
            postIdX,
            userId,
          },
          {
            delay: nextDelayHours * 60 * 60 * 1000, // hours to milliseconds
            attempts: 3,
            backoff: {
              type: 'exponential',
              delay: 60000,
            },
            removeOnComplete: true,
          },
        );

        this.logger.log(
          `Scheduled next metrics collection for tweet ${postIdX} in ${nextDelayHours} hours`,
        );
      } else {
        this.logger.log(
          `Finished collecting metrics for tweet ${postIdX} after a week`,
        );
      }

      return engagement;
    } catch (error) {
      this.logger.error(
        `Failed to collect metrics for tweet ${postIdX}: ${error.message}`,
        error.stack,
      );

      // Even if metrics collection fails, we want to retry later
      // For safety, we'll schedule the next attempt with a larger delay
      await this.metricsQueue.add(
        'collect',
        {
          postIdX,
          userId,
        },
        {
          delay: 4 * 60 * 60 * 1000, // 4 hours
          attempts: 3,
          backoff: {
            type: 'exponential',
            delay: 60000,
          },
          removeOnComplete: true,
        },
      );

      // Rethrow to trigger current job's retry mechanism if needed
      throw error;
    }
  }
}
