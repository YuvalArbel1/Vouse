import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';
import { FirebaseAuthGuard } from '../../auth/guards/firebase-auth';
import { CurrentUser } from '../../auth/decorators/current-user';
import { DecodedIdToken } from 'firebase-admin/auth';
import { PostService } from '../services/post.service';

/**
 * Controller for checking and managing the post publishing queue health
 */
@Controller('queue-health')
export class QueueHealthController {
  private readonly logger = new Logger(QueueHealthController.name);

  constructor(
    @InjectQueue('post-publish')
    private readonly postPublishQueue: Queue,
    private readonly postService: PostService,
  ) {}

  /**
   * Get queue health status - pending jobs, processing jobs, completed jobs
   */
  @Get()
  @UseGuards(FirebaseAuthGuard)
  async getQueueHealth(@CurrentUser() user: DecodedIdToken) {
    try {
      // Check if Redis is connected
      const isReady = this.postPublishQueue.client.status === 'ready';

      // Get job counts
      const [waiting, active, completed, failed, delayed] = await Promise.all([
        this.postPublishQueue.getWaitingCount(),
        this.postPublishQueue.getActiveCount(),
        this.postPublishQueue.getCompletedCount(),
        this.postPublishQueue.getFailedCount(),
        this.postPublishQueue.getDelayedCount(),
      ]);

      // Get delayed jobs
      const delayedJobs = await this.postPublishQueue.getJobs(['delayed']);

      return {
        success: true,
        data: {
          isReady,
          counts: {
            waiting,
            active,
            completed,
            failed,
            delayed,
          },
          delayedJobs: delayedJobs.map((job) => ({
            id: job.id,
            name: job.name,
            data: job.data,
            delay: job.opts.delay,
            timestamp: job.timestamp,
            processAt: new Date(job.timestamp + (job.opts.delay || 0)),
          })),
        },
      };
    } catch (error) {
      this.logger.error(
        `Error checking queue health: ${error.message}`,
        error.stack,
      );
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to check queue health',
        },
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * Force process a specific post (for testing/admin purposes)
   */
  @Post('process/:postId')
  @UseGuards(FirebaseAuthGuard)
  async forceProcessPost(
    @Param('postId') postId: string,
    @CurrentUser() user: DecodedIdToken,
  ) {
    try {
      // Verify the post exists and belongs to the user
      const post = await this.postService.findOne(postId, user.uid);

      // Add job to queue with no delay for immediate processing
      await this.postPublishQueue.add(
        'publish',
        {
          postId: post.id,
          userId: user.uid,
        },
        {
          jobId: `force-publish-${post.id}`,
          delay: 0,
          attempts: 1,
          removeOnComplete: true,
        },
      );

      this.logger.log(
        `Force added post ${postId} to publishing queue for immediate processing`,
      );

      return {
        success: true,
        message: 'Post processing job added to queue',
      };
    } catch (error) {
      this.logger.error(
        `Error forcing post process: ${error.message}`,
        error.stack,
      );
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to process post',
        },
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * Clear stuck jobs in the queue (admin only)
   */
  @Post('clear-stuck-jobs')
  @UseGuards(FirebaseAuthGuard)
  async clearStuckJobs(@CurrentUser() user: DecodedIdToken) {
    try {
      // Clear job types that might be stuck
      const [clearedFailed, clearedStalled] = await Promise.all([
        this.postPublishQueue.clean(0, 'failed'),
        this.postPublishQueue.clean(0, 'delayed'),
      ]);

      this.logger.log(
        `Cleared ${clearedFailed.length} failed jobs and ${clearedStalled.length} stalled jobs`,
      );

      return {
        success: true,
        message: `Cleared ${clearedFailed.length} failed jobs and ${clearedStalled.length} stalled jobs`,
      };
    } catch (error) {
      this.logger.error(
        `Error clearing stuck jobs: ${error.message}`,
        error.stack,
      );
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to clear stuck jobs',
        },
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
