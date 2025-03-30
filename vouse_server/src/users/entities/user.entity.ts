// src/users/entities/user.entity.ts
import {
  Entity,
  Column,
  PrimaryColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
/**
 * User entity for storing user information
 * Includes Twitter/X integration data
 */
@Entity('users')
export class User {
  /**
   * Primary key - Firebase user ID
   */
  @ApiProperty({
    description: 'Primary key - Firebase user ID',
    example: 'firebaseUid123',
  })
  @PrimaryColumn({ name: 'user_id', type: 'text' })
  userId: string;

  /**
   * X/Twitter access token - stored as encrypted text
   */
  @ApiPropertyOptional({
    description: 'Encrypted X/Twitter access token',
    example: 'encrypted...',
  })
  @Column({ name: 'access_token', type: 'text', nullable: true })
  accessToken: string | null = null;

  /**
   * X/Twitter refresh token - stored as encrypted text
   */
  @ApiPropertyOptional({
    description: 'Encrypted X/Twitter refresh token',
    example: 'encrypted...',
  })
  @Column({ name: 'refresh_token', type: 'text', nullable: true })
  refreshToken: string | null = null;

  /**
   * X/Twitter token expiration date
   */
  @ApiPropertyOptional({
    description: 'Expiration timestamp for the X/Twitter access token',
    type: 'string',
    format: 'date-time',
    example: '2025-04-01T10:00:00Z',
  })
  @Column({ name: 'token_expires_at', type: 'timestamp', nullable: true })
  tokenExpiresAt: Date | null = null;

  /**
   * Whether the user is connected to X/Twitter
   */
  @ApiProperty({
    description: 'Whether the user is connected to X/Twitter',
    example: true,
    default: false,
  })
  @Column({ name: 'is_connected', type: 'boolean', default: false })
  isConnected: boolean = false;

  /**
   * Creation timestamp
   */
  @ApiProperty({
    description: 'Timestamp when the user record was created',
    type: 'string',
    format: 'date-time',
  })
  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date = new Date();

  /**
   * Last update timestamp
   */
  @ApiProperty({
    description: 'Timestamp when the user record was last updated',
    type: 'string',
    format: 'date-time',
  })
  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date = new Date();
}
