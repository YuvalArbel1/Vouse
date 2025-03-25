// src/x/controllers/dto/x-auth.dto.ts
import { IsString, IsOptional, IsDateString } from 'class-validator';

/**
 * DTO for connecting a Twitter account
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
