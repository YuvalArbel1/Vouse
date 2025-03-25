// src/notifications/dto/notification.dto.ts

import { IsString, IsNotEmpty, IsIn } from 'class-validator';

export class RegisterDeviceTokenDto {
  @IsString()
  @IsNotEmpty()
  token: string;

  @IsString()
  @IsNotEmpty()
  @IsIn(['ios', 'android', 'web'])
  platform: string;
}
