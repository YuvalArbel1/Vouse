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
} from '@nestjs/common';
import { UserService } from '../services/user.service';
import { User } from '../entities/user.entity';
import { ConnectTwitterDto, UpdateConnectionStatusDto } from '../dto/user.dto';
import { DecodedIdToken } from 'firebase-admin/auth';
import { FirebaseAuthGuard } from '../../auth/guards/firebase-auth';
import { CurrentUser } from '../../auth/decorators/current-user';

/**
 * Controller for user-related endpoints
 */
@Controller('users')
export class UserController {
  constructor(private readonly userService: UserService) {}

  /**
   * Get the current authenticated user
   */
  @Get('me')
  @UseGuards(FirebaseAuthGuard)
  async getCurrentUser(@CurrentUser() user: DecodedIdToken): Promise<User> {
    const foundUser = await this.userService.findOne(user.uid);
    if (!foundUser) {
      // Create the user if it doesn't exist yet
      return this.userService.create({ userId: user.uid });
    }
    return foundUser;
  }

  /**
   * Get a user by ID (only accessible if you are that user)
   */
  @Get(':userId')
  @UseGuards(FirebaseAuthGuard)
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
   * Connect a Twitter account to a user
   */
  @Post(':userId/connect-twitter')
  @UseGuards(FirebaseAuthGuard)
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
   * Disconnect a Twitter account from a user
   */
  @Delete(':userId/disconnect-twitter')
  @UseGuards(FirebaseAuthGuard)
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
   * Update a user's Twitter connection status
   */
  @Post(':userId/connection-status')
  @UseGuards(FirebaseAuthGuard)
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
