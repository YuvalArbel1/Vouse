// src/config/redis.config.ts - Updated version
import * as dotenv from 'dotenv';

dotenv.config();

export const redisConfig = {
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  password: process.env.REDIS_PASSWORD || undefined,
  tls: process.env.REDIS_TLS_ENABLED === 'true' ? { rejectUnauthorized: false } : undefined,
  db: parseInt(process.env.REDIS_DB || '0'),
};