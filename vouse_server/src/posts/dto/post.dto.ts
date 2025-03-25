// src/posts/dto/post.dto.ts
import {
  IsNotEmpty,
  IsString,
  IsOptional,
  IsNumber,
  IsDateString,
  IsArray,
  IsBoolean,
  IsEnum,
} from 'class-validator';
import { PostStatus } from '../entities/post.entity';
import { Type } from 'class-transformer';

/**
 * DTO for creating a post
 */
export class CreatePostDto {
  /**
   * Client-generated unique ID for tracking the post
   */
  @IsNotEmpty()
  @IsString()
  postIdLocal: string = '';

  /**
   * Post content/message
   */
  @IsNotEmpty()
  @IsString()
  content: string = '';

  /**
   * Optional post title
   */
  @IsOptional()
  @IsString()
  title?: string;

  /**
   * Optional scheduled publication date
   */
  @IsOptional()
  @IsDateString()
  scheduledAt?: string;

  /**
   * Optional visibility setting (public, private, etc.)
   */
  @IsOptional()
  @IsString()
  visibility?: string;

  /**
   * Optional image URLs
   */
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  cloudImageUrls?: string[];

  /**
   * Optional location
   */
  @IsOptional()
  @IsNumber()
  locationLat?: number;

  /**
   * Optional location
   */
  @IsOptional()
  @IsNumber()
  locationLng?: number;

  /**
   * Optional location name
   */
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
  @IsOptional()
  @IsString()
  content?: string;

  /**
   * Optional title update
   */
  @IsOptional()
  @IsString()
  title?: string;

  /**
   * Optional updated scheduled date
   */
  @IsOptional()
  @IsDateString()
  scheduledAt?: string;

  /**
   * Optional status update
   */
  @IsOptional()
  @IsEnum(PostStatus)
  status?: PostStatus;

  /**
   * Optional visibility setting update
   */
  @IsOptional()
  @IsString()
  visibility?: string;

  /**
   * Optional image URLs update
   */
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  cloudImageUrls?: string[];

  /**
   * Optional location latitude
   */
  @IsOptional()
  @IsNumber()
  locationLat?: number;

  /**
   * Optional location longitude
   */
  @IsOptional()
  @IsNumber()
  locationLng?: number;

  /**
   * Optional location name
   */
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
  @IsOptional()
  @IsEnum(PostStatus, { each: true })
  status?: PostStatus[];

  /**
   * Start of date range
   */
  @IsOptional()
  @IsDateString()
  startDate?: string;

  /**
   * End of date range
   */
  @IsOptional()
  @IsDateString()
  endDate?: string;

  /**
   * Search text
   */
  @IsOptional()
  @IsString()
  searchTerm?: string;

  /**
   * Page number for pagination
   */
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  page?: number = 1;

  /**
   * Items per page for pagination
   */
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  limit?: number = 10;
}
