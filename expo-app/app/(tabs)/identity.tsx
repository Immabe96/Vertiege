import { Text } from '@/components/ui/text';
import { View } from 'react-native';

export default function YouScreen() {
  return (
    <View className="flex-1 items-center justify-center bg-background px-8">
      <Text variant="section">You</Text>
      <Text variant="body" tone="secondary" className="text-center">
        Identity &amp; progress land in a later wave.
      </Text>
    </View>
  );
}
