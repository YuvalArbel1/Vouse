// src/auth/auth.module.ts
import { Module } from '@nestjs/common';
// import { FirebaseAdminService } from './services/firebase-admin.service';
import { FirebaseAdminService } from './services/firebase-admin';
import { FirebaseAuthGuard } from './guards/firebase-auth';

@Module({
  /* This module provides services for its domain */
  providers: [FirebaseAdminService, FirebaseAuthGuard],
  exports: [FirebaseAdminService, FirebaseAuthGuard],
})
export class AuthModule {}
