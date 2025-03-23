// src/posts/entities/engagement.entity.ts
import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Post } from './post.entity';

/**
 * Post engagement entity for storing engagement metrics for posts
 */
@Entity('post_engagements')
export class Engagement {
  /**
   * X/Twitter post ID that this engagement data is for
   */
  @Column({ name: 'post_id_x', type: 'text', primary: true })
  postIdX: string;

  /**
   * Client-generated unique ID for the post
   * Used for tracking the post across client and server
   */
  @Column({ name: 'post_id_local', type: 'text' })
  postIdLocal: string;

  /**
   * Relation to Post entity
   */
  @ManyToOne(() => Post, { eager: true })
  @JoinColumn({ name: 'post_id_local', referencedColumnName: 'postIdLocal' })
  post: Post;

  /**
   * User ID who owns this post
   */
  @Column({ name: 'user_id', type: 'text' })
  userId: string;

  /**
   * Number of likes the post has received
   */
  @Column({ type: 'integer', default: 0 })
  likes: number = 0;

  /**
   * Number of retweets the post has received
   */
  @Column({ type: 'integer', default: 0 })
  retweets: number = 0;

  /**
   * Number of quotes the post has received
   */
  @Column({ type: 'integer', default: 0 })
  quotes: number = 0;

  /**
   * Number of replies the post has received
   */
  @Column({ type: 'integer', default: 0 })
  replies: number = 0;

  /**
   * Number of impressions the post has received
   */
  @Column({ type: 'integer', default: 0 })
  impressions: number = 0;

  /**
   * Hourly metrics data
   * Stores time series data for engagement metrics
   */
  @Column('jsonb', { name: 'hourly_metrics', default: [] })
  hourlyMetrics: {
    timestamp: string;
    metrics: {
      likes: number;
      retweets: number;
      quotes: number;
      replies: number;
      impressions: number;
    };
  }[] = [];

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
