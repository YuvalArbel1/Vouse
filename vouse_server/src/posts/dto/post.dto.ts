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
  Min,
  Max,
} from 'class-validator';
import { PostStatus } from '../entities/post.entity';
import { Transform } from 'class-transformer';

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
   * Local post ID generated by the Flutter app
   */
  @IsString()
  @IsOptional()
  postIdLocal?: string;

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
  @IsOptional()
  @IsNumber({ allowNaN: false, allowInfinity: false })
  @Transform(({ value }) =>
    typeof value === 'string' ? parseFloat(value) : value,
  )
  @Min(-90, { message: 'Latitude must be between -90 and 90 degrees' })
  @Max(90, { message: 'Latitude must be between -90 and 90 degrees' })
  locationLat?: number;

  /**
   * Longitude
   */
  @IsOptional()
  @IsNumber({ allowNaN: false, allowInfinity: false })
  @Transform(({ value }) =>
    typeof value === 'string' ? parseFloat(value) : value,
  )
  @Min(-180, { message: 'Longitude must be between -180 and 180 degrees' })
  @Max(180, { message: 'Longitude must be between -180 and 180 degrees' })
  @ValidateIf((o) => o.locationLat !== undefined)
  locationLng?: number;

  /**
   * Human-readable location address
   */
  @IsString()
  @IsOptional()
  locationAddress?: string;
}
