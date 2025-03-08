// src/posts/controllers/engagement.controller.ts
import {
  Controller,
  Get,
  Post,
  Param,
  UseGuards,
  NotFoundException,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { EngagementService } from '../services/engagement.service';
import { FirebaseAuthGuard } from '../../auth/guards/firebase-auth';
import { CurrentUser } from '../../auth/decorators/current-user';
import { DecodedIdToken } from 'firebase-admin/auth';
import { XAuthService } from '../../x/services/x-auth.service';

@Controller('engagements')
export class EngagementController {
  constructor(
    private readonly engagementService: EngagementService,
    private readonly xAuthService: XAuthService,
  ) {}

  /**
   * Get all engagement metrics for the current user's posts
   */
  @Get()
  @UseGuards(FirebaseAuthGuard)
  async findAll(@CurrentUser() user: DecodedIdToken) {
    const engagements = await this.engagementService.getAllUserEngagements(
      user.uid,
    );
    return {
      success: true,
      data: engagements,
    };
  }

  /**
   * Get engagement metrics for a post by Twitter ID
   */
  @Get(':postIdX')
  @UseGuards(FirebaseAuthGuard)
  async findOne(
    @Param('postIdX') postIdX: string,
    @CurrentUser() user: DecodedIdToken,
  ) {
    try {
      const engagement = await this.engagementService.getEngagement(
        postIdX,
        user.uid,
      );
      return {
        success: true,
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
          message: error.message || 'Failed to get engagement data',
        },
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * Get engagement metrics for a post by its local ID
   */
  @Get('local/:postIdLocal')
  @UseGuards(FirebaseAuthGuard)
  async findOneByLocalId(
    @Param('postIdLocal') postIdLocal: string,
    @CurrentUser() user: DecodedIdToken,
  ) {
    try {
      const engagement = await this.engagementService.getEngagementByLocalId(
        postIdLocal,
        user.uid,
      );
      return {
        success: true,
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
          message: error.message || 'Failed to get engagement data',
        },
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * Force refresh engagement metrics for a post
   */
  @Post('refresh/:postIdX')
  @UseGuards(FirebaseAuthGuard)
  async refreshEngagement(
    @Param('postIdX') postIdX: string,
    @CurrentUser() user: DecodedIdToken,
  ) {
    try {
      // First check if the engagement exists and belongs to the user
      await this.engagementService.getEngagement(postIdX, user.uid);

      // Get user's tokens
      const tokens = await this.xAuthService.getUserTokens(user.uid);
      if (!tokens || !tokens.accessToken) {
        throw new HttpException(
          'Twitter tokens not found or invalid',
          HttpStatus.BAD_REQUEST,
        );
      }

      // Force refresh metrics
      const engagement = await this.engagementService.collectFreshMetrics(
        postIdX,
        tokens.accessToken,
      );

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
          message: error.message || 'Failed to refresh engagement metrics',
        },
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * Force refresh engagement metrics for a post by its local ID
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

      // Force refresh metrics using the Twitter ID from the found engagement
      const updatedEngagement =
        await this.engagementService.collectFreshMetrics(
          engagement.postIdX,
          tokens.accessToken,
        );

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
          message: error.message || 'Failed to refresh engagement metrics',
        },
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * Refresh all engagement metrics for the current user's posts
   */
  // src/posts/controllers/engagement.controller.ts

  @Post('refresh/all')
  @UseGuards(FirebaseAuthGuard)
  async refreshAllEngagements(@CurrentUser() user: DecodedIdToken) {
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
      // Explicitly type the array to fix the TypeScript error
      const refreshResults: Array<any> = [];
      const maxPostsToRefresh = 10; // Limit to avoid API rate limits

      for (
        let i = 0;
        i < Math.min(engagements.length, maxPostsToRefresh);
        i++
      ) {
        try {
          const updated = await this.engagementService.collectFreshMetrics(
            engagements[i].postIdX,
            tokens.accessToken,
          );
          refreshResults.push(updated);
        } catch (err) {
          // Continue with next post even if one fails
          console.error(
            `Failed to refresh metrics for post ${engagements[i].postIdX}: ${err.message}`,
          );
        }
      }

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
          message: error.message || 'Failed to refresh engagement metrics',
        },
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
