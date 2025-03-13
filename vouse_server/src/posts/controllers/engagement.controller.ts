// src/posts/controllers/engagement.controller.ts
import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  UseGuards,
  NotFoundException,
  HttpException,
  HttpStatus,
  Query,
} from '@nestjs/common';
import { EngagementService } from '../services/engagement.service';
import { FirebaseAuthGuard } from '../../auth/guards/firebase-auth';
import { CurrentUser } from '../../auth/decorators/current-user';
import { DecodedIdToken } from 'firebase-admin/auth';
import { XAuthService } from '../../x/services/x-auth.service';

/**
 * Controller for fetching and managing engagement metrics
 * Now includes caching to reduce API calls and support on-demand refreshing
 */
@Controller('engagements')
export class EngagementController {
  // Cache for storing metrics data to avoid excessive API calls
  private metricsCache: Map<string, { data: any; timestamp: number }> =
    new Map();
  // Cache expiration time - 5 minutes
  private readonly CACHE_TTL = 5 * 60 * 1000;

  constructor(
    private readonly engagementService: EngagementService,
    private readonly xAuthService: XAuthService,
  ) {}

  /**
   * Get all engagement metrics for the current user's posts
   * Uses caching to improve performance and reduce API calls
   *
   * @param user Current authenticated user
   * @param limit Optional parameter to limit the number of results
   * @param forceRefresh Whether to bypass the cache and force a fresh fetch
   */
  @Get()
  @UseGuards(FirebaseAuthGuard)
  async findAll(
    @CurrentUser() user: DecodedIdToken,
    @Query('limit') limit?: string,
    @Query('force_refresh') forceRefresh?: string,
  ) {
    const cacheKey = `all_engagements_${user.uid}_${limit || 'all'}`;
    const now = Date.now();

    // Use cache if available and not forcing refresh
    if (
      forceRefresh !== 'true' &&
      this.metricsCache.has(cacheKey) &&
      now - (this.metricsCache.get(cacheKey)?.timestamp || 0) < this.CACHE_TTL
    ) {
      const cachedData = this.metricsCache.get(cacheKey);
      if (cachedData) {
        return {
          success: true,
          data: cachedData.data,
          fromCache: true,
        };
      }
    }

    // Get fresh data
    const engagements = await this.engagementService.getAllUserEngagements(
      user.uid,
      limit ? parseInt(limit) : undefined,
    );

    // Update cache
    this.metricsCache.set(cacheKey, {
      data: engagements,
      timestamp: now,
    });

    return {
      success: true,
      data: engagements,
      fromCache: false,
    };
  }

