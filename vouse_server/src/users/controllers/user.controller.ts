// src/users/controllers/user.controller.ts
import { Controller, Get, Post, Body, Param, Delete } from '@nestjs/common';
import { UserService } from '../services/user.service';
import { User } from '../entities/user.entity';
import { ConnectTwitterDto, UpdateConnectionStatusDto } from '../dto/user.dto';

/**
 * Controller for user-related endpoints
 */
@Controller('users')
export class UserController {
  constructor(private readonly userService: UserService) {}

  /**
   * Get a user by ID
   */
  @Get(':userId')
  async findOne(@Param('userId') userId: string): Promise<User> {
    return this.userService.findOneOrFail(userId);
  }

  /**
   * Connect a Twitter account to a user
   */
  @Post(':userId/connect-twitter')
  async connectTwitter(
    @Param('userId') userId: string,
    @Body() connectTwitterDto: ConnectTwitterDto,
  ): Promise<User> {
    return this.userService.connectTwitter(userId, connectTwitterDto);
  }

  /**
   * Disconnect a Twitter account from a user
   */
  @Delete(':userId/disconnect-twitter')
  async disconnectTwitter(@Param('userId') userId: string): Promise<User> {
    return this.userService.disconnectTwitter(userId);
  }

  /**
   * Update a user's Twitter connection status
   */
  @Post(':userId/connection-status')
  async updateConnectionStatus(
    @Param('userId') userId: string,
    @Body() updateConnectionStatusDto: UpdateConnectionStatusDto,
  ): Promise<User> {
    return this.userService.updateConnectionStatus(
      userId,
      updateConnectionStatusDto,
    );
  }
}
