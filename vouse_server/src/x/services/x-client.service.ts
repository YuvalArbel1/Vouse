// src/x/services/x-client.service.ts
import { Injectable, Logger, Inject, forwardRef } from '@nestjs/common'; // Added Inject, forwardRef
import axios, { AxiosInstance, AxiosRequestConfig } from 'axios';
import { UserService } from '../../users/services/user.service';
import { ConnectTwitterDto } from '../../users/dto/user.dto';
import { XAuthService } from './x-auth.service'; // Added XAuthService import
import * as crypto from 'crypto';
import * as OAuth from 'oauth-1.0a';
import { TokenEncryption } from '../../common/utils/token_encryption.util';
import {
  asApiError,
  ApiError,
  TwitterMediaResponse,
} from '../../common/types/api-response.types';

/**
 * Service for communicating with the X/Twitter API
 * Handles authentication, token management, and API requests
 */
@Injectable()
export class XClientService {
  private readonly logger = new Logger(XClientService.name);
  private readonly apiV2BaseUrl = 'https://api.twitter.com/2';
  private readonly apiV1BaseUrl = 'https://api.twitter.com/1.1';
  private readonly uploadApiUrl = 'https://upload.twitter.com/1.1';
  private readonly axiosInstance: AxiosInstance;

  constructor(
    private readonly userService: UserService,
    private readonly tokenEncryption: TokenEncryption,
    // Inject XAuthService - forwardRef might be needed if circular dependency exists
    @Inject(forwardRef(() => XAuthService))
    private readonly xAuthService: XAuthService,
  ) {
    // Initialize Axios client with default config
    this.axiosInstance = axios.create({
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });
  }

  /**
   * Make an authenticated GET request to the X/Twitter v2 API.
   * Handles automatic token refresh on 401 errors.
   *
   * @param endpoint - The API endpoint to call (e.g., '/users/me')
   * @param userId - The user ID for authentication
   * @param params - Optional query parameters
   * @param isRetry - Internal flag to prevent infinite retry loops on refresh failure
   * @returns The API response data
   */
  async get<T>(
    endpoint: string,
    userId: string,
    params: Record<string, any> = {},
    isRetry = false,
  ): Promise<T> {
    try {
      const url = `${this.apiV2BaseUrl}${endpoint}`;
      const user = await this.userService.findOneOrFail(userId);

      if (!user.accessToken || !user.isConnected) {
        throw new Error('User not connected to X/Twitter');
      }

      // Decrypt the access token
      const accessToken = this.tokenEncryption.decrypt(user.accessToken);
      if (!accessToken) {
        throw new Error('Failed to decrypt access token');
      }

      // Make the API request with bearer token
      const response = await this.axiosInstance.get(url, {
        params,
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      });

      return response.data as T;
    } catch (err) {
      const error = asApiError(err);

      // Handle 401 Unauthorized errors by refreshing the token
      // Handle 401 Unauthorized: Attempt token refresh via XAuthService and retry ONCE.
      if (error.response?.status === 401 && userId && !isRetry) {
        this.logger.warn(
          `Received 401 for GET ${endpoint}. Attempting token refresh for user ${userId}.`,
        );
        try {
          // Try to refresh the token using the centralized service
          const newAccessToken = await this.xAuthService.refreshTokens(userId);

          if (newAccessToken) {
            this.logger.log(
              `Token refresh successful for user ${userId}. Retrying GET ${endpoint}.`,
            );
            // Retry the request with the updated token (implicitly stored by xAuthService)
            return this.get<T>(endpoint, userId, params, true); // Pass isRetry=true
          } else {
            this.logger.error(
              `Token refresh failed for user ${userId}. Cannot retry GET ${endpoint}.`,
            );
            // If refresh failed, throw the original error or a specific refresh error
            throw new Error('Token refresh failed');
          }
        } catch (refreshErr) {
          const refreshError = asApiError(refreshErr);
          this.logger.error(`Token refresh failed: ${refreshError.message}`);
          throw refreshError;
        }
      }

      // Handle rate limit errors
      if (error.response?.status === 429) {
        const resetTime = error.response?.headers
          ? error.response.headers['x-rate-limit-reset']
          : undefined;
        error.isRateLimit = true;
        error.resetTime = resetTime
          ? new Date(parseInt(resetTime.toString()) * 1000)
          : new Date(Date.now() + 15 * 60 * 1000);
      }

      // Handle other 401 errors
      if (error.response?.status === 401) {
        // Mark user as disconnected in case of persistent auth issues
        await this.userService.updateConnectionStatus(userId, {
          isConnected: false,
        });
      }

      throw error;
    }
  }

