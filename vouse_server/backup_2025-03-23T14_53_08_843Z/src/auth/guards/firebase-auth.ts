// src/auth/guards/firebase-auth.ts
import {
  CanActivate,
  ExecutionContext,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { Request } from 'express';
import { DecodedIdToken } from 'firebase-admin/auth';
import { FirebaseAdminService } from '../services/firebase-admin';

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  private readonly logger = new Logger(FirebaseAuthGuard.name);

  constructor(private readonly firebaseAdminService: FirebaseAdminService) {}

  /**
   * Check if the request can be processed based on the Firebase ID token
   *
   * @param context The execution context
   * @returns A boolean indicating if the request can proceed
   * @throws UnauthorizedException if the token is missing or invalid
   */
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const token = this.extractTokenFromHeader(request);

    if (!token) {
      this.logger.warn('No authorization token provided');
      throw new UnauthorizedException('No authorization token provided');
    }

    try {
      // Verify the Firebase ID token and attach the user to the request for later use
      const decodedToken: DecodedIdToken =
        await this.firebaseAdminService.verifyIdToken(token);

      // Validate token claims if needed
      this.validateTokenClaims(decodedToken);

      // Assign the validated user to the request
      request.user = decodedToken;

      return true;
    } catch (error) {
      const typedError = error as Error;
      this.logger.error(
        `Authentication error: ${typedError.message}`,
        typedError.stack,
      );
      throw new UnauthorizedException('Invalid token');
    }
  }

  /**
   * Validate required token claims
   *
   * @param decodedToken The decoded Firebase ID token
   * @throws UnauthorizedException if the token claims are invalid
   */
  private validateTokenClaims(decodedToken: DecodedIdToken): void {
    // Check for token expiration
    const currentTime = Math.floor(Date.now() / 1000);
    if (!decodedToken.exp || decodedToken.exp < currentTime) {
      throw new UnauthorizedException('Token has expired');
    }

    // Ensure the token has a user ID
    if (!decodedToken.uid) {
      throw new UnauthorizedException('Token missing required claims');
    }
  }

  /**
   * Extract the token from the Authorization header
   *
   * @param request The HTTP request
   * @returns The token or undefined if not found
   */
  private extractTokenFromHeader(request: Request): string | undefined {
    const authHeader = request.headers.authorization;
    if (!authHeader) {
      return undefined;
    }

    const [type, token] = authHeader.split(' ');
    return type === 'Bearer' ? token : undefined;
  }
}
