// src/x/services/x-auth.service.ts
import { Injectable, Logger, Inject, forwardRef } from '@nestjs/common';
import { UserService } from '../../users/services/user.service';
import { XClientService } from './x-client.service';
import { TokenEncryption } from '../../common/utils/token_encryption.util';
import axios from 'axios';

interface TwitterAuthTokens {
  accessToken: string | null;
  refreshToken: string | null;
  tokenExpiresAt?: string | null;
}

/**
 * Service for managing Twitter OAuth tokens
 */
@Injectable()
export class XAuthService {
  private readonly logger = new Logger(XAuthService.name);

  // Add a cache for verified users to reduce API calls
  private readonly verifiedTokensCache: Map<
      string,
      {
        timestamp: number;
        username: string;
      }
  > = new Map();

  // Cache expiration time - 1 hour
  private readonly CACHE_EXPIRATION_MS = 60 * 60 * 1000;

  constructor(
      private readonly userService: UserService,
      @Inject(forwardRef(() => XClientService))
      private readonly xClientService: XClientService,
      private readonly tokenEncryption: TokenEncryption,
  ) {}

  /**
   * Connect a Twitter account by storing encrypted tokens
   * Creates the user if they don't exist
   *
   * @param userId Firebase user ID
   * @param tokens Twitter OAuth tokens
   * @returns Updated user record
   */
  async connectAccount(
      userId: string,
      tokens: TwitterAuthTokens,
  ): Promise<any> {
    try {
      if (!tokens.accessToken || !tokens.refreshToken) {
        throw new Error('Access token and refresh token are required');
      }

      // Encrypt tokens before storage
      const encryptedAccessToken = this.tokenEncryption.encrypt(
          tokens.accessToken,
      );
      const encryptedRefreshToken = this.tokenEncryption.encrypt(
          tokens.refreshToken,
      );

      try {
        // Verify the tokens by making a test API call
        const verifyResult = await this.verifyTokens(tokens.accessToken);

        // Add to verification cache
        if (verifyResult?.data?.username) {
          this.verifiedTokensCache.set(userId, {
            timestamp: Date.now(),
            username: verifyResult.data.username,
          });
        }
      } catch (error) {
        // If the error is due to rate limiting, still proceed with token storage
        // but log the issue
        if (error.isRateLimit) {
          this.logger.warn(
              `Rate limited during token verification. Proceeding with token storage anyway.`,
          );
        } else {
          // For other errors, reject the connection
          throw error;
        }
      }

      // IMPORTANT FIX: Find or create the user before connecting
      // This ensures the user exists in our database
      const user = await this.userService.findOrCreate(userId);
      this.logger.log(`User found or created: ${user.userId}`);

      // Store the encrypted tokens in the database
      return this.userService.connectTwitter(userId, {
        accessToken: encryptedAccessToken !== null ? encryptedAccessToken : '',
        refreshToken:
            encryptedRefreshToken !== null ? encryptedRefreshToken : '',
        // Convert null to undefined for tokenExpiresAt
        tokenExpiresAt:
            tokens.tokenExpiresAt === null ? undefined : tokens.tokenExpiresAt,
      });
    } catch (error) {
      const errorMessage =
          error instanceof Error ? error.message : String(error);
      this.logger.error(`Error connecting Twitter account: ${errorMessage}`);
      throw error;
    }
  }

  /**
   * Verify that the tokens are valid by making a test API call
   *
   * @param accessToken Twitter access token
   * @returns User info if tokens are valid
   */
  async verifyTokens(accessToken: string): Promise<any> {
    try {
      const credentials =
          await this.xClientService.verifyCredentials(accessToken);
      return {
        success: true,
        data: {
          id: credentials.data.id,
          name: credentials.data.name,
          username: credentials.data.username,
        },
      };
    } catch (error) {
      const errorMessage =
          error instanceof Error ? error.message : String(error);
      this.logger.error(`Token verification failed: ${errorMessage}`);

      // Pass through the error with rate limit info if present
      if (error.isRateLimit) {
        throw error;
      }

      throw new Error('Invalid Twitter tokens');
    }
  }

  /**
   * Disconnect a Twitter account by removing stored tokens
   *
   * @param userId Firebase user ID
   * @returns Updated user record
   */
  async disconnectAccount(userId: string): Promise<any> {
    // Remove from cache if present
    this.verifiedTokensCache.delete(userId);
    return this.userService.disconnectTwitter(userId);
  }

