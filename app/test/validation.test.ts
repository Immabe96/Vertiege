import { signInSchema } from '@/lib/validation/auth';

describe('signInSchema', () => {
  it('accepts a well-formed email and password', () => {
    expect(signInSchema.safeParse({ email: 'a@b.co', password: 'pw' }).success).toBe(true);
  });

  it('rejects a malformed email', () => {
    const result = signInSchema.safeParse({ email: 'not-an-email', password: 'pw' });
    expect(result.success).toBe(false);
    expect(result.error?.issues[0]?.path).toEqual(['email']);
  });

  it('rejects an empty password', () => {
    const result = signInSchema.safeParse({ email: 'a@b.co', password: '' });
    expect(result.success).toBe(false);
    expect(result.error?.issues[0]?.path).toEqual(['password']);
  });

  it('does not impose a minimum length on existing passwords', () => {
    expect(signInSchema.safeParse({ email: 'a@b.co', password: 'x' }).success).toBe(true);
  });

  it('rejects an over-long email', () => {
    const email = `${'a'.repeat(250)}@b.co`;
    expect(signInSchema.safeParse({ email, password: 'pw' }).success).toBe(false);
  });
});