  /**
   * Get engagement metrics for a post by Twitter ID
   * Uses caching to improve performance and reduce API calls
   *
   * @param postIdX Twitter post ID
   * @param user Current authenticated user
   * @param forceRefresh Whether to bypass the cache and force a fresh fetch
   */
  @Get(':postIdX')
  @UseGuards(FirebaseAuthGuard)
  async findOne(
    @Param('postIdX') postIdX: string,
    @CurrentUser() user: DecodedIdToken,
    @Query('force_refresh') forceRefresh?: string,
  ) {
    const cacheKey = `engagement_${postIdX}`;
    const now = Date.now();

    // Use cache if available and not forcing refresh
    if (
      forceRefresh !== 'true' &&
      this.metricsCache.has(cacheKey) &&
      now - (this.metricsCache.get(cacheKey)?.timestamp || 0) < this.CACHE_TTL
    ) {
      const cachedData = this.metricsCache.get(cacheKey);
      if (cachedData) {
        return {
          success: true,
          data: cachedData.data,
          fromCache: true,
        };
      }
    }

    try {
      const engagement = await this.engagementService.getEngagement(
        postIdX,
        user.uid,
      );

      // Update cache
      this.metricsCache.set(cacheKey, {
        data: engagement,
        timestamp: now,
      });

      return {
        success: true,
        data: engagement,
        fromCache: false,
      };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw new HttpException(
          {
            success: false,
            message: error.message,
          },
          HttpStatus.NOT_FOUND,
        );
      }
      throw new HttpException(
        {
          success: false,
          message:
            error instanceof Error
              ? error.message
              : 'Failed to get engagement data',
        },
        error instanceof HttpException
          ? error.getStatus()
          : HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * Get engagement metrics for a post by its local ID
   * Uses caching to improve performance
   *
   * @param postIdLocal Local post ID
   * @param user Current authenticated user
   * @param forceRefresh Whether to bypass the cache and force a fresh fetch
   */
  @Get('local/:postIdLocal')
  @UseGuards(FirebaseAuthGuard)
  async findOneByLocalId(
    @Param('postIdLocal') postIdLocal: string,
    @CurrentUser() user: DecodedIdToken,
    @Query('force_refresh') forceRefresh?: string,
  ) {
    const cacheKey = `engagement_local_${postIdLocal}`;
    const now = Date.now();

    // Use cache if available and not forcing refresh
    if (
      forceRefresh !== 'true' &&
      this.metricsCache.has(cacheKey) &&
      now - (this.metricsCache.get(cacheKey)?.timestamp || 0) < this.CACHE_TTL
    ) {
      const cachedData = this.metricsCache.get(cacheKey);
      if (cachedData) {
        return {
          success: true,
          data: cachedData.data,
          fromCache: true,
        };
      }
    }

    try {
      const engagement = await this.engagementService.getEngagementByLocalId(
        postIdLocal,
        user.uid,
      );

      // Update cache
      this.metricsCache.set(cacheKey, {
        data: engagement,
        timestamp: now,
      });

      // Also update the Twitter ID cache
      const twitterCacheKey = `engagement_${engagement.postIdX}`;
      this.metricsCache.set(twitterCacheKey, {
        data: engagement,
        timestamp: now,
      });

      return {
        success: true,
        data: engagement,
        fromCache: false,
      };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw new HttpException(
          {
            success: false,
            message: error.message,
          },
          HttpStatus.NOT_FOUND,
        );
      }
      throw new HttpException(
        {
          success: false,
          message:
            error instanceof Error
              ? error.message
              : 'Failed to get engagement data',
        },
        error instanceof HttpException
          ? error.getStatus()
          : HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * Force refresh engagement metrics for a post
   * Updates cache after refreshing
   *
   * @param postIdX Twitter post ID
   * @param user Current authenticated user
   */
  @Post('refresh/:postIdX')
  @UseGuards(FirebaseAuthGuard)
  async refreshEngagement(
    @Param('postIdX') postIdX: string,
    @CurrentUser() user: DecodedIdToken,
  ) {
    try {
      // First check if the engagement exists and belongs to the user
      const existingEngagement = await this.engagementService.getEngagement(
        postIdX,
        user.uid,
      );

      // Get user's tokens
      const tokens = await this.xAuthService.getUserTokens(user.uid);
      if (!tokens || !tokens.accessToken) {
        throw new HttpException(
          'Twitter tokens not found or invalid',
          HttpStatus.BAD_REQUEST,
        );
      }

      // Force refresh metrics - pass userId for token refresh
      const engagement = await this.engagementService.collectFreshMetrics(
        postIdX,
        tokens.accessToken,
        user.uid,
      );

      // Update cache
      const cacheKey = `engagement_${postIdX}`;
      this.metricsCache.set(cacheKey, {
        data: engagement,
        timestamp: Date.now(),
      });

      // Also update local ID cache if it exists
      const localCacheKey = `engagement_local_${existingEngagement.postIdLocal}`;
      if (this.metricsCache.has(localCacheKey)) {
        this.metricsCache.set(localCacheKey, {
          data: engagement,
          timestamp: Date.now(),
        });
      }

      // Invalidate the all engagements cache
      const allCacheKey = `all_engagements_${user.uid}_all`;
      if (this.metricsCache.has(allCacheKey)) {
        this.metricsCache.delete(allCacheKey);
      }

      return {
        success: true,
        message: 'Engagement metrics refreshed successfully',
        data: engagement,
      };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw new HttpException(
          {
            success: false,
            message: error.message,
          },
          HttpStatus.NOT_FOUND,
        );
      }
      throw new HttpException(
        {
          success: false,
          message:
            error instanceof Error
              ? error.message
              : 'Failed to refresh engagement metrics',
        },
        error instanceof HttpException
          ? error.getStatus()
          : HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * Force refresh engagement metrics for a post by its local ID
   * Updates cache after refreshing
   *
   * @param postIdLocal Local post ID
   * @param user Current authenticated user
   */
  @Post('refresh/local/:postIdLocal')
  @UseGuards(FirebaseAuthGuard)
  async refreshEngagementByLocalId(
    @Param('postIdLocal') postIdLocal: string,
    @CurrentUser() user: DecodedIdToken,
  ) {
    try {
      // Get the engagement record using local ID
      const engagement = await this.engagementService.getEngagementByLocalId(
        postIdLocal,
        user.uid,
      );

      // Get user's tokens
      const tokens = await this.xAuthService.getUserTokens(user.uid);
      if (!tokens || !tokens.accessToken) {
        throw new HttpException(
          'Twitter tokens not found or invalid',
          HttpStatus.BAD_REQUEST,
        );
      }

      // Force refresh metrics using the Twitter ID from the found engagement - pass userId for token refresh
      const updatedEngagement =
        await this.engagementService.collectFreshMetrics(
          engagement.postIdX,
          tokens.accessToken,
          user.uid,
        );

      // Update both caches
      const localCacheKey = `engagement_local_${postIdLocal}`;
      this.metricsCache.set(localCacheKey, {
        data: updatedEngagement,
        timestamp: Date.now(),
      });

      const twitterCacheKey = `engagement_${engagement.postIdX}`;
      this.metricsCache.set(twitterCacheKey, {
        data: updatedEngagement,
        timestamp: Date.now(),
      });

      // Invalidate the all engagements cache
      const allCacheKey = `all_engagements_${user.uid}_all`;
      if (this.metricsCache.has(allCacheKey)) {
        this.metricsCache.delete(allCacheKey);
      }

      return {
        success: true,
        message: 'Engagement metrics refreshed successfully',
        data: updatedEngagement,
      };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw new HttpException(
          {
            success: false,
            message: error.message,
          },
          HttpStatus.NOT_FOUND,
        );
      }
      throw new HttpException(
        {
          success: false,
          message:
            error instanceof Error
              ? error.message
              : 'Failed to refresh engagement metrics',
        },
        error instanceof HttpException
          ? error.getStatus()
          : HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * Refresh all engagement metrics for the current user's posts
   * Updates cache for all refreshed posts
   *
   * @param user Current authenticated user
   * @param limit Maximum number of posts to refresh
   */
  @Post('refreshall')
  @UseGuards(FirebaseAuthGuard)
  async refreshAllEngagements(
    @CurrentUser() user: DecodedIdToken,
    @Query('limit') limit?: string,
  ) {
    try {
      // Get user's tokens
      const tokens = await this.xAuthService.getUserTokens(user.uid);
      if (!tokens || !tokens.accessToken) {
        throw new HttpException(
          'Twitter tokens not found or invalid',
          HttpStatus.BAD_REQUEST,
        );
      }

      // Get all engagement records for the user
      const engagements = await this.engagementService.getAllUserEngagements(
        user.uid,
      );

      // Refresh metrics for each post (limit to avoid Twitter API rate limits)
      const refreshResults: Array<any> = [];
      const maxPostsToRefresh = limit ? parseInt(limit) : 10; // Default limit to 10 to avoid API rate limits
      const now = Date.now();

      for (
        let i = 0;
        i < Math.min(engagements.length, maxPostsToRefresh);
        i++
      ) {
        try {
          // Pass userId for token refresh
          const updated = await this.engagementService.collectFreshMetrics(
            engagements[i].postIdX,
            tokens.accessToken,
            user.uid,
          );
          refreshResults.push(updated);

          // Update cache for this post
          const twitterCacheKey = `engagement_${engagements[i].postIdX}`;
          this.metricsCache.set(twitterCacheKey, {
            data: updated,
            timestamp: now,
          });

          // Update local ID cache too
          const localCacheKey = `engagement_local_${engagements[i].postIdLocal}`;
          this.metricsCache.set(localCacheKey, {
            data: updated,
            timestamp: now,
          });
        } catch (err) {
          // Continue with next post even if one fails
          console.error(
            `Failed to refresh metrics for post ${engagements[i].postIdX}: ${err instanceof Error ? err.message : String(err)}`,
          );
        }
      }

      // Update the all engagements cache with fresh data
      const allCacheKey = `all_engagements_${user.uid}_all`;
      this.metricsCache.delete(allCacheKey); // Just delete it so next request will get fresh data

      return {
        success: true,
        message: `Refreshed metrics for ${refreshResults.length} posts`,
        data: refreshResults,
        total: engagements.length,
        refreshed: refreshResults.length,
      };
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message:
            error instanceof Error
              ? error.message
              : 'Failed to refresh engagement metrics',
        },
        error instanceof HttpException
          ? error.getStatus()
          : HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * Batch refresh multiple posts' engagement metrics
   * Efficient way to update metrics for multiple posts at once
   *
   * @param user Current authenticated user
   * @param body Request body containing an array of postIds to refresh
   */
  @Post('refresh/batch')
  @UseGuards(FirebaseAuthGuard)
  async refreshBatchEngagements(
    @CurrentUser() user: DecodedIdToken,
    @Body() body: { postIds: string[] },
  ) {
    try {
      // Get user's tokens
      const tokens = await this.xAuthService.getUserTokens(user.uid);
      if (!tokens || !tokens.accessToken) {
        throw new HttpException(
          'Twitter tokens not found or invalid',
          HttpStatus.BAD_REQUEST,
        );
      }

      const refreshResults: Array<any> = [];
      const failures: Array<any> = [];
      const now = Date.now();

      // Process each post ID
      for (const postIdX of body.postIds) {
        try {
          // Verify the post belongs to the user
          const existingEngagement = await this.engagementService.getEngagement(
            postIdX,
            user.uid,
          );

          // Refresh metrics - pass userId for token refresh
          const updated = await this.engagementService.collectFreshMetrics(
            postIdX,
            tokens.accessToken,
            user.uid,
          );

          refreshResults.push({
            postIdX,
            success: true,
            data: updated,
          });

          // Update cache for this post
          const twitterCacheKey = `engagement_${postIdX}`;
          this.metricsCache.set(twitterCacheKey, {
            data: updated,
            timestamp: now,
          });

          // Update local ID cache too
          const localCacheKey = `engagement_local_${existingEngagement.postIdLocal}`;
          this.metricsCache.set(localCacheKey, {
            data: updated,
            timestamp: now,
          });
        } catch (err) {
          failures.push({
            postIdX,
            success: false,
            error: err instanceof Error ? err.message : String(err),
          });
        }
      }

      // Update all_engagements cache
      const allCacheKey = `all_engagements_${user.uid}_all`;
      if (this.metricsCache.has(allCacheKey)) {
        this.metricsCache.delete(allCacheKey);
      }

      return {
        success: true,
        message: `Refreshed metrics for ${refreshResults.length} posts`,
        data: refreshResults,
        failures: failures,
        successCount: refreshResults.length,
        failureCount: failures.length,
      };
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message:
            error instanceof Error
              ? error.message
              : 'Failed to refresh engagement metrics',
        },
        error instanceof HttpException
          ? error.getStatus()
          : HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
