// src/common/common.module.ts
import { Module } from '@nestjs/common';
import { TokenEncryption } from './utils/token_encryption.util';

@Module({
  providers: [TokenEncryption],
  exports: [TokenEncryption],
})
export class CommonModule {}
