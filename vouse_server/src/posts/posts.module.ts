// src/posts/posts.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BullModule } from '@nestjs/bull';

import { Post } from './entities/post.entity';
import { Engagement } from './entities/engagement.entity';
import { PostService } from './services/post.service';
import { EngagementService } from './services/engagement.service';
import { PostController } from './controllers/post.controller';
import { EngagementController } from './controllers/engagement.controller';
import { QueueHealthController } from './controllers/queue-health.controller';
import { PostPublishProcessor } from './processors/post-publish.processor';

import { AuthModule } from '../auth/auth.module';
import { UsersModule } from '../users/users.module';
import { XModule } from '../x/x.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  /* This module provides services for its domain */
  imports: [
    TypeOrmModule.forFeature([Post, Engagement]),
    BullModule.registerQueue({
      name: 'post-publish',
    }),
    AuthModule,
    UsersModule,
    XModule,
    NotificationsModule,
  ],
  providers: [
    PostService,
    EngagementService,
    PostPublishProcessor,
  ],
  controllers: [PostController, EngagementController, QueueHealthController],
  exports: [PostService, EngagementService],
})
export class PostsModule {}
