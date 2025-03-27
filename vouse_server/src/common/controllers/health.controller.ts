// src/common/controllers/health.controller.ts
import { Controller, Get } from '@nestjs/common';

@Controller('health')
export class HealthController {
  /**
   * Health check endpoint to verify server is running
   * This route is public and doesn't require authentication
   */
  @Get()
  healthCheck() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      service: 'vouse-server',
    };
  }
}
