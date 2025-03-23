// src/x/x.module.ts
import { Module } from '@nestjs/common';
import { XClientService } from './services/x-client.service';
import { XAuthService } from './services/x-auth.service';
import { XAuthController } from './controllers/x-auth.controller';
import { UsersModule } from '../users/users.module';
import { AuthModule } from '../auth/auth.module';
import { CommonModule } from '../common/common.module';

@Module({
  /* This module provides services for its domain */
  imports: [AuthModule, UsersModule, CommonModule],
  providers: [XClientService, XAuthService],
  controllers: [XAuthController],
  exports: [XClientService, XAuthService],
})
export class XModule {}
