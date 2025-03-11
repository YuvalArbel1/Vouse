// src/posts/controllers/post.controller.ts
import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  NotFoundException,
  HttpException,
  HttpStatus,
  ForbiddenException,
} from '@nestjs/common';
import { PostService } from '../services/post.service';
import { CreatePostDto, UpdatePostDto } from '../dto/post.dto';
import { FirebaseAuthGuard } from '../../auth/guards/firebase-auth';
import { CurrentUser } from '../../auth/decorators/current-user';
import { DecodedIdToken } from 'firebase-admin/auth';
import { XAuthService } from '../../x/services/x-auth.service';
import { PostStatus } from '../entities/post.entity';

@Controller('posts')
export class PostController {
  constructor(
    private readonly postService: PostService,
    private readonly xAuthService: XAuthService,
  ) {}

  /**
   * Create a new post
   *
   * Note: This endpoint only handles scheduled posts (including immediate posts).
   * Draft posts are managed locally in the Flutter app and not sent to the server.
   */
  @Post()
  @UseGuards(FirebaseAuthGuard)
  async create(
    @Body() createPostDto: CreatePostDto,
    @CurrentUser() user: DecodedIdToken,
  ) {
    try {
      // Check if user has connected their Twitter account
      const isConnected = await this.xAuthService.isAccountConnected(user.uid);
      if (!isConnected) {
        throw new HttpException(
          'Twitter account not connected',
          HttpStatus.BAD_REQUEST,
        );
      }

      const post = await this.postService.create(user.uid, createPostDto);
      return {
        success: true,
        data: post,
      };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      const status =
        error instanceof HttpException
          ? error.getStatus()
          : HttpStatus.BAD_REQUEST;

      throw new HttpException(
        {
          success: false,
          message: errorMessage || 'Failed to create post',
        },
        status,
      );
    }
  }

  /**
   * Get all posts for the current user
   */
  @Get()
  @UseGuards(FirebaseAuthGuard)
  async findAll(@CurrentUser() user: DecodedIdToken) {
    const posts = await this.postService.findAllByUser(user.uid);
    return {
      success: true,
      data: posts,
    };
  }

  /**
   * Get a post by ID
   */
  @Get(':id')
  @UseGuards(FirebaseAuthGuard)
  async findOne(@Param('id') id: string, @CurrentUser() user: DecodedIdToken) {
    try {
      const post = await this.postService.findOne(id, user.uid);
      return {
        success: true,
        data: post,
      };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw new HttpException(
          {
            success: false,
            message: error.message,
          },
          HttpStatus.NOT_FOUND,
        );
      }
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      throw new HttpException(
        {
          success: false,
          message: errorMessage || 'Failed to get post',
        },
        error instanceof HttpException
          ? error.getStatus()
          : HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * Get a post by its local ID
   */
  @Get('local/:postIdLocal')
  @UseGuards(FirebaseAuthGuard)
  async findOneByLocalId(
    @Param('postIdLocal') postIdLocal: string,
    @CurrentUser() user: DecodedIdToken,
  ) {
    try {
      const post = await this.postService.findOneByLocalId(
        postIdLocal,
        user.uid,
      );
      return {
        success: true,
        data: post,
      };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw new HttpException(
          {
            success: false,
            message: error.message,
          },
          HttpStatus.NOT_FOUND,
        );
      }
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      throw new HttpException(
        {
          success: false,
          message: errorMessage || 'Failed to get post',
        },
        error instanceof HttpException
          ? error.getStatus()
          : HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * Update a post - Only allows updating posts that are not yet published
   */
  @Patch(':id')
  @UseGuards(FirebaseAuthGuard)
  async update(
    @Param('id') id: string,
    @Body() updatePostDto: UpdatePostDto,
    @CurrentUser() user: DecodedIdToken,
  ) {
    try {
      // First check if the post exists
      const post = await this.postService.findOne(id, user.uid);

      // Prevent editing published posts
      if (post.status === PostStatus.PUBLISHED) {
        throw new ForbiddenException('Cannot update already published posts');
      }
      // Add check for scheduled posts close to publish time
      if (post.status === PostStatus.SCHEDULED && post.scheduledAt) {
        const now = new Date();
        const scheduledAt = new Date(post.scheduledAt);
        const diffMinutes =
          (scheduledAt.getTime() - now.getTime()) / (1000 * 60);

        if (diffMinutes < 2) {
          throw new ForbiddenException(
            'Cannot update posts scheduled to be published in less than 2 minutes',
          );
        }
      }

      const updatedPost = await this.postService.update(
        id,
        user.uid,
        updatePostDto,
      );
      return {
        success: true,
        data: updatedPost,
      };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw new HttpException(
          {
            success: false,
            message: error.message,
          },
          HttpStatus.NOT_FOUND,
        );
      }
      if (error instanceof ForbiddenException) {
        throw new HttpException(
          {
            success: false,
            message: error.message,
          },
          HttpStatus.FORBIDDEN,
        );
      }
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      throw new HttpException(
        {
          success: false,
          message: errorMessage || 'Failed to update post',
        },
        error instanceof HttpException
          ? error.getStatus()
          : HttpStatus.BAD_REQUEST,
      );
    }
  }

  /**
   * Delete a post - Only allows deleting posts that are not yet published
   */
  @Delete(':id')
  @UseGuards(FirebaseAuthGuard)
  async remove(@Param('id') postIdLocal: string, @CurrentUser() user: DecodedIdToken) {
    try {
      // First check if the post exists
      const post = await this.postService.findOneByLocalId(postIdLocal, user.uid);

      // Prevent deleting published posts
      if (post.status === PostStatus.PUBLISHED) {
        throw new ForbiddenException('Cannot delete already published posts');
      }

      await this.postService.remove(post.id, user.uid);
      return {
        success: true,
        message: 'Post deleted successfully',
      };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw new HttpException(
          {
            success: false,
            message: error.message,
          },
          HttpStatus.NOT_FOUND,
        );
      }
      if (error instanceof ForbiddenException) {
        throw new HttpException(
          {
            success: false,
            message: error.message,
          },
          HttpStatus.FORBIDDEN,
        );
      }
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      throw new HttpException(
        {
          success: false,
          message: errorMessage || 'Failed to delete post',
        },
        error instanceof HttpException
          ? error.getStatus()
          : HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
