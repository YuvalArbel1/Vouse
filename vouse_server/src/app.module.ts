// src/app.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { typeOrmConfig } from './config/typeorm.config';

/**
 * Main application module that imports all feature modules
 */
@Module({
  imports: [
    // Configure TypeORM with our Neon PostgreSQL settings
    TypeOrmModule.forRoot(typeOrmConfig),

    // Feature modules
    AuthModule,
    UsersModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
