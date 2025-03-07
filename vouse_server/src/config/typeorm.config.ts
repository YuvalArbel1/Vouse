// src/config/typeorm.config.ts
import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import * as dotenv from 'dotenv';

dotenv.config();

// Hardcoded connection string for troubleshooting
const connectionString =
  'postgres://neondb_owner:npg_A7F3RgEXxDYT@ep-super-queen-a22rxr8q-pooler.eu-central-1.aws.neon.tech:5432/vouse';

/**
 * TypeORM configuration for connecting to Neon PostgreSQL
 */
export const typeOrmConfig: TypeOrmModuleOptions = {
  type: 'postgres',
  url: connectionString,
  entities: [__dirname + '/../**/*.entity{.ts,.js}'],
  synchronize: true,
  ssl: {
    rejectUnauthorized: false,
  },
  logging: true,
  extra: {
    connectionTimeoutMillis: 15000,
  },
};
