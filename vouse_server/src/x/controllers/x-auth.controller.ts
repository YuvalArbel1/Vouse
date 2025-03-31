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
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiParam,
  ApiQuery,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { XAuthService } from '../services/x-auth.service';
import { XClientService } from '../services/x-client.service';
import { FirebaseAuthGuard } from '../../auth/guards/firebase-auth';
import { CurrentUser } from '../../auth/decorators/current-user';
import { DecodedIdToken } from 'firebase-admin/auth';
import { ConnectTwitterDto } from '../dto/x-auth.dto';
import * as crypto from 'crypto';

@ApiTags('X / Twitter Auth')
@Controller('x/auth')
export class XAuthController {
  constructor(
    private readonly xAuthService: XAuthService,
    private readonly xClientService: XClientService,
  ) {}

  /**
   * Generate an OAuth 2.0 authorization URL for Twitter
   */
  @Get('authorize')
  @ApiOperation({ summary: 'Generate Twitter OAuth 2.0 authorization URL' })
  @ApiQuery({
    name: 'redirect_uri',
    required: true,
    description: "Your application's callback URL registered with Twitter",
    example: 'vouseflutter://callback',
  })
  @ApiResponse({
    status: 200,
    description: 'Returns the authorization URL and state parameter.',
  })
  @ApiResponse({
    status: 500,
    description: 'Failed to generate URL (e.g., missing Twitter API Key).',
  })
  generateAuthUrl(@Query('redirect_uri') redirectUri: string) {
    try {
      // Generate random state for CSRF protection
      const state = crypto.randomBytes(16).toString('hex');

      // Generate the authorization URL
      const authUrl = this.xClientService.generateAuthorizationUrl(
        redirectUri || 'http://localhost:3000/auth/callback', // Default might need adjustment
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
  @ApiBearerAuth() // Indicate Bearer token auth is required
  @ApiOperation({ summary: 'Connect Twitter account by storing OAuth tokens' })
  @ApiParam({
    name: 'userId',
    description: 'The Firebase UID of the user',
    example: 'firebaseUid123',
  })
  @ApiResponse({
    status: 201,
    description: 'Twitter account connected successfully.',
  })
  @ApiResponse({
    status: 400,
    description: 'Bad Request (e.g., invalid tokens, missing tokens).',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized.' })
  @ApiResponse({ status: 404, description: 'User not found.' })
  @ApiResponse({
    status: 429,
    description: 'Rate limit exceeded during token verification.',
  })
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
      // Enhanced logging for incoming tokens
      this.xAuthService['logger'].log(
        `[Connect Request - User: ${userId}] Received tokens - AccessToken provided: ${!!connectTwitterDto.accessToken}, RefreshToken provided: ${!!connectTwitterDto.refreshToken}, ExpiresAt: ${connectTwitterDto.tokenExpiresAt}`,
      );
      // Log the actual refresh token presence more clearly
      if (!connectTwitterDto.refreshToken) {
        this.xAuthService['logger'].warn(
          `[Connect Request - User: ${userId}] Refresh token is MISSING from the request body.`,
        );
      }

      // Log the incoming tokens for debugging
      console.log(
        'Received tokens - accessToken exists:',
        !!connectTwitterDto.accessToken,
      );
      console.log(
        'Received tokens - refreshToken exists:',
        !!connectTwitterDto.refreshToken,
      );
      console.log(
        'Received tokens - tokenExpiresAt:',
        connectTwitterDto.tokenExpiresAt,
      );

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
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Disconnect Twitter account and remove tokens' })
  @ApiParam({
    name: 'userId',
    description: 'The Firebase UID of the user',
    example: 'firebaseUid123',
  })
  @ApiResponse({
    status: 200,
    description: 'Twitter account disconnected successfully.',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized.' })
  @ApiResponse({ status: 404, description: 'User not found.' })
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
   * Check if the current user's Twitter account is connected
   */
  @Get(':userId/status')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Check if user's Twitter account is connected" })
  @ApiParam({
    name: 'userId',
    description: 'The Firebase UID of the user',
    example: 'firebaseUid123',
  })
  @ApiResponse({
    status: 200,
    description: 'Returns connection status.',
    schema: { properties: { isConnected: { type: 'boolean' } } },
  })
  @ApiResponse({ status: 401, description: 'Unauthorized.' })
  @ApiResponse({ status: 404, description: 'User not found.' })
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
   * Verify if the stored Twitter tokens for the user are still valid
   */
  @Post(':userId/verify')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Verify if stored Twitter tokens are valid' })
  @ApiParam({
    name: 'userId',
    description: 'The Firebase UID of the user',
    example: 'firebaseUid123',
  })
  @ApiResponse({
    status: 201,
    description: 'Tokens are valid.',
    schema: {
      properties: {
        success: { type: 'boolean' },
        message: { type: 'string' },
        username: { type: 'string' },
      },
    },
  })
  @ApiResponse({
    status: 400,
    description: 'Bad Request (e.g., tokens not found or invalid).',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized.' })
  @ApiResponse({ status: 404, description: 'User not found.' })
  @ApiResponse({
    status: 429,
    description: 'Rate limit exceeded during verification.',
  })
  async verifyTokens(
    @Param('userId') userId: string,
    @CurrentUser() user: DecodedIdToken,
  ) {
    // Security check: users can only access their own data
    if (user.uid !== userId) {
      throw new NotFoundException('User not found');
    }

    // Directly attempt to fetch user info using xClientService.get
    // This method handles fetching stored tokens and refreshing them if necessary.
    try {
      const userInfo = await this.xClientService.get<any>('/users/me', userId, {
        'user.fields': 'id,name,username', // Request necessary fields
      });

      // If the call succeeds (potentially after a refresh), tokens are valid
      return {
        success: true,
        message: 'Twitter tokens are valid',
        username: userInfo.data.username, // Access username from the response data
      };
    } catch (error) {
      // Handle errors from xClientService.get (which includes refresh failures)

      // Special handling for rate limit errors passed through from xClientService
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

      // If the error indicates a failed refresh or invalid initial tokens,
      // the user's connection status might have already been set to false
      // by the underlying services (xClientService.get -> xAuthService.refreshTokens).
      // We return a 400 Bad Request indicating invalid/unusable tokens.
      throw new HttpException(
        {
          success: false,
          message: 'Twitter tokens are invalid or could not be refreshed',
          error: error.message,
        },
        HttpStatus.BAD_REQUEST, // 400
      );
    }
  }
}
