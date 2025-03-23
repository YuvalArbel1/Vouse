// src/users/users.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './entities/user.entity';
import { UserService } from './services/user.service';
import { UserController } from './controllers/user.controller';
import { AuthModule } from '../auth/auth.module';

@Module({
  /* This module provides services for its domain */
  imports: [
    TypeOrmModule.forFeature([User]),
    AuthModule, // Import the Auth module
  ],
  providers: [UserService],
  controllers: [UserController],
  exports: [UserService],
})
export class UsersModule {}
