// src/common/common.module.ts
import { Module } from '@nestjs/common';
import { TokenEncryption } from './utils/token_encryption.util';

/**
 * Module for common utilities and services used across the application
 */
@Module({
  providers: [TokenEncryption],
  exports: [TokenEncryption],
})
export class CommonModule {}
