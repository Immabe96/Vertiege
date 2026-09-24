import { z } from 'zod';

/** Email shape only — sign-in must accept every address that already exists. */
export const emailSchema = z.email('Enter a valid email address').max(254);

export const signInSchema = z.object({
  email: emailSchema,
  password: z.string().min(1, 'Enter your password'),
});

export type SignInValues = z.input<typeof signInSchema>;
