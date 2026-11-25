import {
  CanActivate,
  ExecutionContext,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import * as crypto from 'crypto';

// Fail closed when ADMIN_API_KEY is not configured. Compare keys using
// constant-time comparison to avoid leaking match progress through timing.
@Injectable()
export class AdminGuard implements CanActivate {
  private readonly logger = new Logger('AdminGuard');

  constructor() {
    if (!process.env.ADMIN_API_KEY) {
      this.logger.error(
        'ADMIN_API_KEY is NOT set - all /admin routes will reject requests. ' +
          'Set ADMIN_API_KEY in the backend .env and send it as the x-admin-key header.',
      );
    }
  }

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const provided = request.headers['x-admin-key'];
    const expected = process.env.ADMIN_API_KEY;

    if (
      typeof expected !== 'string' ||
      expected.length === 0 ||
      typeof provided !== 'string' ||
      provided.length === 0
    ) {
      throw new UnauthorizedException('Valid x-admin-key header required');
    }

    const expectedBuffer = Buffer.from(expected, 'utf8');
    const providedBuffer = Buffer.from(provided, 'utf8');

    if (
      expectedBuffer.length !== providedBuffer.length ||
      !crypto.timingSafeEqual(expectedBuffer, providedBuffer)
    ) {
      throw new UnauthorizedException('Valid x-admin-key header required');
    }

    return true;
  }
}
