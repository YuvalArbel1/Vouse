// // src/posts/processors/metrics-collector.processor.ts
// import { Process, Processor } from '@nestjs/bull';
// import { Logger } from '@nestjs/common';
// import { Job } from 'bull';
// import { InjectQueue } from '@nestjs/bull';
// import { Queue } from 'bull';
//
// import { EngagementService } from '../services/engagement.service';
// import { XAuthService } from '../../x/services/x-auth.service';
//
// /**
//  * Processor that handles collecting metrics for posts
//  * Now operates on-demand only without scheduling recurring jobs
//  */
// @Processor('metrics-collector')
// export class MetricsCollectorProcessor {
//   private readonly logger = new Logger(MetricsCollectorProcessor.name);
//
//   constructor(
//     private readonly engagementService: EngagementService,
//     private readonly xAuthService: XAuthService,
//     @InjectQueue('metrics-collector')
//     private readonly metricsQueue: Queue,
//   ) {}
//
//   /**
//    * Process a metrics collection job for a specific tweet
//    * This method handles fetching and storing the latest metrics for a post
//    * It no longer schedules repeated collection automatically.
//    *
//    * @param job The Bull job containing postIdX and userId
//    * @returns The updated engagement record
//    */
//   @Process('collect')
//   async handleMetricsCollection(job: Job<{ postIdX: string; userId: string }>) {
//     const { postIdX, userId } = job.data;
//     this.logger.log(
//       `Collecting metrics for tweet ${postIdX} for user ${userId}`,
//     );
//
//     try {
//       // Get user's Twitter tokens
//       const tokens = await this.xAuthService.getUserTokens(userId);
//       if (!tokens || !tokens.accessToken) {
//         throw new Error('Twitter tokens not found or invalid');
//       }
//
//       // Collect metrics from Twitter API
//       const engagement = await this.engagementService.collectFreshMetrics(
//         postIdX,
//         tokens.accessToken,
//       );
//
//       this.logger.log(`Successfully collected metrics for tweet ${postIdX}`);
//
//       // Return the updated engagement data without scheduling next collection
//       return engagement;
//     } catch (error) {
//       this.logger.error(
//         `Failed to collect metrics for tweet ${postIdX}: ${error.message}`,
//         error.stack,
//       );
//
//       // Rethrow to trigger current job's retry mechanism if needed
//       throw error;
//     }
//   }
// }
