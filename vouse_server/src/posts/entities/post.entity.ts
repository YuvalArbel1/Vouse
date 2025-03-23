// src/posts/entities/post.entity.ts
import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  OneToMany,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

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
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /**
   * Client-generated unique ID for the post
   * Used for tracking the post across client and server
   */
  @Column({ name: 'post_id_local', type: 'text', unique: true })
  postIdLocal: string;

  /**
   * X/Twitter post ID for published posts
   */
  @Column({ name: 'post_id_x', type: 'text', nullable: true })
  postIdX: string | null = null;

  /**
   * User ID who created the post
   */
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
  @Column({ type: 'text' })
  content: string;

  /**
   * Optional post title
   */
  @Column({ type: 'text', nullable: true })
  title: string | null = null;

  /**
   * Scheduled publication date for the post
   */
  @Column({ name: 'scheduled_at', type: 'timestamp', nullable: true })
  scheduledAt: Date | null = null;

  /**
   * Actual publication date for the post
   */
  @Column({ name: 'published_at', type: 'timestamp', nullable: true })
  publishedAt: Date | null = null;

  /**
   * Current status of the post
   * draft, scheduled, published, or failed
   */
  @Column({
    type: 'enum',
    enum: PostStatus,
    default: PostStatus.DRAFT,
  })
  status: PostStatus = PostStatus.DRAFT;

  /**
   * Reason for failure if status is 'failed'
   */
  @Column({ name: 'failure_reason', type: 'text', nullable: true })
  failureReason: string | null = null;

  /**
   * Visibility setting (public, private, etc.)
   */
  @Column({ type: 'text', nullable: true })
  visibility: string | null = null;

  /**
   * URLs for images to include with the post
   */
  @Column('simple-array', { name: 'cloud_image_urls', default: [] })
  cloudImageUrls: string[] = [];

  /**
   * Optional location latitude
   */
  @Column({ name: 'location_lat', type: 'float', nullable: true })
  locationLat: number | null = null;

  /**
   * Optional location longitude
   */
  @Column({ name: 'location_lng', type: 'float', nullable: true })
  locationLng: number | null = null;

  /**
   * Optional location address or name
   */
  @Column({ name: 'location_address', type: 'text', nullable: true })
  locationAddress: string | null = null;

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
