// src/posts/posts.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BullModule } from '@nestjs/bull';

import { Post } from './entities/post.entity';
import { PostEngagement } from './entities/engagement.entity';
import { PostService } from './services/post.service';
import { EngagementService } from './services/engagement.service';
import { PostController } from './controllers/post.controller';
import { EngagementController } from './controllers/engagement.controller';
import { PostPublishProcessor } from './processors/post-publish.processor';

import { AuthModule } from '../auth/auth.module';
import { UsersModule } from '../users/users.module';
import { XModule } from '../x/x.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Post, PostEngagement]),
    BullModule.registerQueue({
      name: 'post-publish',
    }),
    // Removed metrics-collector queue
    AuthModule,
    UsersModule,
    XModule,
  ],
  providers: [
    PostService,
    EngagementService,
    PostPublishProcessor,
    // Removed MetricsCollectorProcessor
  ],
  controllers: [PostController, EngagementController],
  exports: [PostService, EngagementService],
})
export class PostsModule {}
