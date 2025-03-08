// src/main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { Logger } from '@nestjs/common';

/**
 * Bootstrap the NestJS application
 */
async function bootstrap() {
  // Create NestJS application instance
  const app = await NestFactory.create(AppModule);

  // Create a logger instance
  const logger = new Logger('Bootstrap');

  // Enable CORS for frontend integration
  app.enableCors();

  // Use global validation pipe to validate DTOs
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // Strip properties not defined in the DTO
      transform: true, // Transform payloads to DTO instances
      forbidNonWhitelisted: true, // Throw errors on unknown properties
    }),
  );

  // Get the port from environment variables or use 3000 as default
  const port = process.env.PORT || 3000;

  // Start the application - UPDATED to listen on all interfaces
  await app.listen(port, '0.0.0.0');

  logger.log(`Application is running on: http://0.0.0.0:${port}`);
}

// Use void operator to explicitly mark the floating promise as intentional
void bootstrap();
