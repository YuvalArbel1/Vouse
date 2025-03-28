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
  Query,
} from '@nestjs/common';
import { XAuthService } from '../services/x-auth.service';
import { XClientService } from '../services/x-client.service';
import { FirebaseAuthGuard } from '../../auth/guards/firebase-auth';
import { CurrentUser } from '../../auth/decorators/current-user';
import { DecodedIdToken } from 'firebase-admin/auth';
import { ConnectTwitterDto } from '../dto/x-auth.dto';
import * as crypto from 'crypto';

@Controller('x/auth')
export class XAuthController {
  constructor(
    private readonly xAuthService: XAuthService,
    private readonly xClientService: XClientService,
  ) {}

  /**
   * Generate an OAuth 2.0 authorization URL with the proper scopes
   * IMPORTANT: This includes the 'offline.access' scope to enable refresh tokens
   */
  @Get('authorize')
  generateAuthUrl(@Query('redirect_uri') redirectUri: string) {
    try {
      // Generate random state for CSRF protection
      const state = crypto.randomBytes(16).toString('hex');

      // Generate the authorization URL
      const authUrl = this.xClientService.generateAuthorizationUrl(
        redirectUri || 'http://localhost:3000/auth/callback',
        state,
      );

      return {
        success: true,
        url: authUrl,
        state,
      };
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: 'Failed to generate authorization URL',
          error: error.message,
        },
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

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
      // Log the incoming tokens for debugging
      console.log('Received tokens - accessToken exists:', !!connectTwitterDto.accessToken);
      console.log('Received tokens - refreshToken exists:', !!connectTwitterDto.refreshToken);
      console.log('Received tokens - tokenExpiresAt:', connectTwitterDto.tokenExpiresAt);

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
      // Special handling for rate limit errors
      if (error.isRateLimit) {
        const waitTime = error.resetTime
          ? new Date(parseInt(error.resetTime) * 1000)
          : 'unknown time';

        throw new HttpException(
          {
            success: false,
            message: `Twitter API rate limit exceeded. Please try again after ${waitTime}`,
            error: 'RATE_LIMIT_EXCEEDED',
            resetTime: error.resetTime,
            isRateLimit: true,
          },
          HttpStatus.TOO_MANY_REQUESTS, // 429
        );
      }

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

      try {
        const userInfo = await this.xAuthService.verifyTokens(
          tokens.accessToken,
        );

        return {
          success: true,
          message: 'Twitter tokens are valid',
          username: userInfo.data.username,
        };
      } catch (error) {
        // Special handling for rate limit errors
        if (error.isRateLimit) {
          const waitTime = error.resetTime
            ? new Date(parseInt(error.resetTime) * 1000)
            : 'unknown time';

          throw new HttpException(
            {
              success: false,
              message: `Twitter API rate limit exceeded. Please try again after ${waitTime}`,
              error: 'RATE_LIMIT_EXCEEDED',
              resetTime: error.resetTime,
              isRateLimit: true,
            },
            HttpStatus.TOO_MANY_REQUESTS, // 429
          );
        }

        // For non-rate-limit errors, update connection status
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
    } catch (error) {
      // If the error is already an HttpException (like from the nested try/catch),
      // just rethrow it
      if (error instanceof HttpException) {
        throw error;
      }

      throw new HttpException(
        {
          success: false,
          message: 'Failed to verify Twitter tokens',
          error: error.message,
        },
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
