// src/x/services/x-client.service.ts
import { Injectable, Logger, Inject, forwardRef } from '@nestjs/common';
import axios, { AxiosInstance, AxiosRequestConfig } from 'axios';
import * as dotenv from 'dotenv';
import * as FormData from 'form-data';
import * as crypto from 'crypto';
import { XAuthService } from './x-auth.service';

dotenv.config();

/**
 * Service for making API calls to Twitter (X) using Twitter API v2
 *
 * This service handles all direct communication with Twitter's API v2 endpoints.
 * Twitter API v2 provides more modern functionality compared to v1.1, including:
 * - Enhanced tweet objects with more detailed metrics
 * - Better media handling
 * - Improved error messages and response formats
 * - More granular scopes for OAuth 2.0
 */
@Injectable()
export class XClientService {
  private readonly logger = new Logger(XClientService.name);
  private client: AxiosInstance;
  // Twitter API v2 base URL
  private readonly apiBaseUrl = 'https://api.twitter.com/2';
  // Twitter API v1.1 base URL (for endpoints not available in v2)
  private readonly apiV1BaseUrl = 'https://api.twitter.com/1.1';
  // Twitter media upload URL (still v1.1)
  private readonly mediaUploadUrl =
    'https://upload.twitter.com/1.1/media/upload.json';

