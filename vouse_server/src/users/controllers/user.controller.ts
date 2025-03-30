// src/users/controllers/user.controller.ts
import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  UseGuards,
  NotFoundException,
  HttpCode,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiParam,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { UserService } from '../services/user.service';
import { User } from '../entities/user.entity';
import { ConnectTwitterDto, UpdateConnectionStatusDto } from '../dto/user.dto';
import { DecodedIdToken } from 'firebase-admin/auth';
import { FirebaseAuthGuard } from '../../auth/guards/firebase-auth';
import { CurrentUser } from '../../auth/decorators/current-user';

/**
 * Controller for user-related endpoints
 */
@ApiTags('Users')
@ApiBearerAuth()
@Controller('users')
export class UserController {
  constructor(private readonly userService: UserService) {}

  /**
   * Get the current authenticated user's profile data
   */
  @Get('me')
  @UseGuards(FirebaseAuthGuard)
  @ApiOperation({ summary: "Get current user's profile" })
  @ApiResponse({
    status: 200,
    description: 'Returns the user profile.',
    type: User,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized.' })
  async getCurrentUser(@CurrentUser() user: DecodedIdToken): Promise<User> {
    const foundUser = await this.userService.findOne(user.uid);
    if (!foundUser) {
      // Create the user if it doesn't exist yet
      return this.userService.create({ userId: user.uid });
    }
    return foundUser;
  }

  /**
   * Get a specific user's profile data (only accessible by the user themselves)
   */
  @Get(':userId')
  @UseGuards(FirebaseAuthGuard)
  @ApiOperation({ summary: "Get a specific user's profile (self only)" })
  @ApiParam({
    name: 'userId',
    description: 'The Firebase UID of the user',
    example: 'firebaseUid123',
  })
  @ApiResponse({
    status: 200,
    description: 'Returns the user profile.',
    type: User,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized.' })
  @ApiResponse({ status: 404, description: 'User not found or access denied.' })
  async findOne(
    @Param('userId') userId: string,
    @CurrentUser() user: DecodedIdToken,
  ): Promise<User> {
    // Security check: users can only access their own data
    if (user.uid !== userId) {
      throw new NotFoundException('User not found');
    }
    return this.userService.findOneOrFail(userId);
  }

  /**
   * Connect a Twitter account to the current user
   */
  @Post(':userId/connect-twitter')
  @UseGuards(FirebaseAuthGuard)
  @ApiOperation({ summary: 'Connect Twitter account to user' })
  @ApiParam({
    name: 'userId',
    description: 'The Firebase UID of the user',
    example: 'firebaseUid123',
  })
  @ApiResponse({
    status: 201,
    description: 'Twitter account connected successfully.',
    type: User,
  })
  @ApiResponse({
    status: 400,
    description: 'Bad request (e.g., invalid tokens).',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized.' })
  @ApiResponse({ status: 404, description: 'User not found or access denied.' })
  async connectTwitter(
    @Param('userId') userId: string,
    @Body() connectTwitterDto: ConnectTwitterDto,
    @CurrentUser() user: DecodedIdToken,
  ): Promise<User> {
    // Security check: users can only modify their own data
    if (user.uid !== userId) {
      throw new NotFoundException('User not found');
    }
    return this.userService.connectTwitter(userId, connectTwitterDto);
  }

  /**
   * Disconnect Twitter account from the current user
   */
  @Delete(':userId/disconnect-twitter')
  @HttpCode(204) // Set success status code to 204 No Content
  @UseGuards(FirebaseAuthGuard)
  @ApiOperation({ summary: 'Disconnect Twitter account from user' })
  @ApiParam({
    name: 'userId',
    description: 'The Firebase UID of the user',
    example: 'firebaseUid123',
  })
  @ApiResponse({
    status: 204,
    description: 'Twitter account disconnected successfully.',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized.' })
  @ApiResponse({ status: 404, description: 'User not found or access denied.' })
  async disconnectTwitter(
    @Param('userId') userId: string,
    @CurrentUser() user: DecodedIdToken,
  ): Promise<User> {
    // Security check: users can only modify their own data
    if (user.uid !== userId) {
      throw new NotFoundException('User not found');
    }
    return this.userService.disconnectTwitter(userId);
  }

  /**
   * Update the Twitter connection status for the current user
   */
  @Post(':userId/connection-status')
  @UseGuards(FirebaseAuthGuard)
  @ApiOperation({ summary: "Update user's Twitter connection status" })
  @ApiParam({
    name: 'userId',
    description: 'The Firebase UID of the user',
    example: 'firebaseUid123',
  })
  @ApiResponse({
    status: 201,
    description: 'Connection status updated successfully.',
    type: User,
  })
  @ApiResponse({ status: 400, description: 'Bad request.' })
  @ApiResponse({ status: 401, description: 'Unauthorized.' })
  @ApiResponse({ status: 404, description: 'User not found or access denied.' })
  async updateConnectionStatus(
    @Param('userId') userId: string,
    @Body() updateConnectionStatusDto: UpdateConnectionStatusDto,
    @CurrentUser() user: DecodedIdToken,
  ): Promise<User> {
    // Security check: users can only modify their own data
    if (user.uid !== userId) {
      throw new NotFoundException('User not found');
    }
    return this.userService.updateConnectionStatus(
      userId,
      updateConnectionStatusDto,
    );
  }
}
