// src/x/controllers/x-auth.controller.ts
import {
  Controller,
  Post,
  Body,
  UseGuards,
  Param,
  Delete,
  Get,
  NotFoundException,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { XAuthService } from '../services/x-auth.service';
import { FirebaseAuthGuard } from '../../auth/guards/firebase-auth';
import { CurrentUser } from '../../auth/decorators/current-user';
import { DecodedIdToken } from 'firebase-admin/auth';
import { ConnectTwitterDto } from '../dto/x-auth.dto';

@Controller('x/auth')
export class XAuthController {
  constructor(private readonly xAuthService: XAuthService) {}

  /**
   * Connect a Twitter account by storing OAuth tokens
   */
  @Post(':userId/connect')
  @UseGuards(FirebaseAuthGuard)
  async connectTwitterAccount(
    @Param('userId') userId: string,
    @Body() connectTwitterDto: ConnectTwitterDto,
    @CurrentUser() user: DecodedIdToken,
  ) {
    // Security check: users can only modify their own data
    if (user.uid !== userId) {
      throw new NotFoundException('User not found');
    }

    try {
      await this.xAuthService.connectAccount(userId, {
        accessToken: connectTwitterDto.accessToken,
        refreshToken: connectTwitterDto.refreshToken,
        tokenExpiresAt: connectTwitterDto.tokenExpiresAt,
      });

      return {
        success: true,
        message: 'Twitter account connected successfully',
      };
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: 'Failed to connect Twitter account',
          error: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  /**
   * Disconnect a Twitter account and remove stored tokens
   */
  @Delete(':userId/disconnect')
  @UseGuards(FirebaseAuthGuard)
  async disconnectTwitterAccount(
    @Param('userId') userId: string,
    @CurrentUser() user: DecodedIdToken,
  ) {
    // Security check: users can only modify their own data
    if (user.uid !== userId) {
      throw new NotFoundException('User not found');
    }

    try {
      await this.xAuthService.disconnectAccount(userId);

      return {
        success: true,
        message: 'Twitter account disconnected successfully',
      };
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: 'Failed to disconnect Twitter account',
          error: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  /**
   * Check if a Twitter account is connected
   */
  @Get(':userId/status')
  @UseGuards(FirebaseAuthGuard)
  async checkConnectionStatus(
    @Param('userId') userId: string,
    @CurrentUser() user: DecodedIdToken,
  ) {
    // Security check: users can only access their own data
    if (user.uid !== userId) {
      throw new NotFoundException('User not found');
    }

    const isConnected = await this.xAuthService.isAccountConnected(userId);

    return {
      isConnected,
    };
  }

  /**
   * Verify Twitter tokens are valid
   */
  @Post(':userId/verify')
  @UseGuards(FirebaseAuthGuard)
  async verifyTokens(
    @Param('userId') userId: string,
    @CurrentUser() user: DecodedIdToken,
  ) {
    // Security check: users can only access their own data
    if (user.uid !== userId) {
      throw new NotFoundException('User not found');
    }

    try {
      const tokens = await this.xAuthService.getUserTokens(userId);

      if (!tokens || !tokens.accessToken) {
        throw new HttpException(
          {
            success: false,
            message: 'No Twitter tokens found',
          },
          HttpStatus.BAD_REQUEST,
        );
      }

      const userInfo = await this.xAuthService.verifyTokens(tokens.accessToken);

      return {
        success: true,
        message: 'Twitter tokens are valid',
        username: userInfo.data.username,
      };
    } catch (error) {
      // Update connection status if tokens are invalid
      await this.xAuthService.updateConnectionStatus(userId, false);

      throw new HttpException(
        {
          success: false,
          message: 'Twitter tokens are invalid',
          error: error.message,
        },
        HttpStatus.BAD_REQUEST,
      );
    }
  }
}
