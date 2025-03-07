// src/posts/controllers/engagement.controller.ts
import {
  Controller,
  Get,
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

@Controller('engagements')
export class EngagementController {
  constructor(private readonly engagementService: EngagementService) {}

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
}
