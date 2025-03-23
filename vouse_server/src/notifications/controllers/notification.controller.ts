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
  Logger,
} from '@nestjs/common';
import { NotificationService } from '../services/notification.service';
import { FirebaseAuthGuard } from '../../auth/guards/firebase-auth';
import { CurrentUser } from '../../auth/decorators/current-user';
import { DecodedIdToken } from 'firebase-admin/auth';
import { RegisterDeviceTokenDto } from '../dto/notification.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { User } from '../../users/entities/user.entity';
import { Repository } from 'typeorm';

@Controller('notifications')
export class NotificationController {
  private readonly logger = new Logger(NotificationController.name);

  constructor(
    private readonly notificationService: NotificationService,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

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
      // Verify the user exists in the database
      const userExists = await this.userRepository.findOne({
        where: { userId: userId },
      });

      if (!userExists) {
        this.logger.warn(`User ${userId} not found in database when registering device token`);
        throw new HttpException(
          {
            success: false,
            message: 'User not found',
          },
          HttpStatus.NOT_FOUND,
        );
      }

      this.logger.log(`User ${userId} found, proceeding with device token registration`);

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
      this.logger.error(`Error registering device token: ${error.message}`, error.stack);
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to register device token',
        },
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
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