  /**
   * Make an authenticated POST request to the X/Twitter v2 API.
   * Handles automatic token refresh on 401 errors.
   *
   * @param endpoint - The API endpoint to call (e.g., '/tweets')
   * @param userId - The user ID for authentication
   * @param data - Request body data
   * @param params - Optional query parameters
   * @param isRetry - Internal flag to prevent infinite retry loops on refresh failure
   * @returns The API response data
   */
  async post<T>(
    endpoint: string,
    userId: string,
    data: Record<string, any>,
    params: Record<string, any> = {},
    isRetry = false, // Added isRetry parameter
  ): Promise<T> {
    try {
      const url = `${this.apiV2BaseUrl}${endpoint}`;
      const user = await this.userService.findOneOrFail(userId);

      if (!user.accessToken || !user.isConnected) {
        throw new Error('User not connected to X/Twitter');
      }

      // Decrypt the access token
      const accessToken = this.tokenEncryption.decrypt(user.accessToken);
      if (!accessToken) {
        throw new Error('Failed to decrypt access token');
      }

      // Make the API request with bearer token
      const response = await this.axiosInstance.post(url, data, {
        params,
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      });

      return response.data as T;
    } catch (err) {
      const error = asApiError(err);

      // Handle 401 Unauthorized: Attempt token refresh via XAuthService and retry ONCE.
      if (error.response?.status === 401 && userId && !isRetry) {
        this.logger.warn(
          `Received 401 for POST ${endpoint}. Attempting token refresh for user ${userId}.`,
        );
        try {
          // Try to refresh the token using the centralized service
          const newAccessToken = await this.xAuthService.refreshTokens(userId);

          if (newAccessToken) {
            this.logger.log(
              `Token refresh successful for user ${userId}. Retrying POST ${endpoint}.`,
            );
            // Retry the request with the updated token (implicitly stored by xAuthService)
            return this.post<T>(endpoint, userId, data, params, true); // Pass isRetry=true
          } else {
            this.logger.error(
              `Token refresh failed for user ${userId}. Cannot retry POST ${endpoint}.`,
            );
            // If refresh failed, throw the original error or a specific refresh error
            throw new Error('Token refresh failed');
          }
        } catch (refreshErr) {
          const refreshError = asApiError(refreshErr);
          this.logger.error(
            `Token refresh failed during POST retry: ${refreshError.message}`,
          );
          // Throw the refresh error to prevent falling through to throw the original 401
          throw refreshError;
        }
      }

      // Handle rate limit errors
      if (error.response?.status === 429) {
        const resetTime = error.response?.headers
          ? error.response.headers['x-rate-limit-reset']
          : undefined;
        error.isRateLimit = true;
        error.resetTime = resetTime
          ? new Date(parseInt(resetTime.toString()) * 1000)
          : new Date(Date.now() + 15 * 60 * 1000);
      }

      // Handle other 401 errors (e.g., if retry failed or wasn't attempted)
      if (error.response?.status === 401) {
        // Mark user as disconnected in case of persistent auth issues
        await this.userService.updateConnectionStatus(userId, {
          isConnected: false,
        });
      }

      throw error; // Throw original or modified error
    }
  }

  /**
   * Get tweet metrics from the Twitter API
   *
   * @param tweetId - The ID of the tweet to get metrics for
   * @param accessToken - The user's access token (optional if userId is provided)
   * @param userId - The user's ID (optional)
   * @returns Tweet metrics from the Twitter API
   */
  async getTweetMetrics(
    tweetId: string,
    accessToken?: string,
    userId?: string,
  ): Promise<any> {
    try {
      this.logger.log(`Getting metrics for tweet ${tweetId}`);

      // Endpoint for tweet lookup with metrics
      const endpoint = `/tweets/${tweetId}`;

      // Request parameters for metrics - only request accessible metrics
      // Removed promoted_metrics which causes errors for non-promoted tweets
      const params = {
        'tweet.fields': 'public_metrics,non_public_metrics,organic_metrics',
      };

      // If userId is provided, use the user's own token via the get method
      if (userId) {
        return this.get<any>(endpoint, userId, params);
      }

      // Otherwise use the provided access token directly
      if (!accessToken) {
        throw new Error('Either userId or accessToken must be provided');
      }

      const url = `${this.apiV2BaseUrl}${endpoint}`;
      const response = await this.axiosInstance.get(url, {
        params,
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      });

      return response.data;
    } catch (error) {
      this.logger.error(`Failed to get tweet metrics: ${error.message}`);
      throw error;
    }
  }

