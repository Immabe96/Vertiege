import { Redirect } from 'expo-router';

import { useAuthStore } from '@/lib/auth-store';

/**
 * `/` sits outside both `Stack.Protected` groups, so it has to route itself.
 * Cold start lands here before expo-router picks a group.
 */
export default function Index() {
  const session = useAuthStore((s) => s.session);

  return <Redirect href={session ? '/(tabs)' : '/(auth)/login'} />;
}