  /**
   * Get user's Twitter tokens (decrypted)
   *
   * @param userId Firebase user ID
   * @returns Decrypted tokens or null if not found
   */
  async getUserTokens(userId: string): Promise<TwitterAuthTokens | null> {
    const user = await this.userService.findOneOrFail(userId);

    if (!user.accessToken || !user.refreshToken) {
      return null;
    }

    try {
      const accessToken = this.tokenEncryption.decrypt(user.accessToken);
      const refreshToken = this.tokenEncryption.decrypt(user.refreshToken);

      return {
        accessToken: accessToken,
        refreshToken: refreshToken,
        tokenExpiresAt: user.tokenExpiresAt?.toISOString() || null,
      };
    } catch (error) {
      const errorMessage =
          error instanceof Error ? error.message : String(error);
      this.logger.error(
          `Failed to decrypt tokens for user ${userId}: ${errorMessage}`,
      );
      // If decryption fails, update connection status to false
      await this.updateConnectionStatus(userId, false);
      return null;
    }
  }

  /**
   * Check if a user has connected their Twitter account
   *
   * @param userId Firebase user ID
   * @returns Boolean indicating if connected
   */
  async isAccountConnected(userId: string): Promise<boolean> {
    const user = await this.userService.findOne(userId);
    return user?.isConnected || false;
  }

  /**
   * Update user's connection status
   *
   * @param userId Firebase user ID
   * @param isConnected Whether the account is connected
   * @returns Updated user record
   */
  async updateConnectionStatus(
      userId: string,
      isConnected: boolean,
  ): Promise<any> {
    return this.userService.updateConnectionStatus(userId, { isConnected });
  }

  /**
   * Obtains a new access token using the stored refresh token.
   * This is typically called when an API request fails due to an expired access token.
   *
   * @param userId The user ID for whom to refresh the tokens.
   * @returns A new access token if successful, otherwise null.
   */
  async refreshTokens(userId: string): Promise<string | null> {
    try {
      this.logger.log(`Attempting to refresh tokens for user ${userId}`);

      // Get the current tokens
      const tokens = await this.getUserTokens(userId);
      if (!tokens || !tokens.refreshToken) {
        this.logger.error(`No refresh token found for user ${userId}`);
        return null;
      }

      this.logger.debug(`Refresh token exists for user ${userId}`);

      // Twitter OAuth 2.0 token endpoint
      const tokenUrl = 'https://api.twitter.com/2/oauth2/token';

      // Get client credentials - BOTH are required for token refresh
      const clientId = process.env.TWITTER_API_KEY;
      const clientSecret = process.env.TWITTER_API_SECRET;

      if (!clientId || !clientSecret) {
        this.logger.error('Twitter API credentials not properly configured');
        return null;
      }

      // Create Basic Auth header for client authentication
      // This is required by Twitter for token refresh
      const basicAuth = Buffer.from(`${clientId}:${clientSecret}`).toString(
          'base64',
      );

      // Create form data for token refresh request
      const formData = new URLSearchParams();
      formData.append('refresh_token', tokens.refreshToken);
      formData.append('grant_type', 'refresh_token');
      formData.append('client_id', clientId);

      this.logger.debug('Sending refresh token request to Twitter API');

      // Make the request to refresh the token with proper authentication
      const response = await axios.post(tokenUrl, formData.toString(), {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          Authorization: `Basic ${basicAuth}`,
        },
      });

      // Log response for debugging
      this.logger.debug(
          `Token refresh response: ${JSON.stringify(response.data)}`,
      );

      // Extract new tokens from response
      const newAccessToken = response.data.access_token;
      const newRefreshToken =
          response.data.refresh_token || tokens.refreshToken;
      const expiresIn = response.data.expires_in || 7200;

      // Calculate token expiration time
      const tokenExpiresAt = new Date();
      tokenExpiresAt.setSeconds(tokenExpiresAt.getSeconds() + expiresIn);

      // Encrypt the new tokens
      const encryptedAccessToken = this.tokenEncryption.encrypt(newAccessToken);
      const encryptedRefreshToken =
          this.tokenEncryption.encrypt(newRefreshToken);

      // Update the tokens in the database
      await this.userService.connectTwitter(userId, {
        accessToken: encryptedAccessToken || '', // Convert null to empty string
        refreshToken: encryptedRefreshToken || '', // Convert null to empty string
        tokenExpiresAt: tokenExpiresAt.toISOString(),
      });

      this.logger.log(
          `Successfully refreshed tokens for user ${userId}, expires at ${tokenExpiresAt.toISOString()}`,
      );

      // Return the new access token for immediate use
      return newAccessToken;
    } catch (error) {
      const errorMessage =
          error instanceof Error ? error.message : String(error);
      this.logger.error(
          `Failed to refresh tokens for user ${userId}: ${errorMessage}`,
      );

      // If the refresh token is invalid, update connection status
      if (error.response?.status === 400 || error.response?.status === 401) {
        this.logger.warn(
            `Invalid refresh token for user ${userId}, disconnecting account`,
        );
        await this.updateConnectionStatus(userId, false);
      }

      return null;
    }
  }
}
