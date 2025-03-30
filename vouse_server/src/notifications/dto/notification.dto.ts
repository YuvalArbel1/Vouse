// src/notifications/dto/notification.dto.ts
import { IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

/**
 * DTO for registering a device token for push notifications
 */
export class RegisterDeviceTokenDto {
  /**
   * Device token for push notifications
   */
  @ApiProperty({
    description: 'The FCM device token string',
    example: 'fcmTokenString...',
  })
  @IsNotEmpty()
  @IsString()
  token: string = '';

  /**
   * Platform (iOS, Android, web)
   */
  @ApiProperty({
    description: 'The platform of the device',
    example: 'android',
    enum: ['ios', 'android', 'web'],
  })
  @IsNotEmpty()
  @IsString()
  platform: string = '';
}
