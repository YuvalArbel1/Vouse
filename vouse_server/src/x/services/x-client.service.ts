// src/x/services/x-client.service.ts
import { Injectable, Logger } from '@nestjs/common';
import axios, { AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios';
import * as dotenv from 'dotenv';
import * as FormData from 'form-data';

dotenv.config();

// Adding a rate limit tracker
interface RateLimitInfo {
  endpoint: string;
  remaining: number;
  reset: number; // Timestamp when the rate limit resets
  lastRequest: number; // Timestamp of the last request
}

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
  // Twitter media upload URL (still v1.1)
  private readonly mediaUploadUrl =
    'https://upload.twitter.com/1.1/media/upload.json';

  // Track rate limits for different endpoints
  private rateLimits: Map<string, RateLimitInfo> = new Map();

  constructor() {
    // Create a pre-configured axios instance for API calls
    this.client = axios.create({
      baseURL: this.apiBaseUrl,
      timeout: 30000, // 30 seconds timeout (increased for media uploads)
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Add response interceptor for logging and rate limit tracking
    this.client.interceptors.response.use(
      (response) => {
        // Track rate limit info from response headers
        this.updateRateLimitInfo(response);
        return response;
      },
      (error) => {
        // Log the error but don't expose sensitive info
        if (error.response) {
          // Track rate limit info even from error responses
          this.updateRateLimitInfo(error.response);

          this.logger.error(
            `Twitter API error: ${error.response.status} - ${JSON.stringify(error.response.data)}`,
          );

          // If rate limited, provide clearer error
          if (error.response.status === 429) {
            const resetTime = error.response.headers['x-rate-limit-reset'];
            const waitTime = resetTime
              ? new Date(parseInt(resetTime) * 1000)
              : 'unknown time';
            this.logger.warn(
              `Rate limited by Twitter API. Reset at ${waitTime}`,
            );
            error.isRateLimit = true;
            error.resetTime = resetTime;
          }
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
   * Update rate limit information from response headers
   */
  private updateRateLimitInfo(response: AxiosResponse): void {
    try {
      const endpoint = response.config.url || 'unknown';
      const remaining = parseInt(
        response.headers['x-rate-limit-remaining'] || '-1',
      );
      const reset =
        parseInt(response.headers['x-rate-limit-reset'] || '0') * 1000; // Convert to ms

      if (remaining >= 0) {
        this.rateLimits.set(endpoint, {
          endpoint,
          remaining,
          reset,
          lastRequest: Date.now(),
        });

        // Log rate limit info if we're getting low
        if (remaining < 10) {
          this.logger.warn(
            `Twitter API rate limit for ${endpoint}: ${remaining} requests remaining. Resets at ${new Date(reset).toLocaleString()}`,
          );
        }
      }
    } catch (error) {
      // Just log and continue - rate limit tracking is best effort
      this.logger.debug(`Error tracking rate limits: ${error.message}`);
    }
  }

  /**
   * Check if an endpoint is rate limited and we should wait
   * @returns Number of milliseconds to wait, or 0 if no wait needed
   */
  private checkRateLimit(endpoint: string): number {
    const info = this.rateLimits.get(endpoint);

    if (!info) return 0; // No info, proceed with request

    // If we have no requests remaining and we're not past the reset time
    if (info.remaining <= 0 && info.reset > Date.now()) {
      return info.reset - Date.now() + 1000; // Add 1 second buffer
    }

    return 0; // No wait needed
  }

  /**
   * Execute a request with rate limit handling and retries
   */
  private async executeWithRateLimitHandling<T>(
    fn: () => Promise<T>,
    endpoint: string,
    maxRetries = 2,
  ): Promise<T> {
    let retries = 0;

    while (true) {
      try {
        // Check if we need to wait for rate limit
        const waitTime = this.checkRateLimit(endpoint);
        if (waitTime > 0) {
          this.logger.log(
            `Waiting ${waitTime}ms for Twitter rate limit to reset`,
          );
          await new Promise((resolve) => setTimeout(resolve, waitTime));
        }

        // Execute the request
        return await fn();
      } catch (error) {
        // If rate limited and we have retries left
        if (error.isRateLimit && retries < maxRetries) {
          retries++;
          const waitTime = error.resetTime
            ? parseInt(error.resetTime) * 1000 - Date.now() + 2000 // Add 2 second buffer
            : 60000 * (retries + 1); // Exponential backoff

          this.logger.log(
            `Rate limited. Retrying in ${waitTime / 1000} seconds (retry ${retries}/${maxRetries})`,
          );
          await new Promise((resolve) => setTimeout(resolve, waitTime));
          continue;
        }

        // Either not a rate limit error or we're out of retries
        throw error;
      }
    }
  }

  /**
   * Make an authenticated request to Twitter's API using a user's access token
   *
   * @param accessToken User's OAuth access token
   * @param method HTTP method
   * @param endpoint API endpoint (without base URL)
   * @param data Request body data
   * @param params Query parameters
   * @returns API response data
   */
  async makeAuthenticatedRequest(
    accessToken: string,
    method: string,
    endpoint: string,
    data?: any,
    params?: any,
    baseUrl?: string,
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

    return this.executeWithRateLimitHandling(async () => {
      const response = await axios.request(config);
      return response.data;
    }, endpoint);
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

    return this.executeWithRateLimitHandling(async () => {
      const response = await this.client.request(config);
      return response.data;
    }, endpoint);
  }

  /**
   * Post a tweet on behalf of a user using Twitter API v2 POST /tweets endpoint
   *
   * Reference: https://developer.twitter.com/en/docs/twitter-api/tweets/manage-tweets/api-reference/post-tweets
   *
   * @param accessToken User's OAuth access token
   * @param text The tweet text content
   * @param mediaIds Optional array of media IDs to attach to the tweet
   * @returns The API response with tweet data
   */
  async postTweet(
    accessToken: string,
    text: string,
    mediaIds?: string[],
  ): Promise<any> {
    const endpoint = '/tweets';
    const data: any = { text };

    if (mediaIds && mediaIds.length > 0) {
      data.media = { media_ids: mediaIds };
    }

    return this.makeAuthenticatedRequest(accessToken, 'post', endpoint, data);
  }

  /**
   * Upload media to Twitter's media endpoint
   * Note: This still uses the v1.1 API as the v2 API does not have a direct media upload endpoint
   *
   * Reference: https://developer.twitter.com/en/docs/twitter-api/v1/media/upload-media/api-reference/post-media-upload
   *
   * @param accessToken User's OAuth access token
   * @param mediaData Base64 encoded media data
   * @param mediaType MIME type of the media
   * @returns Media ID string to use when posting tweets
   */
  async uploadMedia(
    accessToken: string,
    mediaData: string,
    mediaType: string,
  ): Promise<string> {
    try {
      this.logger.log(`Uploading media of type ${mediaType}`);

      // Create form data
      const formData = new FormData();
      formData.append('media_data', mediaData);

      // Use the rate limit handling function for media upload
      const response = await this.executeWithRateLimitHandling(async () => {
        // Use axios directly for the multipart/form-data request
        return axios.post(this.mediaUploadUrl, formData, {
          headers: {
            Authorization: `Bearer ${accessToken}`,
            ...formData.getHeaders(),
          },
        });
      }, 'media_upload');

      if (!response.data || !response.data.media_id_string) {
        throw new Error('Failed to get media ID from Twitter response');
      }

      this.logger.log(
        `Successfully uploaded media ID: ${response.data.media_id_string}`,
      );
      return response.data.media_id_string;
    } catch (error) {
      this.logger.error(`Failed to upload media: ${error.message}`);
      throw error;
    }
  }

  /**
   * Get tweet metrics for a specific tweet using Twitter API v2 GET /tweets/:id endpoint
   *
   * Reference: https://developer.twitter.com/en/docs/twitter-api/tweets/lookup/api-reference/get-tweets-id
   *
   * @param tweetId The ID of the tweet
   * @returns Engagement metrics data including public_metrics, non_public_metrics, and organic_metrics
   */
  async getTweetMetrics(tweetId: string): Promise<any> {
    const endpoint = `/tweets/${tweetId}`;
    const params = {
      'tweet.fields': 'public_metrics,non_public_metrics,organic_metrics',
    };

    return this.makeAppAuthenticatedRequest('get', endpoint, null, params);
  }

  /**
   * Verify the user's credentials and get basic account info using Twitter API v2 GET /users/me endpoint
   *
   * Reference: https://developer.twitter.com/en/docs/twitter-api/users/lookup/api-reference/get-users-me
   *
   * @param accessToken User's OAuth access token
   * @returns User account data if valid, throws error otherwise
   */
  async verifyCredentials(accessToken: string): Promise<any> {
    const endpoint = '/users/me';
    const params = {
      'user.fields': 'id,name,username',
    };

    return this.makeAuthenticatedRequest(
      accessToken,
      'get',
      endpoint,
      null,
      params,
    );
  }
}
