// src/config/typeorm.config.ts
import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import * as dotenv from 'dotenv';
import { User } from '../users/entities/user.entity';
import { Post } from '../posts/entities/post.entity';
import { Engagement } from '../posts/entities/engagement.entity';
import { DeviceToken } from '../notifications/entities/device-token.entity';

dotenv.config();

/**
 * TypeORM configuration for connecting to Neon PostgreSQL
 */
export const typeOrmConfig: TypeOrmModuleOptions = {
  type: 'postgres',
  url:
    process.env.DATABASE_URL ||
    'postgresql://neondb_owner:npg_A7F3RgEXxDYT@ep-super-queen-a22rxr8q-pooler.eu-central-1.aws.neon.tech/neondb?sslmode=require',
  entities: [User, Post, Engagement, DeviceToken],
  synchronize: true, // Enable to automatically create database tables if needed
  dropSchema: false, // Set back to false to preserve data between restarts
  ssl: {
    rejectUnauthorized: false,
  },
  logging: true,
  extra: {
    connectionTimeoutMillis: 15000,
  },
};
