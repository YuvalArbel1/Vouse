// src/notifications/dto/notification.dto.ts
import { IsNotEmpty, IsString } from 'class-validator';

/**
 * DTO for registering a device token for push notifications
 */
export class RegisterDeviceTokenDto {
  /**
   * Device token for push notifications
   */
  @IsNotEmpty()
  @IsString()
  token: string = '';

  /**
   * Platform (iOS, Android, web)
   */
  @IsNotEmpty()
  @IsString()
  platform: string = '';
}
