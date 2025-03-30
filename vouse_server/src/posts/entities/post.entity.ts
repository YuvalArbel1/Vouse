// src/posts/entities/post.entity.ts
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
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

// Post status enum
export enum PostStatus {
  DRAFT = 'draft',
  SCHEDULED = 'scheduled',
  PUBLISHED = 'published',
  FAILED = 'failed',
}

/**
 * Post entity for storing social media posts
 * Includes scheduling, content, and metadata
 */
@Entity('posts')
export class Post {
  /**
   * Primary key UUID
   */
  @ApiProperty({
    description: 'Primary key UUID for the post',
    example: 'a1b2c3d4-e5f6-7890-1234-567890abcdef',
  })
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /**
   * Client-generated unique ID for the post
   * Used for tracking the post across client and server
   */
  @ApiProperty({
    description: 'Client-generated unique ID for tracking',
    example: 'local-uuid-123',
  })
  @Column({ name: 'post_id_local', type: 'text', unique: true })
  postIdLocal: string;

  /**
   * X/Twitter post ID for published posts
   */
  @ApiPropertyOptional({
    description: 'X/Twitter post ID after publication',
    example: '1773600000000000000',
  })
  @Column({ name: 'post_id_x', type: 'text', nullable: true })
  postIdX: string | null = null;

  /**
   * User ID who created the post
   */
  @ApiProperty({
    description: 'Firebase User ID of the post creator',
    example: 'firebaseUid123',
  })
  @Column({ name: 'user_id', type: 'text' })
  userId: string;

  /**
   * Relation to User entity
   */
  @ManyToOne(() => User, { eager: true })
  @JoinColumn({ name: 'user_id' })
  user: User;

  /**
   * Post content/message
   */
  @ApiProperty({
    description: 'The main text content of the post',
    example: 'Hello Twitter!',
  })
  @Column({ type: 'text' })
  content: string;

  /**
   * Optional post title
   */
  @ApiPropertyOptional({
    description: 'An optional internal title for the post',
    example: 'My First Vouse Post',
  })
  @Column({ type: 'text', nullable: true })
  title: string | null = null;

  /**
   * Scheduled publication date for the post
   */
  @ApiPropertyOptional({
    description:
      'ISO 8601 timestamp when the post is scheduled for publication',
    type: 'string',
    format: 'date-time',
    example: '2025-04-01T10:00:00Z',
  })
  @Column({ name: 'scheduled_at', type: 'timestamp', nullable: true })
  scheduledAt: Date | null = null;

  /**
   * Actual publication date for the post
   */
  @ApiPropertyOptional({
    description: 'ISO 8601 timestamp when the post was actually published',
    type: 'string',
    format: 'date-time',
    example: '2025-04-01T10:00:05Z',
  })
  @Column({ name: 'published_at', type: 'timestamp', nullable: true })
  publishedAt: Date | null = null;

  /**
   * Current status of the post
   * draft, scheduled, published, or failed
   */
  @ApiProperty({
    description: 'Current status of the post',
    enum: PostStatus,
    example: PostStatus.SCHEDULED,
  })
  @Column({
    type: 'enum',
    enum: PostStatus,
    default: PostStatus.DRAFT,
  })
  status: PostStatus = PostStatus.DRAFT;

  /**
   * Reason for failure if status is 'failed'
   */
  @ApiPropertyOptional({
    description: 'Reason for publication failure, if applicable',
    example: 'Twitter API error: Invalid credentials.',
  })
  @Column({ name: 'failure_reason', type: 'text', nullable: true })
  failureReason: string | null = null;

  /**
   * Visibility setting (public, private, etc.)
   */
  @ApiPropertyOptional({
    description: 'Visibility setting (currently unused)',
    example: 'public',
  })
  @Column({ type: 'text', nullable: true })
  visibility: string | null = null;

  /**
   * URLs for images to include with the post
   */
  @ApiPropertyOptional({
    description: 'Array of image URLs from cloud storage',
    example: ['https://storage.googleapis.com/.../image1.jpg'],
    type: [String],
  })
  @Column('simple-array', { name: 'cloud_image_urls', default: [] })
  cloudImageUrls: string[] = [];

  /**
   * Optional location latitude
   */
  @ApiPropertyOptional({
    description: 'Latitude for the post location',
    example: 34.0522,
  })
  @Column({ name: 'location_lat', type: 'float', nullable: true })
  locationLat: number | null = null;

  /**
   * Optional location longitude
   */
  @ApiPropertyOptional({
    description: 'Longitude for the post location',
    example: -118.2437,
  })
  @Column({ name: 'location_lng', type: 'float', nullable: true })
  locationLng: number | null = null;

  /**
   * Optional location address or name
   */
  @ApiPropertyOptional({
    description: 'Address or name of the location',
    example: 'Los Angeles, CA',
  })
  @Column({ name: 'location_address', type: 'text', nullable: true })
  locationAddress: string | null = null;

  /**
   * Creation timestamp
   */
  @ApiProperty({
    description: 'Timestamp when the post record was created',
    type: 'string',
    format: 'date-time',
  })
  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date = new Date();

  /**
   * Last update timestamp
   */
  @ApiProperty({
    description: 'Timestamp when the post record was last updated',
    type: 'string',
    format: 'date-time',
  })
  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date = new Date();
}