  constructor(
    @Inject(forwardRef(() => XAuthService))
    private readonly xAuthService: XAuthService,
  ) {
    // Create a pre-configured axios instance for API calls
    this.client = axios.create({
      baseURL: this.apiBaseUrl,
      timeout: 30000, // 30 seconds timeout (increased for media uploads)
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Add response interceptor for logging
    this.client.interceptors.response.use(
      (response) => {
        return response;
      },
      (error) => {
        // Log the error but don't expose sensitive info
        if (error.response) {
          this.logger.error(
            `Twitter API error: ${error.response.status} - ${JSON.stringify(error.response.data)}`,
          );
        } else if (error.request) {
          this.logger.error('Twitter API error: No response received');
        } else {
          this.logger.error(`Twitter API error: ${error.message}`);
        }
        return Promise.reject(error);
      },
    );
  }

  /**
   * Make an authenticated request to Twitter's API using a user's access token
   * Now with automatic token refresh on 401 errors
   *
   * @param accessToken User's OAuth access token
   * @param method HTTP method
   * @param endpoint API endpoint (without base URL)
   * @param data Request body data
   * @param params Query parameters
   * @param baseUrl Optional base URL override
   * @param userId User's Firebase ID (needed for token refresh)
   * @param isRetry Flag to prevent infinite refresh loops
   * @returns API response data
   */
  async makeAuthenticatedRequest(
    accessToken: string,
    method: string,
    endpoint: string,
    data?: any,
    params?: any,
    baseUrl?: string,
    userId?: string,
    isRetry: boolean = false,
  ): Promise<any> {
    const config: AxiosRequestConfig = {
      method,
      url: endpoint,
      baseURL: baseUrl || this.apiBaseUrl,
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
      data,
      params,
    };

    try {
      const response = await axios.request(config);
      return response.data;
    } catch (error) {
      // Handle token expiration (401 Unauthorized)
      if (error.response?.status === 401 && userId && !isRetry) {
        this.logger.log(
          `Access token expired for user ${userId}, attempting refresh...`,
        );

        try {
          // Try to refresh the token
          const newAccessToken = await this.xAuthService.refreshTokens(userId);

          if (newAccessToken) {
            this.logger.log(
              `Successfully refreshed token for user ${userId}, retrying request`,
            );

            // Retry the original request with the new token, but mark as retry
            // to prevent potential infinite loops
            return this.makeAuthenticatedRequest(
              newAccessToken,
              method,
              endpoint,
              data,
              params,
              baseUrl,
              userId,
              true,
            );
          }
        } catch (refreshError) {
          this.logger.error(`Token refresh failed: ${refreshError.message}`);
        }
      }

      // If the error is due to rate limiting, add specific info
      if (error.response?.status === 429) {
        const resetTime = error.response.headers['x-rate-limit-reset'];
        const rateError: any = new Error('Twitter API rate limit exceeded');
        rateError.isRateLimit = true;
        rateError.resetTime = resetTime;
        throw rateError;
      }

      // If the error is due to an expired token, throw a specific error
      if (error.response?.status === 401) {
        this.logger.warn('Twitter access token expired or invalid');
        throw new Error('TWITTER_TOKEN_EXPIRED');
      }

      // Re-throw the original error
      throw error;
    }
  }

  /**
   * Make an application-level authenticated request using app bearer token
   *
   * @param method HTTP method
   * @param endpoint API endpoint (without base URL)
   * @param data Request body data
   * @param params Query parameters
   * @returns API response data
   */
  async makeAppAuthenticatedRequest(
    method: string,
    endpoint: string,
    data?: any,
    params?: any,
  ): Promise<any> {
    const bearerToken = process.env.TWITTER_BEARER_TOKEN;

    if (!bearerToken) {
      throw new Error('Twitter bearer token not configured');
    }

    const config: AxiosRequestConfig = {
      method,
      url: endpoint,
      headers: {
        Authorization: `Bearer ${bearerToken}`,
      },
      data,
      params,
    };

    try {
      const response = await this.client.request(config);
      return response.data;
    } catch (error) {
      throw error;
    }
  }

  /**
   * Post a tweet on behalf of a user using Twitter API v2 POST /tweets endpoint
   * Supports location data by appending it to the tweet text
   *
   * @param accessToken User's OAuth access token
   * @param text The tweet text content
   * @param mediaIds Optional array of media IDs to attach to the tweet
   * @param locationAddress Optional location address to append to the tweet
   * @param userId User's Firebase ID (needed for token refresh)
   * @returns The API response with tweet data
   */
  async postTweet(
    accessToken: string,
    text: string,
    mediaIds?: string[],
    locationAddress?: string | null,
    userId?: string,
  ): Promise<any> {
    let tweetText = text;
    const endpoint = '/tweets';

    // Add location to the tweet text if provided
    if (locationAddress) {
      const locationText = `\n\n📍 ${locationAddress}`;
      // Check if adding location will exceed Twitter's character limit
      if (text.length + locationText.length <= 280) {
        tweetText = text + locationText;
        this.logger.log(
          `Added location text to tweet on new line: ${locationText}`,
        );
      } else {
        this.logger.warn(
          `Location text would exceed character limit, skipping`,
        );
      }
    }

    const data: any = { text: tweetText };

    // Add media if present
    if (mediaIds && mediaIds.length > 0) {
      data.media = { media_ids: mediaIds };
    }

    return this.makeAuthenticatedRequest(
      accessToken,
      'post',
      endpoint,
      data,
      undefined,
      undefined,
      userId,
    );
  }

  /**
   * Upload media to Twitter's media endpoint with token refresh support
   *
   * @param accessToken User's OAuth access token
   * @param mediaData Base64 encoded media data
   * @param mediaType MIME type of the media
   * @param userId User's Firebase ID (needed for token refresh)
   * @returns Media ID string to use when posting tweets
   */
  async uploadMedia(
    accessToken: string,
    mediaData: string,
    mediaType: string,
    userId?: string,
  ): Promise<string> {
    try {
      this.logger.log(`Uploading media of type ${mediaType}`);

      // Use app-level credentials for OAuth 1.0a
      const consumerKey = process.env.TWITTER_API_KEY;
      const consumerSecret = process.env.TWITTER_API_SECRET;
      const accessTokenKey = process.env.TWITTER_ACCESS_TOKEN;
      const accessTokenSecret = process.env.TWITTER_ACCESS_SECRET;

      if (
        !consumerKey ||
        !consumerSecret ||
        !accessTokenKey ||
        !accessTokenSecret
      ) {
        throw new Error(
          'Twitter API credentials not configured for OAuth 1.0a',
        );
      }

      // Create OAuth 1.0a instance using require to avoid import issues
      const OAuth = require('oauth-1.0a');
      const oauth = new OAuth({
        consumer: { key: consumerKey, secret: consumerSecret },
        signature_method: 'HMAC-SHA1',
        hash_function(baseString, key) {
          return crypto
            .createHmac('sha1', key)
            .update(baseString)
            .digest('base64');
        },
      });

      // Request data for OAuth signing
      const requestData = {
        url: this.mediaUploadUrl,
        method: 'POST',
      };

      // Generate OAuth parameters
      const token = { key: accessTokenKey, secret: accessTokenSecret };
      const oauthHeader = oauth.toHeader(oauth.authorize(requestData, token));

      // Create form data
      const formData = new FormData();
      formData.append('media_data', mediaData);

      try {
        // Make the request with OAuth 1.0a authentication
        const response = await axios.post(this.mediaUploadUrl, formData, {
          headers: {
            ...oauthHeader,
            ...formData.getHeaders(),
          },
        });

        if (!response.data || !response.data.media_id_string) {
          throw new Error('Failed to get media ID from Twitter response');
        }

        this.logger.log(
          `Successfully uploaded media ID: ${response.data.media_id_string}`,
        );
        return response.data.media_id_string;
      } catch (error) {
        // If it's a token expiration, try to refresh and retry
        if (error.response?.status === 401 && userId) {
          this.logger.log(
            'Media upload failed with 401, attempting to refresh token',
          );

          try {
            const newAccessToken =
              await this.xAuthService.refreshTokens(userId);
            if (newAccessToken) {
              this.logger.log('Token refreshed, retrying media upload');
              // Retry the upload with the new token but don't pass userId to avoid loops
              return this.uploadMedia(newAccessToken, mediaData, mediaType);
            }
          } catch (refreshError) {
            this.logger.error('Token refresh failed:', refreshError.message);
          }
        }
        throw error;
      }
    } catch (error) {
      this.logger.error(`Failed to upload media: ${error.message}`);
      if (error.response) {
        this.logger.error(
          `Error details: ${JSON.stringify(error.response.data)}`,
        );
      }
      throw error;
    }
  }

  /**
   * Get tweet metrics for a specific tweet using Twitter API v2 GET /tweets/:id endpoint
   *
   * @param tweetId The ID of the tweet
   * @param accessToken User's OAuth access token (optional, will use app token if not provided)
   * @param userId User's Firebase ID (needed for token refresh)
   * @returns Engagement metrics data including public_metrics, non_public_metrics, and organic_metrics
   */
  async getTweetMetrics(
    tweetId: string,
    accessToken?: string,
    userId?: string,
  ): Promise<any> {
    try {
      const endpoint = `/tweets/${tweetId}`;
      // Define all necessary metrics fields
      const params = {
        'tweet.fields': 'public_metrics,non_public_metrics,organic_metrics',
        expansions: 'author_id',
        'user.fields': 'id,username',
      };

      console.log(
        `Fetching metrics for tweet ${tweetId} with token: ${accessToken?.substring(0, 10)}...`,
      );

      // Must use user token for non-public metrics
      if (!accessToken) {
        console.warn(
          'No access token provided for metrics, using app token which may have limited access',
        );
        return this.makeAppAuthenticatedRequest('get', endpoint, null, params);
      }

      return this.makeAuthenticatedRequest(
        accessToken,
        'get',
        endpoint,
        undefined,
        params,
        undefined,
        userId,
      );
    } catch (error) {
      console.error(`Error fetching tweet metrics for ${tweetId}:`, error);
      if (error.response) {
        console.error('Error response:', error.response.data);
        console.error('Error status:', error.response.status);
      }
      throw error;
    }
  }

  /**
   * Verify the user's credentials and get basic account info using Twitter API v2 GET /users/me endpoint
   *
   * @param accessToken User's OAuth access token
   * @param userId User's Firebase ID (needed for token refresh)
   * @returns User account data if valid, throws error otherwise
   */
  async verifyCredentials(accessToken: string, userId?: string): Promise<any> {
    const endpoint = '/users/me';
    const params = {
      'user.fields': 'id,name,username',
    };

    return this.makeAuthenticatedRequest(
      accessToken,
      'get',
      endpoint,
      undefined,
      params,
      undefined,
      userId,
    );
  }
}