  /**
   * Upload media to Twitter
   *
   * @param userId - The user ID for authentication
   * @param mediaBase64 - The base64-encoded media content
   * @param mediaType - The media MIME type
   * @returns The media ID from Twitter
   */
  /**
   * Upload media to Twitter using v1.1 API.
   * Handles automatic token refresh on 401 errors (though v1.1 uses different auth).
   * Note: Token refresh logic might need adjustment if v1.1 auth fails differently.
   *
   * @param userId The user ID for authentication
   * @param mediaBase64 The base64-encoded media content
   * @param mediaType The media MIME type (e.g., "image/jpeg")
   * @param isRetry Internal flag to prevent infinite retry loops on refresh failure
   * @returns The media ID string from Twitter
   */
  async uploadMedia(
    userId: string,
    mediaBase64: string,
    mediaType: string,
    isRetry = false, // Added isRetry parameter
  ): Promise<string> {
    try {
      this.logger.log(`Starting v1.1 media upload for user ${userId}`);

      const user = await this.userService.findOneOrFail(userId);

      if (!user.accessToken || !user.refreshToken) {
        throw new Error('User not connected to X/Twitter');
      }

      const accessToken = this.tokenEncryption.decrypt(user.accessToken);

      if (!accessToken) {
        throw new Error('Failed to decrypt access token');
      }

      // Create form data for the media upload
      const formData = new FormData();
      const mediaBuffer = Buffer.from(mediaBase64, 'base64');

      // Create blob with the correct size
      const blob = new Blob([mediaBuffer], { type: mediaType });
      formData.append('media', blob);

      // Create OAuth signer for v1.1 API
      const oauth = this.createOAuth();

      // V1.1 Upload URL
      const uploadUrl = `${this.uploadApiUrl}/media/upload.json`;

      // OAuth header for the request
      const authHeader = oauth.toHeader(
        oauth.authorize(
          {
            url: uploadUrl,
            method: 'POST',
          },
          {
            key: process.env.TWITTER_ACCESS_TOKEN || '',
            secret: process.env.TWITTER_ACCESS_SECRET || '',
          },
        ),
      );

      // Use Axios directly for media upload with formData
      try {
        this.logger.log(`Sending media upload request to ${uploadUrl}`);

        // Upload media using v1.1 API
        const response = await axios.post(uploadUrl, formData, {
          headers: {
            ...authHeader,
            'Content-Type': 'multipart/form-data',
          },
        });

        // Extract media ID from the response
        const mediaId = response.data.media_id_string;
        this.logger.log(`Successfully uploaded media with ID: ${mediaId}`);

        return mediaId;
      } catch (uploadError) {
        this.logger.error(`Error during media upload: ${uploadError.message}`);
        if (uploadError.response) {
          this.logger.error(
            `Upload error details: ${JSON.stringify(uploadError.response.data)}`,
          );
        }
        throw uploadError;
      }
    } catch (err) {
      const error = asApiError(err);
      this.logger.error(`Failed to upload media: ${error.message}`);

      if (error.response) {
        this.logger.error(
          `Error details: ${JSON.stringify(error.response.data)}`,
        );
      }

      // Handle 401 Unauthorized: Attempt token refresh via XAuthService and retry ONCE.
      // Note: V1.1 API might return different error codes for auth issues. This assumes 401 for simplicity.
      if (error.response?.status === 401 && userId && !isRetry) {
        this.logger.warn(
          `Received 401 during media upload. Attempting token refresh for user ${userId}.`,
        );
        try {
          // Try to refresh the token using the centralized service
          const newAccessToken = await this.xAuthService.refreshTokens(userId);

          if (newAccessToken) {
            this.logger.log(
              `Token refresh successful for user ${userId}. Retrying media upload.`,
            );
            // Retry the upload with the updated token (implicitly stored by xAuthService)
            return this.uploadMedia(userId, mediaBase64, mediaType, true); // Pass isRetry=true
          } else {
            this.logger.error(
              `Token refresh failed for user ${userId}. Cannot retry media upload.`,
            );
            // If refresh failed, throw the original error or a specific refresh error
            throw new Error('Token refresh failed');
          }
        } catch (refreshErr) {
          const refreshError = asApiError(refreshErr);
          this.logger.error(
            `Token refresh failed during media upload retry: ${refreshError.message}`,
          );
          // Throw the refresh error to prevent falling through to throw the original 401
          throw refreshError;
        }
      }
      // Handle other errors or re-throw if refresh wasn't attempted/failed
      throw error;
    }
  }

