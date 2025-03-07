// src/auth/guards/firebase-auth.guard.ts
import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
  Logger,
} from '@nestjs/common';
import { Request } from 'express';
import { FirebaseAdminService } from '../services/firebase-admin.service';

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  private readonly logger = new Logger(FirebaseAuthGuard.name);

  constructor(private firebaseAdminService: FirebaseAdminService) {}

  /**
   * Check if the request can be processed based on the Firebase ID token
   *
   * @param context The execution context
   * @returns A boolean indicating if the request can proceed
   */
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const token = this.extractTokenFromHeader(request);

    if (!token) {
      this.logger.warn('No authorization token provided');
      throw new UnauthorizedException('No authorization token provided');
    }

    try {
      // Verify the Firebase ID token
      const decodedToken = await this.firebaseAdminService.verifyIdToken(token);

      // Attach the user to the request for later use
      request.user = decodedToken;

      return true;
    } catch (error) {
      this.logger.error(`Authentication error: ${error.message}`, error.stack);
      throw new UnauthorizedException('Invalid token');
    }
  }

  /**
   * Extract the token from the Authorization header
   *
   * @param request The HTTP request
   * @returns The token or undefined if not found
   */
  private extractTokenFromHeader(request: Request): string | undefined {
    const [type, token] = request.headers.authorization?.split(' ') ?? [];
    return type === 'Bearer' ? token : undefined;
  }
}
