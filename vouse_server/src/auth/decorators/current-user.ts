// src/auth/decorators/current-user.decorator.ts
import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { Request } from 'express';

/**
 * Custom decorator to extract the current authenticated user from the request
 *
 * This decorator relies on the FirebaseAuthGuard to set the user property on the request
 *
 * @example
 * ```typescript
 * @Get('profile')
 * @UseGuards(FirebaseAuthGuard)
 * getProfile(@CurrentUser() user: DecodedIdToken) {
 *   return { uid: user.uid, email: user.email };
 * }
 * ```
 */
export const CurrentUser = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest<Request>();
    return request.user;
  },
);
