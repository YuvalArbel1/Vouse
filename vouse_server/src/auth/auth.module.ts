// src/auth/auth.module.ts
import { Module } from '@nestjs/common';
import { FirebaseAdminService } from './services/firebase-admin.service';
import { FirebaseAuthGuard } from './guards/firebase-auth.guard';

@Module({
  providers: [FirebaseAdminService, FirebaseAuthGuard],
  exports: [FirebaseAdminService, FirebaseAuthGuard],
})
export class AuthModule {}
