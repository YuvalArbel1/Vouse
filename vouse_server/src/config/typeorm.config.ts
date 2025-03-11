// src/config/typeorm.config.ts
import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import * as dotenv from 'dotenv';
import { User } from '../users/entities/user.entity';
import { Post } from '../posts/entities/post.entity';
import { PostEngagement } from '../posts/entities/engagement.entity';
import { DeviceToken } from '../notifications/entities/device-token.entity';

dotenv.config();

/**
 * TypeORM configuration for connecting to Neon PostgreSQL
 */
export const typeOrmConfig: TypeOrmModuleOptions = {
  type: 'postgres',
  url:
    process.env.DATABASE_URL ||
    'postgres://neondb_owner:npg_A7F3RgEXxDYT@ep-super-queen-a22rxr8q-pooler.eu-central-1.aws.neon.tech:5432/vouse',
  entities: [User, Post, PostEngagement, DeviceToken],
  synchronize: true, // Be careful with this in production!
  dropSchema: false, // Set to true only if you want to completely reset your database
  ssl: {
    rejectUnauthorized: false,
  },
  logging: true,
  extra: {
    connectionTimeoutMillis: 15000,
  },
};
