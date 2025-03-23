// src/users/entities/user.entity.ts
import {
  Entity,
  Column,
  PrimaryColumn,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';

/**
 * User entity for storing user information
 * Includes Twitter/X integration data
 */
@Entity('users')
export class User {
  /**
   * Primary key - Firebase user ID
   */
  @PrimaryColumn({ name: 'user_id', type: 'text' })
  userId: string;

  /**
   * X/Twitter access token - stored as encrypted text
   */
  @Column({ name: 'access_token', type: 'text', nullable: true })
  accessToken: string | null = null;

  /**
   * X/Twitter refresh token - stored as encrypted text
   */
  @Column({ name: 'refresh_token', type: 'text', nullable: true })
  refreshToken: string | null = null;

  /**
   * X/Twitter token expiration date
   */
  @Column({ name: 'token_expires_at', type: 'timestamp', nullable: true })
  tokenExpiresAt: Date | null = null;

  /**
   * Whether the user is connected to X/Twitter
   */
  @Column({ name: 'is_connected', type: 'boolean', default: false })
  isConnected: boolean = false;

  /**
   * Creation timestamp
   */
  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date = new Date();

  /**
   * Last update timestamp
   */
  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date = new Date();
}
