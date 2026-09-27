import {
  CanActivate,
  ExecutionContext,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';

// ============================================================
// ADMIN GUARD
// ============================================================
//
// Protects every /admin/* route. Requests must carry the
// admin API key in a header:
//
//   x-admin-key: <ADMIN_API_KEY from backend .env>
//
// FAILS CLOSED: if ADMIN_API_KEY is not configured the
// guard rejects every request (never falls back to open).
//
// ============================================================

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

    if (!expected || provided !== expected) {
      throw new UnauthorizedException(
        'Valid x-admin-key header required',
      );
    }

    return true;
  }
}
