import { Controller, Get, Head, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger'; // Import decorator to hide from Swagger

@ApiExcludeController()
@Controller()
export class AppController {
  @Get()
  @HttpCode(HttpStatus.OK)
  getHealthCheck(): { status: string } {
    // Simple response for GET /
    return { status: 'ok' };
  }

  @Head()
  @HttpCode(HttpStatus.OK) // Explicitly set 200 OK status for HEAD requests
  headHealthCheck(): void {
    // No body needed for HEAD requests
  }
}
