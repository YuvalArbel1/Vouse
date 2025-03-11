// src/notifications/controllers/notification.controller.ts

import {
  Controller,
  Post,
  Body,
  Param,
  Delete,
  UseGuards,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { NotificationService } from '../services/notification.service';
import { FirebaseAuthGuard } from '../../auth/guards/firebase-auth';
import { CurrentUser } from '../../auth/decorators/current-user';
import { DecodedIdToken } from 'firebase-admin/auth';
import { RegisterDeviceTokenDto } from '../dto/notification.dto';

@Controller('notifications')
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  @Post(':userId/register')
  @UseGuards(FirebaseAuthGuard)
  async registerDeviceToken(
    @Param('userId') userId: string,
    @Body() registerDeviceTokenDto: RegisterDeviceTokenDto,
    @CurrentUser() user: DecodedIdToken,
  ) {
    // Security check: users can only register their own device tokens
    if (user.uid !== userId) {
      throw new HttpException(
        {
          success: false,
          message: 'Unauthorized',
        },
        HttpStatus.UNAUTHORIZED,
      );
    }

    try {
      await this.notificationService.registerDeviceToken(
        userId,
        registerDeviceTokenDto.token,
        registerDeviceTokenDto.platform,
      );

      return {
        success: true,
        message: 'Device token registered successfully',
      };
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to register device token',
        },
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Delete(':userId/tokens/:token')
  @UseGuards(FirebaseAuthGuard)
  async unregisterDeviceToken(
    @Param('userId') userId: string,
    @Param('token') token: string,
    @CurrentUser() user: DecodedIdToken,
  ) {
    // Security check: users can only unregister their own device tokens
    if (user.uid !== userId) {
      throw new HttpException(
        {
          success: false,
          message: 'Unauthorized',
        },
        HttpStatus.UNAUTHORIZED,
      );
    }

    try {
      await this.notificationService.unregisterDeviceToken(userId, token);

      return {
        success: true,
        message: 'Device token unregistered successfully',
      };
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to unregister device token',
        },
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
