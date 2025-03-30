// src/app.module.ts
import { TypeOrmModule } from '@nestjs/typeorm';
import { BullModule } from '@nestjs/bull';
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { XModule } from './x/x.module';
import { PostsModule } from './posts/posts.module';
import { typeOrmConfig } from './config/typeorm.config';
import { redisConfig } from './config/redis.config';
import { NotificationsModule } from './notifications/notifications.module';
import { CommonModule } from './common/common.module';
import { RequestLoggerMiddleware } from './common/middleware/request-logger.middleware';
import { Module, NestModule, MiddlewareConsumer } from '@nestjs/common';
import { AppController } from './app.controller';

@Module({
  imports: [
    // Configure TypeORM
    TypeOrmModule.forRoot(typeOrmConfig),

    // Configure Bull with Redis
    BullModule.forRoot({
      redis: {
        host: redisConfig.host,
        port: redisConfig.port,
        password: redisConfig.password,
        tls: redisConfig.tls,
        enableReadyCheck: false,
        maxRetriesPerRequest: null,
        disconnectTimeout: 5000,
        retryStrategy: (times) => {
          return Math.min(times * 100, 3000);
        },
      },
    }),

    // Core modules
    CommonModule, // Common utilities and services

    // Feature modules
    AuthModule, // Firebase authentication
    UsersModule, // User management
    XModule, // Twitter API v2 integration
    PostsModule, // Post scheduling and metrics
    NotificationsModule, // Notification
  ],
  controllers: [AppController], // Register the AppController
  providers: [],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(RequestLoggerMiddleware).forRoutes('*');
  }
}
