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
  ParseUUIDPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiParam,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { PostService } from '../services/post.service';
import { CreatePostDto, UpdatePostDto } from '../dto/post.dto';
import { FirebaseAuthGuard } from '../../auth/guards/firebase-auth';
import { CurrentUser } from '../../auth/decorators/current-user';
import { DecodedIdToken } from 'firebase-admin/auth';
import { XAuthService } from '../../x/services/x-auth.service';
import { PostStatus, Post as PostEntity } from '../entities/post.entity';

@ApiTags('Posts')
@ApiBearerAuth()
@Controller('posts')
export class PostController {
  constructor(
    private readonly postService: PostService,
    private readonly xAuthService: XAuthService,
  ) {}

  /**
   * Force immediate publishing of a scheduled post
   * This is useful when the queue system isn't working properly
   */
  @Post('immediate/:postId')
  @UseGuards(FirebaseAuthGuard)
  @ApiOperation({ summary: 'Force immediate publishing of a post' })
  @ApiParam({
    name: 'postId',
    description: 'The UUID of the post to publish immediately',
    type: String,
  })
  @ApiResponse({
    status: 201,
    description: 'Post publishing initiated.',
    type: PostEntity,
  })
  @ApiResponse({
    status: 400,
    description:
      'Bad Request (e.g., Twitter not connected, post already published).',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized.' })
  @ApiResponse({ status: 404, description: 'Post not found.' })
  async publishImmediately(
    @Param('postId', ParseUUIDPipe) postId: string,
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

      // Attempt to publish immediately using the actual post UUID
      const post = await this.postService.publishImmediately(postId, user.uid);

      return {
        success: true,
        data: post,
        message: 'Post publishing initiated. Check status shortly.',
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
          message: errorMessage || 'Failed to publish post',
        },
        status,
      );
    }
  }

  /**
   * Create a new post and schedule it for publishing
   */
  @Post()
  @UseGuards(FirebaseAuthGuard)
  @ApiOperation({ summary: 'Create and schedule a new post' })
  @ApiResponse({
    status: 201,
    description: 'Post created and scheduled successfully.',
    type: PostEntity,
  })
  @ApiResponse({
    status: 400,
    description: 'Bad Request (e.g., Twitter not connected).',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized.' })
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
  @ApiOperation({ summary: 'Get all posts for the current user' })
  @ApiResponse({
    status: 200,
    description: 'Returns an array of user posts.',
    type: [PostEntity],
  })
  @ApiResponse({ status: 401, description: 'Unauthorized.' })
  async findAll(@CurrentUser() user: DecodedIdToken) {
    const posts = await this.postService.findAllByUser(user.uid);
    return {
      success: true,
      data: posts,
    };
  }

  /**
   * Get a specific post by its UUID
   */
  @Get(':id')
  @UseGuards(FirebaseAuthGuard)
  @ApiOperation({ summary: 'Get a specific post by its UUID' })
  @ApiParam({ name: 'id', description: 'The UUID of the post', type: String })
  @ApiResponse({
    status: 200,
    description: 'Returns the post details.',
    type: PostEntity,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized.' })
  @ApiResponse({ status: 404, description: 'Post not found.' })
  async findOne(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: DecodedIdToken,
  ) {
    try {
      // findOne service method already checks user ownership
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
   * Get a post by its client-generated local ID
   */
  @Get('local/:postIdLocal')
  @UseGuards(FirebaseAuthGuard)
  @ApiOperation({ summary: 'Get a post by its client-generated local ID' })
  @ApiParam({
    name: 'postIdLocal',
    description: 'The local ID generated by the client app',
    type: String,
  })
  @ApiResponse({
    status: 200,
    description: 'Returns the post details.',
    type: PostEntity,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized.' })
  @ApiResponse({ status: 404, description: 'Post not found.' })
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
   * Update a post (identified by local ID) - Only allows updating posts that are not yet published or scheduled too soon
   */
  @Patch(':postIdLocal')
  @UseGuards(FirebaseAuthGuard)
  @ApiOperation({ summary: 'Update a draft or scheduled post (by local ID)' })
  @ApiParam({
    name: 'postIdLocal',
    description: 'The local ID of the post to update',
    type: String,
  })
  @ApiResponse({
    status: 200,
    description: 'Post updated successfully.',
    type: PostEntity,
  })
  @ApiResponse({ status: 400, description: 'Bad Request.' })
  @ApiResponse({ status: 401, description: 'Unauthorized.' })
  @ApiResponse({
    status: 403,
    description:
      'Forbidden (e.g., post already published or scheduled too soon).',
  })
  @ApiResponse({ status: 404, description: 'Post not found.' })
  async update(
    @Param('postIdLocal') postIdLocal: string,
    @Body() updatePostDto: UpdatePostDto,
    @CurrentUser() user: DecodedIdToken,
  ) {
    try {
      // First check if the post exists using local ID
      const post = await this.postService.findOneByLocalId(
        postIdLocal,
        user.uid,
      );

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

      // Use the actual post UUID (post.id) for the update service call
      const updatedPost = await this.postService.update(
        post.id,
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
   * Delete a post (identified by local ID) - Only allows deleting posts that are not yet published
   */
  @Delete(':postIdLocal') // Changed param name to match usage
  @UseGuards(FirebaseAuthGuard)
  @ApiOperation({ summary: 'Delete a draft or scheduled post (by local ID)' })
  @ApiParam({
    name: 'postIdLocal',
    description: 'The local ID of the post to delete',
    type: String,
  })
  @ApiResponse({ status: 200, description: 'Post deleted successfully.' })
  @ApiResponse({ status: 401, description: 'Unauthorized.' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden (e.g., post already published).',
  })
  @ApiResponse({ status: 404, description: 'Post not found.' })
  async remove(
    @Param('postIdLocal') postIdLocal: string,
    @CurrentUser() user: DecodedIdToken,
  ) {
    try {
      // First check if the post exists using local ID
      const post = await this.postService.findOneByLocalId(
        postIdLocal,
        user.uid,
      );

      // Prevent deleting published posts
      if (post.status === PostStatus.PUBLISHED) {
        throw new ForbiddenException('Cannot delete already published posts');
      }

      // Use the actual post UUID (post.id) for the remove service call
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
