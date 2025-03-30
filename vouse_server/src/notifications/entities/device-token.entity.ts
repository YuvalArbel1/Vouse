// src/notifications/entities/device-token.entity.ts
import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { ApiProperty } from '@nestjs/swagger';

/**
 * Device token entity for storing push notification tokens
 */
@Entity('device_tokens')
export class DeviceToken {
  /**
   * Primary key UUID
   */
  @ApiProperty({
    description: 'Primary key UUID for the device token record',
    example: 'a1b2c3d4-e5f6-7890-1234-567890abcdef',
  })
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /**
   * User ID the device token belongs to
   */
  @ApiProperty({
    description: 'Firebase User ID the token belongs to',
    example: 'firebaseUid123',
  })
  @Column({ name: 'user_id', type: 'text' })
  userId: string;

  /**
   * Relation to User entity
   */
  // @ApiProperty({ type: () => User }) // Avoid exposing full user object
  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User; // Consider removing eager loading if not needed

  /**
   * The device token string for push notifications
   */
  @ApiProperty({
    description: 'The FCM device token string',
    example: 'fcmTokenString...',
  })
  @Column({ type: 'text' })
  token: string;

  /**
   * The platform the token is for (iOS, Android, web)
   */
  @ApiProperty({
    description: 'The platform of the device',
    example: 'android',
    enum: ['ios', 'android', 'web'],
  })
  @Column({ type: 'text' })
  platform: string;

  /**
   * Creation timestamp
   */
  @ApiProperty({
    description: 'Timestamp when the token record was created',
    type: 'string',
    format: 'date-time',
  })
  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date = new Date();

  /**
   * Last update timestamp
   */
  @ApiProperty({
    description: 'Timestamp when the token record was last updated',
    type: 'string',
    format: 'date-time',
  })
  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date = new Date();
}
