import { Button } from '@/components/ui/button';
import { Text } from '@/components/ui/text';
import { useAuthStore } from '@/lib/auth-store';
import { View } from 'react-native';

export default function HomeScreen() {
  const user = useAuthStore((s) => s.user);
  const signOut = useAuthStore((s) => s.signOut);

  return (
    <View className="flex-1 items-center justify-center gap-4 bg-background px-8">
      <Text variant="section">Welcome{user?.email ? `, ${user.email}` : ''}</Text>
      <Text variant="body" tone="secondary" className="text-center">
        Home feed lands in the next wave.
      </Text>
      <Button variant="neutral" onPress={signOut}>
        <Text>Sign out</Text>
      </Button>
    </View>
  );
}
