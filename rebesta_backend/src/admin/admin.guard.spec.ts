import { UnauthorizedException } from '@nestjs/common';
import { AdminGuard } from './admin.guard';

describe('AdminGuard', () => {
  const originalKey = process.env.ADMIN_API_KEY;

  afterEach(() => {
    if (originalKey === undefined) delete process.env.ADMIN_API_KEY;
    else process.env.ADMIN_API_KEY = originalKey;
  });

  const contextFor = (header: string | undefined) => ({
    switchToHttp: () => ({
      getRequest: () => ({ headers: { 'x-admin-key': header } }),
    }),
  }) as any;

  it('rejects when the key is not configured', () => {
    delete process.env.ADMIN_API_KEY;
    const guard = new AdminGuard();
    expect(() => guard.canActivate(contextFor('anything'))).toThrow(
      UnauthorizedException,
    );
  });

  it('rejects missing and incorrect keys', () => {
    process.env.ADMIN_API_KEY = 'secret';
    const guard = new AdminGuard();
    expect(() => guard.canActivate(contextFor(undefined))).toThrow(
      UnauthorizedException,
    );
    expect(() => guard.canActivate(contextFor('wrong'))).toThrow(
      UnauthorizedException,
    );
  });

  it('rejects non-string header values', () => {\n    process.env.ADMIN_API_KEY = 'secret';\n    const guard = new AdminGuard();\n    expect(() => guard.canActivate(contextFor(['secret'] as any))).toThrow(\n      UnauthorizedException,\n    );\n  });\n\n  it('accepts the configured key', () => {
    process.env.ADMIN_API_KEY = 'secret';
    const guard = new AdminGuard();
    expect(guard.canActivate(contextFor('secret'))).toBe(true);
  });
});
