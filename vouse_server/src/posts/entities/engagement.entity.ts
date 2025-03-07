// src/posts/entities/engagement.entity.ts
import {
  Entity,
  Column,
  PrimaryColumn,
  CreateDateColumn,
  UpdateDateColumn,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { Post } from './post.entity';

/**
 * Entity for storing engagement metrics for published posts
 */
@Entity('post_engagements')
export class PostEngagement {
  /**
   * Twitter post ID as primary key
   */
  @PrimaryColumn()
  postIdX: string;

  /**
   * Reference to the local post ID
   */
  @Column()
  postIdLocal: string;

  /**
   * One-to-one relationship with the Post entity
   */
  @OneToOne(() => Post)
  @JoinColumn({ name: 'postIdLocal', referencedColumnName: 'postIdLocal' })
  post: Post;

  /**
   * User who owns this post
   */
  @Column()
  userId: string;

  /**
   * Number of likes the post has received
   */
  @Column({ default: 0 })
  likes: number;

  /**
   * Number of retweets the post has received
   */
  @Column({ default: 0 })
  retweets: number;

  /**
   * Number of quotes the post has received
   */
  @Column({ default: 0 })
  quotes: number;

  /**
   * Number of replies the post has received
   */
  @Column({ default: 0 })
  replies: number;

  /**
   * Number of impressions (views) the post has received
   */
  @Column({ default: 0 })
  impressions: number;

  /**
   * Detailed hourly metrics stored as JSON
   * Format: { timestamp: ISO string, metrics: { likes, retweets, etc. } }
   */
  @Column({ type: 'json', default: '[]' })
  hourlyMetrics: any[];

  /**
   * When this engagement record was created
   */
  @CreateDateColumn()
  createdAt: Date;

  /**
   * When metrics were last updated
   */
  @UpdateDateColumn()
  updatedAt: Date;
}
