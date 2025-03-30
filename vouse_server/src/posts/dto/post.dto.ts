// src/posts/dto/post.dto.ts
import {
  IsNotEmpty,
  IsString,
  IsOptional,
  IsNumber,
  IsDateString,
  IsArray,
  IsEnum,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PostStatus } from '../entities/post.entity';
import { Type } from 'class-transformer';

/**
 * DTO for creating a post
 */
export class CreatePostDto {
  /**
   * Client-generated unique ID for tracking the post
   */
  @ApiProperty({
    description: 'Client-generated unique ID for the post',
    example: 'local-uuid-123',
  })
  @IsNotEmpty()
  @IsString()
  postIdLocal: string = '';

  /**
   * Post content/message
   */
  @ApiProperty({
    description: 'The main text content of the post',
    example: 'Check out this cool update!',
  })
  @IsNotEmpty()
  @IsString()
  content: string = '';

  /**
   * Optional post title
   */
  @ApiPropertyOptional({
    description: 'An optional title for the post',
    example: 'Vouse App Update',
  })
  @IsOptional()
  @IsString()
  title?: string;

  /**
   * Optional scheduled publication date
   */
  @ApiPropertyOptional({
    description: 'ISO 8601 timestamp for scheduled publication',
    example: '2025-04-01T10:00:00Z',
  })
  @IsOptional()
  @IsDateString()
  scheduledAt?: string;

  /**
   * Optional visibility setting (public, private, etc.)
   */
  @ApiPropertyOptional({
    description: 'Visibility setting (e.g., public)',
    example: 'public',
  })
  @IsOptional()
  @IsString()
  visibility?: string;

  /**
   * Optional image URLs
   */
  @ApiPropertyOptional({
    description: 'Array of image URLs stored in cloud storage',
    example: ['https://storage.googleapis.com/.../image1.jpg'],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  cloudImageUrls?: string[];

  /**
   * Optional location
   */
  @ApiPropertyOptional({
    description: 'Latitude for the post location',
    example: 34.0522,
  })
  @IsOptional()
  @IsNumber()
  locationLat?: number;

  /**
   * Optional location
   */
  @ApiPropertyOptional({
    description: 'Longitude for the post location',
    example: -118.2437,
  })
  @IsOptional()
  @IsNumber()
  locationLng?: number;

  /**
   * Optional location name
   */
  @ApiPropertyOptional({
    description: 'Address or name of the location',
    example: 'Los Angeles, CA',
  })
  @IsOptional()
  @IsString()
  locationAddress?: string;
}

/**
 * DTO for updating a post
 */
export class UpdatePostDto {
  /**
   * Optional updated content
   */
  @ApiPropertyOptional({
    description: 'Updated text content for the post',
    example: 'Revised post content.',
  })
  @IsOptional()
  @IsString()
  content?: string;

  /**
   * Optional title update
   */
  @ApiPropertyOptional({
    description: 'Updated title for the post',
    example: 'Vouse App Update v1.1',
  })
  @IsOptional()
  @IsString()
  title?: string;

  /**
   * Optional updated scheduled date
   */
  @ApiPropertyOptional({
    description: 'Updated ISO 8601 timestamp for scheduling',
    example: '2025-04-02T12:00:00Z',
  })
  @IsOptional()
  @IsDateString()
  scheduledAt?: string;

  /**
   * Optional status update
   */
  @ApiPropertyOptional({
    description: 'Update the post status',
    enum: PostStatus,
    example: PostStatus.SCHEDULED,
  })
  @IsOptional()
  @IsEnum(PostStatus)
  status?: PostStatus;

  /**
   * Optional visibility setting update
   */
  @ApiPropertyOptional({
    description: 'Updated visibility setting',
    example: 'public',
  })
  @IsOptional()
  @IsString()
  visibility?: string;

  /**
   * Optional image URLs update
   */
  @ApiPropertyOptional({
    description: 'Updated array of image URLs',
    example: ['https://storage.googleapis.com/.../image_new.jpg'],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  cloudImageUrls?: string[];

  /**
   * Optional location latitude
   */
  @ApiPropertyOptional({ description: 'Updated latitude', example: 34.0523 })
  @IsOptional()
  @IsNumber()
  locationLat?: number;

  /**
   * Optional location longitude
   */
  @ApiPropertyOptional({ description: 'Updated longitude', example: -118.2438 })
  @IsOptional()
  @IsNumber()
  locationLng?: number;

  /**
   * Optional location name
   */
  @ApiPropertyOptional({
    description: 'Updated location name',
    example: 'Downtown Los Angeles',
  })
  @IsOptional()
  @IsString()
  locationAddress?: string;
}

/**
 * DTO for filtering posts
 */
export class PostFilterDto {
  /**
   * Filter by post status
   */
  @ApiPropertyOptional({
    description: 'Filter by one or more post statuses',
    enum: PostStatus,
    isArray: true,
    example: [PostStatus.PUBLISHED, PostStatus.SCHEDULED],
  })
  @IsOptional()
  @IsEnum(PostStatus, { each: true })
  status?: PostStatus[];

  /**
   * Start of date range
   */
  @ApiPropertyOptional({
    description: 'Filter posts created after this ISO 8601 date',
    example: '2025-03-01T00:00:00Z',
  })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  /**
   * End of date range
   */
  @ApiPropertyOptional({
    description: 'Filter posts created before this ISO 8601 date',
    example: '2025-03-31T23:59:59Z',
  })
  @IsOptional()
  @IsDateString()
  endDate?: string;

  /**
   * Search text
   */
  @ApiPropertyOptional({
    description: 'Search term to filter post content or title',
    example: 'update',
  })
  @IsOptional()
  @IsString()
  searchTerm?: string;

  /**
   * Page number for pagination
   */
  @ApiPropertyOptional({
    description: 'Page number for pagination',
    default: 1,
    type: Number,
  })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  page?: number = 1;

  /**
   * Items per page for pagination
   */
  @ApiPropertyOptional({
    description: 'Number of items per page',
    default: 10,
    type: Number,
  })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  limit?: number = 10;
}
