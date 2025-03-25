// src/users/dto/user.dto.ts
import { IsString, IsOptional, IsBoolean, IsDateString } from 'class-validator';

/**
 * DTO for creating a new user from Firebase authentication
 */
export class CreateUserDto {
  /**
   * User ID from Firebase Authentication
   */
  @IsString()
  userId!: string;
}

/**
 * DTO for connecting a Twitter account to the user
 */
export class ConnectTwitterDto {
  /**
   * Twitter OAuth access token
   */
  @IsString()
  accessToken!: string;

  /**
   * Twitter OAuth refresh token
   */
  @IsString()
  refreshToken!: string;

  /**
   * Expiration timestamp for the access token
   */
  @IsDateString()
  @IsOptional()
  tokenExpiresAt?: string;
}

/**
 * DTO for updating user connection status
 */
export class UpdateConnectionStatusDto {
  /**
   * Whether the user is connected to Twitter
   */
  @IsBoolean()
  isConnected!: boolean;
}
