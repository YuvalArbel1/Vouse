
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

/**
 * Device token entity for storing push notification tokens
 */
@Entity('device_tokens')
export class DeviceToken {
  /**
   * Primary key UUID
   */
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /**
   * User ID the device token belongs to
   */
  @Column({ name: 'user_id', type: 'text' })
  userId: string;

  /**
   * Relation to User entity
   */
  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  /**
   * The device token string for push notifications
   */
  @Column({ type: 'text' })
  token: string;

  /**
   * The platform the token is for (iOS, Android, web)
   */
  @Column({ type: 'text' })
  platform: string;

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
