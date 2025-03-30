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
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
// Define a helper class for the hourly metrics structure for Swagger
class HourlyMetricDetail {
  @ApiProperty({ example: 10 })
  likes: number;
  @ApiProperty({ example: 2 })
  retweets: number;
  @ApiProperty({ example: 1 })
  quotes: number;
  @ApiProperty({ example: 3 })
  replies: number;
  @ApiProperty({ example: 150 })
  impressions: number;
}
class HourlyMetric {
  @ApiProperty({
    type: String,
    format: 'date-time',
    example: '2025-04-01T11:00:00Z',
  })
  timestamp: string;
  @ApiProperty({ type: HourlyMetricDetail })
  metrics: HourlyMetricDetail;
}

/**
 * Post engagement entity for storing engagement metrics for posts
 */
@Entity('post_engagements')
export class Engagement {
  /**
   * X/Twitter post ID that this engagement data is for
   */
  @ApiProperty({
    description: 'X/Twitter post ID (Primary Key)',
    example: '1773600000000000000',
  })
  @Column({ name: 'post_id_x', type: 'text', primary: true })
  postIdX: string;

  /**
   * Client-generated unique ID for the post
   * Used for tracking the post across client and server
   */
  @ApiProperty({
    description: 'Client-generated unique ID for the post',
    example: 'local-uuid-123',
  })
  @Column({ name: 'post_id_local', type: 'text' })
  postIdLocal: string;

  /**
   * Relation to Post entity
   */
  // @ApiProperty({ type: () => Post }) // Avoid exposing full Post object here
  @ManyToOne(() => Post, { eager: true })
  @JoinColumn({ name: 'post_id_local', referencedColumnName: 'postIdLocal' })
  post: Post; // Consider removing eager: true or using a DTO

  /**
   * User ID who owns this post
   */
  @ApiProperty({
    description: 'Firebase User ID of the post owner',
    example: 'firebaseUid123',
  })
  @Column({ name: 'user_id', type: 'text' })
  userId: string;

  /**
   * Number of likes the post has received
   */
  @ApiProperty({ description: 'Total number of likes', example: 125 })
  @Column({ type: 'integer', default: 0 })
  likes: number = 0;

  /**
   * Number of retweets the post has received
   */
  @ApiProperty({ description: 'Total number of retweets', example: 25 })
  @Column({ type: 'integer', default: 0 })
  retweets: number = 0;

  /**
   * Number of quotes the post has received
   */
  @ApiProperty({ description: 'Total number of quotes', example: 5 })
  @Column({ type: 'integer', default: 0 })
  quotes: number = 0;

  /**
   * Number of replies the post has received
   */
  @ApiProperty({ description: 'Total number of replies', example: 15 })
  @Column({ type: 'integer', default: 0 })
  replies: number = 0;

  /**
   * Number of impressions the post has received
   */
  @ApiProperty({ description: 'Total number of impressions', example: 5000 })
  @Column({ type: 'integer', default: 0 })
  impressions: number = 0;

  /**
   * Hourly metrics data
   * Stores time series data for engagement metrics
   */
  @ApiProperty({
    description: 'Time series data for engagement metrics',
    type: [HourlyMetric],
  })
  @Column('jsonb', { name: 'hourly_metrics', default: [] })
  hourlyMetrics: HourlyMetric[] = []; // Use the helper class type

  /**
   * Creation timestamp
   */
  @ApiProperty({
    description: 'Timestamp when the engagement record was created',
    type: 'string',
    format: 'date-time',
  })
  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date = new Date();

  /**
   * Last update timestamp
   */
  @ApiProperty({
    description: 'Timestamp when the engagement record was last updated',
    type: 'string',
    format: 'date-time',
  })
  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date = new Date();
}
