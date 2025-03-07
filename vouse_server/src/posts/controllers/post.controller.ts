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
  Query,
} from '@nestjs/common';
import { PostService } from '../services/post.service';
import { CreatePostDto, UpdatePostDto } from '../dto/post.dto';
import { FirebaseAuthGuard } from '../../auth/guards/firebase-auth';
import { CurrentUser } from '../../auth/decorators/current-user';
import { DecodedIdToken } from 'firebase-admin/auth';
import { XAuthService } from '../../x/services/x-auth.service';

@Controller('posts')
export class PostController {
  constructor(
    private readonly postService: PostService,
    private readonly xAuthService: XAuthService,
  ) {}

  /**
   * Create a new post
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
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to create post',
        },
        error.status || HttpStatus.BAD_REQUEST,
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
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to get post',
        },
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
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
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to get post',
        },
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * Update a post
   */
  @Patch(':id')
  @UseGuards(FirebaseAuthGuard)
  async update(
    @Param('id') id: string,
    @Body() updatePostDto: UpdatePostDto,
    @CurrentUser() user: DecodedIdToken,
  ) {
    try {
      const post = await this.postService.update(id, user.uid, updatePostDto);
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
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to update post',
        },
        error.status || HttpStatus.BAD_REQUEST,
      );
    }
  }

  /**
   * Delete a post
   */
  @Delete(':id')
  @UseGuards(FirebaseAuthGuard)
  async remove(@Param('id') id: string, @CurrentUser() user: DecodedIdToken) {
    try {
      await this.postService.remove(id, user.uid);
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
      throw new HttpException(
        {
          success: false,
          message: error.message || 'Failed to delete post',
        },
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
