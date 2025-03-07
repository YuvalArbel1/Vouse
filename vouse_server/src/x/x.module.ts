// src/x/x.module.ts
import { Module } from '@nestjs/common';
import { XClientService } from './services/x-client.service';
import { XAuthService } from './services/x-auth.service';
import { XAuthController } from './controllers/x-auth.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from '../users/users.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [AuthModule, UsersModule],
  providers: [XClientService, XAuthService],
  controllers: [XAuthController],
  exports: [XClientService, XAuthService],
})
export class XModule {}
