// src/x/services/x-client.service.ts
import { Injectable, Logger } from '@nestjs/common';
import axios, { AxiosInstance, AxiosRequestConfig } from 'axios';
import { UserService } from '../../users/services/user.service';
import { ConnectTwitterDto } from '../../users/dto/user.dto';
import * as crypto from 'crypto';
import * as OAuth from 'oauth-1.0a';
import { TokenEncryption } from '../../common/utils/token_encryption.util';
import { asApiError, ApiError, TwitterMediaResponse } from '../../common/types/api-response.types';

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
   * Make an authenticated GET request to the X/Twitter v2 API
   * 
   * @param endpoint - The API endpoint to call
   * @param userId - The user ID for authentication
   * @param params - Optional query parameters
   * @param isRetry - Whether this is a retry attempt after token refresh
   * @returns The API response
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
      if (error.response?.status === 401 && userId && !isRetry) {
        try {
          // Try to refresh the token
          await this.refreshToken(userId);
          
          // Retry the request with new token
          return this.get<T>(endpoint, userId, params, true);
        } catch (refreshErr) {
          const refreshError = asApiError(refreshErr);
          this.logger.error(`Token refresh failed: ${refreshError.message}`);
          throw refreshError;
        }
      }
      
      // Handle rate limit errors
      if (error.response?.status === 429) {
        const resetTime = error.response?.headers ? error.response.headers['x-rate-limit-reset'] : undefined;
        error.isRateLimit = true;
        error.resetTime = resetTime ? new Date(parseInt(resetTime.toString()) * 1000) : new Date(Date.now() + 15 * 60 * 1000);
      }
      
      // Handle other 401 errors
      if (error.response?.status === 401) {
        // Mark user as disconnected in case of persistent auth issues
        await this.userService.updateConnectionStatus(userId, { isConnected: false });
      }
      
      throw error;
    }
  }

  /**
   * Make an authenticated POST request to the X/Twitter v2 API
   * 
   * @param endpoint - The API endpoint to call
   * @param userId - The user ID for authentication
   * @param data - Request body data
   * @param params - Optional query parameters
   * @returns The API response
   */
  async post<T>(
    endpoint: string,
    userId: string,
    data: Record<string, any>,
    params: Record<string, any> = {},
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
      
      // Handle 401 Unauthorized errors by attempting to refresh the token
      if (error.response?.status === 401 && userId) {
        try {
          // Try to refresh the token
          await this.refreshToken(userId);
          
          // Retry the request with new token
          return this.post<T>(endpoint, userId, data, params);
        } catch (refreshErr) {
          const refreshError = asApiError(refreshErr);
          this.logger.error('Token refresh failed:', refreshError.message);
        }
      }
      
      throw error;
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
      
      // Request parameters for metrics
      const params = {
        'tweet.fields': 'public_metrics,non_public_metrics,organic_metrics,promoted_metrics',
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
   * Upload media to Twitter using v1.1 API
   * 
   * @param userId The user ID for authentication
   * @param mediaBase64 The base64-encoded media content
   * @param mediaType The media MIME type (e.g., "image/jpeg")
   * @returns The media ID from Twitter
   */
  async uploadMedia(
    userId: string,
    mediaBase64: string, 
    mediaType: string
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
          }
        )
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
          this.logger.error(`Upload error details: ${JSON.stringify(uploadError.response.data)}`);
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
      
      // Handle 401 Unauthorized by attempting to refresh the token
      if (error.response?.status === 401 && userId) {
        try {
          // Try to refresh the token
          await this.refreshToken(userId);
          
          // Try the upload again
          return this.uploadMedia(userId, mediaBase64, mediaType);
        } catch (refreshErr) {
          const refreshError = asApiError(refreshErr);
          this.logger.error('Token refresh failed:', refreshError.message);
        }
      }
      
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
    
    // Make the API request
    return this.post('/tweets', userId, tweetData);
  }

  /**
   * Refresh a user's X/Twitter access token
   * 
   * @param userId - The user ID to refresh the token for
   * @returns True if successful
   */
  async refreshToken(userId: string): Promise<boolean> {
    try {
      const user = await this.userService.findOneOrFail(userId);
      
      if (!user.refreshToken) {
        throw new Error('No refresh token available');
      }
      
      // Decrypt the refresh token
      const refreshTokenValue = this.tokenEncryption.decrypt(user.refreshToken);
      if (!refreshTokenValue) {
        throw new Error('Failed to decrypt refresh token');
      }
      
      // Call Twitter API to refresh token
      const response = await axios.post(
        'https://api.twitter.com/2/oauth2/token',
        new URLSearchParams({
          grant_type: 'refresh_token',
          refresh_token: refreshTokenValue,
          client_id: process.env.TWITTER_API_KEY || '',
        }).toString(),
        {
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        },
      );
      
      // Process the response
      const data = response.data;
      
      // Update user with new tokens
      const newAccessToken = this.tokenEncryption.encrypt(data.access_token);
      if (!newAccessToken) {
        throw new Error('Failed to encrypt new access token');
      }
      
      // Calculate expiration date
      const expiresIn = data.expires_in;
      const expiresAt = new Date(Date.now() + expiresIn * 1000);
      
      // Create connect Twitter DTO
      const connectDto: ConnectTwitterDto = {
        accessToken: newAccessToken,
        tokenExpiresAt: expiresAt.toISOString(),
      };
      
      // Add refresh token if available
      if (data.refresh_token) {
        const encryptedRefreshToken = this.tokenEncryption.encrypt(data.refresh_token);
        if (encryptedRefreshToken) {
          connectDto.refreshToken = encryptedRefreshToken;
        }
      }
      
      // Update user record using connectTwitter
      await this.userService.connectTwitter(userId, connectDto);
      
      return true;
    } catch (err) {
      const error = asApiError(err);
      if (error.response) {
        this.logger.error('Error response:', error.response.data);
        this.logger.error('Error status:', error.response.status);
      }
      this.logger.error(`Failed to refresh token: ${error.message}`);
      
      // Mark user as disconnected 
      await this.userService.updateConnectionStatus(userId, { isConnected: false });
      
      throw error;
    }
  }

  /**
   * Verify user credentials with Twitter API
   * 
   * @param accessToken - Access token to verify
   * @returns User information if token is valid
   */
  async verifyCredentials(accessToken: string): Promise<any> {
    this.logger.log('Verifying Twitter credentials');
    
    try {
      // Call the Twitter API to verify credentials
      const response = await axios.get(`${this.apiV2BaseUrl}/users/me`, {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
        params: {
          'user.fields': 'id,name,username,profile_image_url,verified',
        },
      });
      
      return response;
    } catch (error) {
      this.logger.error(`Failed to verify credentials: ${error.message}`);
      throw error;
    }
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
