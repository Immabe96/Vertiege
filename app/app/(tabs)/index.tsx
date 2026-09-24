import { Button } from '@/components/nativewindui/Button';
import { Text } from '@/components/nativewindui/Text';
import { useAuthStore } from '@/lib/auth-store';
import { View } from 'react-native';

export default function HomeScreen() {
  const user = useAuthStore((s) => s.user);
  const signOut = useAuthStore((s) => s.signOut);

  return (
    <View className="flex-1 items-center justify-center gap-4 bg-background px-8">
      <Text variant="title1" className="font-bold">
        Welcome{user?.email ? `, ${user.email}` : ''}
      </Text>
      <Text variant="callout" color="secondary" className="text-center">
        Home feed lands in the next wave.
      </Text>
      <Button variant="secondary" onPress={signOut}>
        <Text>Sign out</Text>
      </Button>
    </View>
  );
}
