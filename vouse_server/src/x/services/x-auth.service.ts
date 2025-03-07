// src/x/services/x-auth.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { UserService } from '../../users/services/user.service';
import { XClientService } from './x-client.service';
import { TokenEncryption } from '../../common/utils/token_encryption.util';

interface TwitterAuthTokens {
  accessToken: string;
  refreshToken: string;
  tokenExpiresAt?: string;
}

/**
 * Service for managing Twitter OAuth tokens
 */
@Injectable()
export class XAuthService {
  private readonly logger = new Logger(XAuthService.name);
  private readonly tokenEncryption: TokenEncryption;

  constructor(
    private readonly userService: UserService,
    private readonly xClientService: XClientService,
  ) {
    this.tokenEncryption = new TokenEncryption();
  }

  /**
   * Connect a Twitter account by storing encrypted tokens
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
      // Encrypt tokens before storage
      const encryptedAccessToken = this.tokenEncryption.encrypt(
        tokens.accessToken,
      );
      const encryptedRefreshToken = this.tokenEncryption.encrypt(
        tokens.refreshToken,
      );

      // Verify the tokens by making a test API call
      await this.verifyTokens(tokens.accessToken);

      // Store the encrypted tokens in the database
      return this.userService.connectTwitter(userId, {
        accessToken: encryptedAccessToken,
        refreshToken: encryptedRefreshToken,
        tokenExpiresAt: tokens.tokenExpiresAt,
      });
    } catch (error) {
      this.logger.error(`Error connecting Twitter account: ${error.message}`);
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
      return await this.xClientService.verifyCredentials(accessToken);
    } catch (error) {
      this.logger.error(`Token verification failed: ${error.message}`);
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

    return {
      accessToken: this.tokenEncryption.decrypt(user.accessToken),
      refreshToken: this.tokenEncryption.decrypt(user.refreshToken),
      tokenExpiresAt: user.tokenExpiresAt?.toISOString(),
    };
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
}
