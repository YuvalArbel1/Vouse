// src/main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe, Logger, INestApplication } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import * as dotenv from 'dotenv';
import helmet from 'helmet';

/**
 * Bootstrap the NestJS application
 * Sets up middleware, pipes, and starts the HTTP server
 *
 * @returns A promise that resolves when the application is successfully started
 */
async function bootstrap(): Promise<void> {
  // Ensure environment variables are loaded
  dotenv.config();

  // Create a logger instance
  const logger = new Logger('Bootstrap');

  try {
    // Create NestJS application instance
    const app = await NestFactory.create(AppModule, {
      logger: ['error', 'warn', 'log', 'debug'].includes(
        process.env.LOG_LEVEL || 'info',
      )
        ? ['error', 'warn', 'log', 'debug', 'verbose']
        : ['error', 'warn', 'log'],
    });

    // Configure the application
    configureApp(app);

    // Get the port from environment variables or use 3000 as default
    const port = parseInt(process.env.PORT || '3000', 10);

    // Start the application - listen on all interfaces
    await app.listen(port, '0.0.0.0');

    logger.log(`Application is running on: http://0.0.0.0:${port}`);
    logger.log(`Environment: ${process.env.NODE_ENV || 'development'}`);

    // Handle graceful shutdown
    setupGracefulShutdown(app);
  } catch (error) {
    const typedError = error as Error;
    logger.error(
      `Failed to start application: ${typedError.message}`,
      typedError.stack,
    );
    process.exit(1);
  }
}

/**
 * Configure the NestJS application with middleware and pipes
 *
 * @param app - The NestJS application instance
 */
function configureSwagger(app: INestApplication): void {
  const config = new DocumentBuilder()
    .setTitle('Vouse API')
    .setDescription(
      'API documentation for the Vouse social media management platform',
    )
    .setVersion('1.0')
    // Add more configuration like tags, auth, etc. if needed
    .build();
  const document = SwaggerModule.createDocument(app as any, config);
  SwaggerModule.setup('api-docs', app as any, document); // Cast app to any
}

/**
 * Configure the NestJS application with middleware and pipes
 *
 * @param app - The NestJS application instance
 */
function configureApp(app: INestApplication): void {
  // Security headers
  app.use(helmet());

  // Enable CORS for frontend integration
  app.enableCors({
    origin: process.env.CORS_ORIGIN || '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
  });

  // Use global validation pipe to validate DTOs
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // Strip properties not defined in the DTO
      transform: true, // Transform payloads to DTO instances
      forbidNonWhitelisted: true, // Throw errors on unknown properties
      transformOptions: {
        enableImplicitConversion: false, // Explicit type conversion only
      },
    }),
  );

  // Setup Swagger
  configureSwagger(app);
}

/**
 * Set up graceful shutdown handlers
 *
 * @param app - The NestJS application instance
 */
function setupGracefulShutdown(app: INestApplication): void {
  const logger = new Logger('Shutdown');

  // Handle termination signals
  process.on('SIGTERM', async () => {
    logger.log('SIGTERM received, shutting down gracefully');
    await app.close();
    logger.log('Application closed');
    process.exit(0);
  });

  process.on('SIGINT', async () => {
    logger.log('SIGINT received, shutting down gracefully');
    await app.close();
    logger.log('Application closed');
    process.exit(0);
  });
}

// Start the application
bootstrap().catch((error) => {
  console.error('Unhandled bootstrap error:', error);
  process.exit(1);
});
