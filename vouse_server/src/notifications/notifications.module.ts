// src/notifications/notifications.module.ts

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { NotificationService } from './services/notification.service';
import { NotificationController } from './controllers/notification.controller';
import { DeviceToken } from './entities/device-token.entity';
import { User } from '../users/entities/user.entity';
import { AuthModule } from '../auth/auth.module';

@Module({
  /* This module provides services for its domain */
  imports: [TypeOrmModule.forFeature([DeviceToken, User]), AuthModule],
  providers: [NotificationService],
  controllers: [NotificationController],
  exports: [NotificationService],
})
export class NotificationsModule {}
