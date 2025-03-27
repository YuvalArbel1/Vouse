// src/common/common.module.ts
import { Module } from '@nestjs/common';
import { TokenEncryption } from './utils/token_encryption.util';
import { HealthController } from './controllers/health.controller';

@Module({
  controllers: [HealthController],
  providers: [TokenEncryption],
  exports: [TokenEncryption],
})
export class CommonModule {}
