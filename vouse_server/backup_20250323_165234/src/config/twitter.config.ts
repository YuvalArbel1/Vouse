// src/config/twitter.config.ts
import * as dotenv from 'dotenv';

dotenv.config();

export const twitterConfig = {
  apiKey: process.env.TWITTER_API_KEY,
  apiSecret: process.env.TWITTER_API_SECRET,
  bearerToken: process.env.TWITTER_BEARER_TOKEN,
  accessToken: process.env.TWITTER_ACCESS_TOKEN,
  accessSecret: process.env.TWITTER_ACCESS_SECRET,
};
