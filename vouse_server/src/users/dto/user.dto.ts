// src/users/dto/user.dto.ts
import { IsString, IsOptional, IsBoolean, IsDateString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * DTO for creating a new user from Firebase authentication
 */
export class CreateUserDto {
  /**
   * User ID from Firebase Authentication
   */
  @ApiProperty({
    description: 'User ID from Firebase Authentication',
    example: 'firebaseUid123',
  })
  @IsString()
  userId: string = '';
}

/**
 * DTO for connecting a Twitter account to the user
 */
export class ConnectTwitterDto {
  /**
   * Twitter OAuth access token
   */
  @ApiProperty({
    description: 'Twitter OAuth access token',
    example: 'twitterAccessToken...',
  })
  @IsString()
  accessToken: string = '';

  /**
   * Twitter OAuth refresh token
   */
  @ApiPropertyOptional({
    description: 'Twitter OAuth refresh token (if available)',
    example: 'twitterRefreshToken...',
  })
  @IsString()
  @IsOptional()
  refreshToken?: string;

  /**
   * Expiration timestamp for the access token
   */
  @ApiPropertyOptional({
    description: 'ISO 8601 timestamp for access token expiration',
    example: '2025-03-29T18:00:00Z',
  })
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
  @ApiProperty({
    description: 'Whether the user is connected to Twitter',
    example: true,
  })
  @IsBoolean()
  isConnected: boolean = false;
}
