// src/posts/entities/post.entity.ts
import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

/**
 * Post status enum
 */
export enum PostStatus {
  DRAFT = 'draft',
  SCHEDULED = 'scheduled',
  PUBLISHING = 'publishing',
  PUBLISHED = 'published',
  FAILED = 'failed',
}

/**
 * Post entity for storing scheduled and published posts
 */
@Entity('posts')
export class Post {
  /**
   * Auto-generated UUID for the post
   */
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /**
   * Local post ID from the Flutter app
   * Adding a unique constraint to fix the foreign key issue
   */
  @Column({ nullable: false, type: 'varchar', unique: true })
  @Index('IDX_POST_ID_LOCAL', { unique: true })
  postIdLocal: string;

  /**
   * Twitter post ID, null until published
   */
  @Column({ nullable: true, type: 'varchar' })
  postIdX: string | null;

  /**
   * Foreign key to the user who created this post
   */
  @Column({ type: 'varchar' })
  userId: string;

  /**
   * Relationship to the User entity
   */
  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  /**
   * The post content (tweet text)
   */
  @Column({ type: 'text' })
  content: string;

  /**
   * A title for organizing posts in the app (not published to Twitter)
   */
  @Column({ nullable: true, type: 'varchar' })
  title: string | null;

  /**
   * When the post should be published
   */
  @Column({ type: 'timestamp', nullable: true })
  scheduledAt: Date | null;

  /**
   * When the post was actually published
   */
  @Column({ type: 'timestamp', nullable: true })
  publishedAt: Date | null;

  /**
   * Current status of the post
   */
  @Column({
    type: 'enum',
    enum: PostStatus,
    default: PostStatus.DRAFT,
  })
  status: PostStatus;

  /**
   * If the post failed to publish, store the reason
   */
  @Column({ type: 'text', nullable: true })
  failureReason: string | null;

  /**
   * Visibility setting (for Twitter's reply control)
   */
  @Column({ nullable: true, type: 'varchar' })
  visibility: string | null;

  /**
   * URLs to images stored in cloud storage
   */
  @Column({ type: 'json', default: '[]' })
  cloudImageUrls: string[];

  /**
   * Latitude for location-based posts
   */
  @Column({ type: 'float', nullable: true })
  locationLat: number | null;

  /**
   * Longitude for location-based posts
   */
  @Column({ type: 'float', nullable: true })
  locationLng: number | null;

  /**
   * Human-readable location address
   */
  @Column({ nullable: true, type: 'varchar' })
  locationAddress: string | null;

  /**
   * When the post record was created
   */
  @CreateDateColumn()
  createdAt: Date;
}
