// src/common/middleware/request-logger.middleware.ts
import { Injectable, NestMiddleware, Logger } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';

/**
 * Middleware for logging HTTP requests and responses
 * Tracks request details, timing, and response status
 */
@Injectable()
export class RequestLoggerMiddleware implements NestMiddleware {
  private readonly logger = new Logger('HTTP');

  /**
   * Process the HTTP request and log details
   *
   * @param req - The Express request object
   * @param res - The Express response object
   * @param next - The next middleware function
   */
  use(req: Request, res: Response, next: NextFunction): void {
    const { method, originalUrl, ip, headers } = req;
    const userAgent = headers['user-agent'] || 'unknown';

    // Log when request starts
    this.logger.log(
      `[REQUEST] ${method} ${originalUrl} - IP: ${ip} - User-Agent: ${userAgent}`,
    );

    // Log request body if present and not a file upload
    if (
      Object.keys(req.body || {}).length > 0 &&
      !headers['content-type']?.includes('multipart/form-data')
    ) {
      // Sanitize sensitive data before logging
      const sanitizedBody = this.sanitizeRequestBody(req.body);
      this.logger.debug(`Request body: ${JSON.stringify(sanitizedBody)}`);
    }

    // Track response
    const startTime = Date.now();

    // Log when response is sent
    res.on('finish', () => {
      const duration = Date.now() - startTime;
      const statusCode = res.statusCode;

      const logMethod = statusCode >= 400 ? 'warn' : 'log';

      this.logger[logMethod](
        `[RESPONSE] ${method} ${originalUrl} - Status: ${statusCode} - Duration: ${duration}ms`,
      );
    });

    next();
  }

  /**
   * Sanitize the request body to remove sensitive information before logging
   *
   * @param body - The request body object
   * @returns A sanitized copy of the request body
   */
  private sanitizeRequestBody(body: Record<string, any>): Record<string, any> {
    // Create a deep copy to avoid modifying the original
    const sanitized = JSON.parse(JSON.stringify(body));

    // List of fields to sanitize
    const sensitiveFields = [
      'password',
      'token',
      'secret',
      'authorization',
      'apiKey',
      'api_key',
      'accessToken',
      'refreshToken',
      'credit_card',
    ];

    // Recursively sanitize objects
    const sanitizeObject = (obj: Record<string, any>): void => {
      Object.keys(obj).forEach((key) => {
        // Check if this is a sensitive field
        if (
          sensitiveFields.some((field) => key.toLowerCase().includes(field))
        ) {
          obj[key] = '[REDACTED]';
        } else if (typeof obj[key] === 'object' && obj[key] !== null) {
          // Recursively sanitize nested objects
          sanitizeObject(obj[key]);
        }
      });
    };

    sanitizeObject(sanitized);
    return sanitized;
  }
}