  /**
   * Post a tweet to Twitter
   *
   * @param userId - The user ID for authentication
   * @param text - The tweet text
   * @param mediaIds - Optional array of media IDs to attach to the tweet
   * @returns The response from Twitter
   */
  async postTweet(
    userId: string,
    text: string,
    mediaIds?: string[],
  ): Promise<any> {
    // Construct tweet data
    const tweetData: Record<string, any> = {
      text,
    };

    // Add media if provided
    if (mediaIds && mediaIds.length > 0) {
      tweetData.media = {
        media_ids: mediaIds,
      };
    }

    // Make the API request using the centralized post method which handles refresh
    return this.post('/tweets', userId, tweetData);
  }

  /**
   * Verify user credentials with Twitter API using the user's current token.
   * This method does NOT handle token refresh itself. It simply checks if a given
   * access token is valid by making a direct API call.
   *
   * @param accessToken - Access token to verify
   * @returns User information if token is valid
   */
  async verifyCredentials(accessToken: string): Promise<any> {
    this.logger.log('Verifying Twitter credentials with provided token');

    try {
      // Call the Twitter API directly to verify the provided credentials
      // This does NOT use the internal 'get' method and won't trigger refresh
      const response = await axios.get(`${this.apiV2BaseUrl}/users/me`, {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
        params: {
          'user.fields': 'id,name,username,profile_image_url,verified',
        },
      });

      // Return the raw response object from Axios
      return response;
    } catch (error) {
      this.logger.error(`Failed to verify credentials: ${error.message}`);
      // Re-throw the original error
      throw error;
    }
  }

  /**
   * Generate an OAuth 2.0 authorization URL for Twitter with the required scopes
   *
   * @param redirectUri The callback URL registered in your Twitter application
   * @param state Optional state parameter for CSRF protection
   * @param pkceChallenge Optional PKCE challenge code
   * @param pkceMethod The PKCE challenge method (plain or S256)
   * @returns The authorization URL to redirect users to
   */
  generateAuthorizationUrl(
    redirectUri: string,
    state: string = crypto.randomBytes(16).toString('hex'),
    pkceChallenge: string = 'challenge',
    pkceMethod: 'plain' | 'S256' = 'plain',
  ): string {
    // Get client ID from environment
    const clientId = process.env.TWITTER_API_KEY;

    if (!clientId) {
      throw new Error('TWITTER_API_KEY environment variable is required');
    }

    // Base Twitter OAuth 2.0 authorization URL
    const baseUrl = 'https://x.com/i/oauth2/authorize';

    // Define required scopes for our application
    const scopes = [
      'tweet.read',
      'tweet.write',
      'users.read',
      'offline.access',
    ];

    // Build the query parameters
    const params = new URLSearchParams({
      response_type: 'code',
      client_id: clientId,
      redirect_uri: redirectUri,
      state: state,
      scope: scopes.join(' '),
      code_challenge: pkceChallenge,
      code_challenge_method: pkceMethod,
    });

    // Return the fully constructed URL
    return `${baseUrl}?${params.toString()}`;
  }

  /**
   * Create an OAuth 1.0a helper for Twitter API authentication
   * Required for some Twitter API endpoints that don't support OAuth 2.0
   *
   * @returns OAuth 1.0a instance
   */
  private createOAuth(): OAuth {
    // Create OAuth 1.0a instance
    const oauth = new OAuth({
      consumer: {
        key: process.env.TWITTER_API_KEY || '',
        secret: process.env.TWITTER_API_SECRET || '',
      },
      signature_method: 'HMAC-SHA1',
      hash_function(baseString: string, key: string) {
        return crypto
          .createHmac('sha1', key)
          .update(baseString)
          .digest('base64');
      },
    });

    return oauth;
  }
}
