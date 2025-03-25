// src/common/middleware/request-logger.middleware.ts
import { Injectable, NestMiddleware, Logger } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';

@Injectable()
export class RequestLoggerMiddleware implements NestMiddleware {
  private readonly logger = new Logger('HTTP');

  use(req: Request, res: Response, next: NextFunction) {
    const { method, originalUrl, ip, headers } = req;
    const userAgent = headers['user-agent'] || 'unknown';

    // Log when request starts
    this.logger.log(
      `[REQUEST] ${method} ${originalUrl} - IP: ${ip} - User-Agent: ${userAgent}`,
    );

    // Log request body if present
    if (Object.keys(req.body || {}).length > 0) {
      this.logger.debug(`Request body: ${JSON.stringify(req.body)}`);
    }

    // Track response
    const startTime = Date.now();

    // Log when response is sent
    res.on('finish', () => {
      const duration = Date.now() - startTime;
      const statusCode = res.statusCode;

      this.logger.log(
        `[RESPONSE] ${method} ${originalUrl} - Status: ${statusCode} - Duration: ${duration}ms`,
      );
    });

    next();
  }
}
