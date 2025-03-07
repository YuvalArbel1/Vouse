// src/posts/dto/post.dto.ts
import {
  IsString,
  IsOptional,
  IsArray,
  IsNumber,
  IsDateString,
  IsEnum,
  MaxLength,
  ValidateIf,
} from 'class-validator';
import { PostStatus } from '../entities/post.entity';

/**
 * DTO for creating a new post
 */
export class CreatePostDto {
  /**
   * Local post ID generated by the Flutter app
   */
  @IsString()
  postIdLocal: string;

  /**
   * Post content (tweet text)
   */
  @IsString()
  @MaxLength(280) // Twitter character limit
  content: string;

  /**
   * Post title (for app organization, not published)
   */
  @IsString()
  @IsOptional()
  title?: string;

  /**
   * When the post should be published
   */
  @IsDateString()
  @IsOptional()
  scheduledAt?: string;

  /**
   * Twitter visibility setting
   */
  @IsString()
  @IsOptional()
  visibility?: string;

  /**
   * Local image paths in the Flutter app
   */
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  localImagePaths?: string[];

  /**
   * Cloud storage URLs for images
   */
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  cloudImageUrls?: string[];

  /**
   * Latitude for location-based posts
   */
  @IsNumber()
  @IsOptional()
  locationLat?: number;

  /**
   * Longitude for location-based posts
   */
  @IsNumber()
  @IsOptional()
  @ValidateIf((o) => o.locationLat !== undefined)
  locationLng?: number;

  /**
   * Human-readable location address
   */
  @IsString()
  @IsOptional()
  locationAddress?: string;
}

/**
 * DTO for updating an existing post
 */
export class UpdatePostDto {
  /**
   * Post content (tweet text)
   */
  @IsString()
  @MaxLength(280)
  @IsOptional()
  content?: string;

  /**
   * Post title
   */
  @IsString()
  @IsOptional()
  title?: string;

  /**
   * When the post should be published
   */
  @IsDateString()
  @IsOptional()
  scheduledAt?: string;

  /**
   * Twitter post visibility
   */
  @IsString()
  @IsOptional()
  visibility?: string;

  /**
   * Local image paths
   */
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  localImagePaths?: string[];

  /**
   * Cloud storage URLs for images
   */
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  cloudImageUrls?: string[];

  /**
   * Current post status
   */
  @IsEnum(PostStatus)
  @IsOptional()
  status?: PostStatus;

  /**
   * Latitude
   */
  @IsNumber()
  @IsOptional()
  locationLat?: number;

  /**
   * Longitude
   */
  @IsNumber()
  @IsOptional()
  @ValidateIf((o) => o.locationLat !== undefined)
  locationLng?: number;

  /**
   * Human-readable location address
   */
  @IsString()
  @IsOptional()
  locationAddress?: string;
}
