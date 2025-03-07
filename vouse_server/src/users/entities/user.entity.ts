// src/users/entities/user.entity.ts
import {
  Entity,
  Column,
  PrimaryColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

/**
 * User entity for storing user data and Twitter tokens
 */
@Entity('users')
export class User {
  /**
   * User ID from Firebase Authentication
   * This serves as our primary key
   */
  @PrimaryColumn()
  userId: string;

  /**
   * Encrypted Twitter OAuth access token
   */
  @Column({ nullable: true })
  accessToken: string;

  /**
   * Encrypted Twitter OAuth refresh token
   */
  @Column({ nullable: true })
  refreshToken: string;

  /**
   * Timestamp when the access token expires
   */
  @Column({ nullable: true })
  tokenExpiresAt: Date;

  /**
   * Flag indicating if the user has connected their Twitter account
   */
  @Column({ default: false })
  isConnected: boolean;

  /**
   * When the user record was created
   */
  @CreateDateColumn()
  createdAt: Date;

  /**
   * When the user record was last updated
   */
  @UpdateDateColumn()
  updatedAt: Date;
}
