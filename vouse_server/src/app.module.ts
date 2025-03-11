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
import { RequestLoggerMiddleware } from './httpRequestMiddleware';
import { Module, NestModule, MiddlewareConsumer } from '@nestjs/common';

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
        db: redisConfig.db,
      },
    }),

    // Feature modules
    AuthModule, // Firebase authentication
    UsersModule, // User management
    XModule, // Twitter API v2 integration
    PostsModule, // Post scheduling and metrics
    NotificationsModule, // Notification
  ],
  controllers: [],
  providers: [],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(RequestLoggerMiddleware).forRoutes('*');
  }
}
