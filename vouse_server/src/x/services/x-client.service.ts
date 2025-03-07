// src/x/services/x-client.service.ts
import { Injectable, Logger } from '@nestjs/common';
import axios, { AxiosInstance, AxiosRequestConfig } from 'axios';
import * as dotenv from 'dotenv';
import * as FormData from 'form-data';

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
  // Twitter media upload URL (still v1.1)
  private readonly mediaUploadUrl =
    'https://upload.twitter.com/1.1/media/upload.json';

  constructor() {
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

    try {
      const response = await axios.request(config);
      return response.data;
    } catch (error) {
      // If the error is due to an expired token, we should handle it at a higher level
      if (error.response?.status === 401) {
        this.logger.warn('Twitter access token expired or invalid');
        throw new Error('TWITTER_TOKEN_EXPIRED');
      }
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

      // Use axios directly for the multipart/form-data request
      const response = await axios.post(this.mediaUploadUrl, formData, {
        headers: {
          Authorization: `Bearer ${accessToken}`,
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
