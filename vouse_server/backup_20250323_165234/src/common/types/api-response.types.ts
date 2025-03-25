// src/common/types/api-response.types.ts

/**
 * Generic API response types for external services
 */

/**
 * Generic API response with data
 */
export interface ApiResponse<T> {
  data: T;
  status: number;
  headers?: Record<string, string>;
  message?: string;
}

/**
 * Twitter API specific response types
 */
export interface TwitterMetrics {
  impression_count?: number;
  like_count?: number;
  retweet_count?: number;
  reply_count?: number;
  quote_count?: number;
}

export interface TwitterMediaResponse {
  media_id_string: string;
  media_key?: string;
  size?: number;
  expires_after_secs?: number;
  width?: number;
  height?: number;
}

export interface TwitterUser {
  id: string;
  name: string;
  username: string;
  profile_image_url?: string;
  verified?: boolean;
}

export interface TwitterTweet {
  id: string;
  text: string;
  created_at: string;
  author_id?: string;
  author?: TwitterUser;
  public_metrics?: TwitterMetrics;
  referenced_tweets?: {
    type: 'replied_to' | 'quoted' | 'retweeted';
    id: string;
  }[];
}

/**
 * Firebase API types
 */
export interface FirebaseUserData {
  uid: string;
  email?: string;
  emailVerified?: boolean;
  displayName?: string;
  photoURL?: string;
  phoneNumber?: string;
  disabled?: boolean;
  metadata?: {
    creationTime?: string;
    lastSignInTime?: string;
  };
  providerData?: {
    providerId: string;
    uid: string;
    displayName?: string;
    email?: string;
    photoURL?: string;
    phoneNumber?: string;
  }[];
}

/**
 * Type guards to check response types
 */
export function isApiResponse<T>(obj: unknown): obj is ApiResponse<T> {
  return (
    obj !== null &&
    typeof obj === 'object' &&
    'data' in obj &&
    'status' in obj &&
    typeof (obj as ApiResponse<T>).status === 'number'
  );
}

export function isTwitterTweet(obj: unknown): obj is TwitterTweet {
  return (
    obj !== null &&
    typeof obj === 'object' &&
    'id' in obj &&
    'text' in obj &&
    typeof (obj as TwitterTweet).id === 'string' &&
    typeof (obj as TwitterTweet).text === 'string'
  );
}

export function isTwitterMediaResponse(
  obj: unknown,
): obj is TwitterMediaResponse {
  return (
    obj !== null &&
    typeof obj === 'object' &&
    'media_id_string' in obj &&
    typeof (obj as TwitterMediaResponse).media_id_string === 'string'
  );
}

/**
 * Error handling utility type
 */
export interface ApiError extends Error {
  status?: number;
  response?: {
    data?: unknown;
    status?: number;
    headers?: Record<string, string>;
  };
  request?: unknown;
  code?: string;
  isRateLimit?: boolean;
  resetTime?: Date;
}

/**
 * Type safe utility for handling errors
 */
export function asApiError(error: unknown): ApiError {
  if (error instanceof Error) {
    return error as ApiError;
  }
  return new Error(String(error)) as ApiError;
}
