// src/app.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from './users/users.module';
import { typeOrmConfig } from './config/typeorm.config';

/**
 * Main application module that imports all feature modules
 *
 * Currently includes:
 * - TypeORM configuration
 * - Users module
 */
@Module({
  imports: [
    // Configure TypeORM with our Neon PostgreSQL settings
    TypeOrmModule.forRoot(typeOrmConfig),

    // Feature modules
    UsersModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
