import { Text } from '@/components/ui/text';
import { View } from 'react-native';

export default function WorldsScreen() {
  return (
    <View className="flex-1 items-center justify-center bg-background px-8">
      <Text variant="section">Worlds</Text>
      <Text variant="body" tone="secondary" className="text-center">
        World gallery lands in a later wave.
      </Text>
    </View>
  );
}
