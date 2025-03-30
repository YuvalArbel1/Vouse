// src/common/controllers/health.controller.ts
import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  /**
   * Health check endpoint to verify server is running
   * This route is public and doesn't require authentication
   */
  @Get()
  @ApiOperation({ summary: 'Check server health status' })
  @ApiResponse({ status: 200, description: 'Server is running.' })
  healthCheck() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      service: 'vouse-server',
    };
  }
}
