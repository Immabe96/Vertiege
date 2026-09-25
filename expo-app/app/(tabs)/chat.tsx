import { Text } from '@/components/ui/text';
import { View } from 'react-native';

export default function ChatScreen() {
  return (
    <View className="flex-1 items-center justify-center bg-background px-8">
      <Text variant="section">Chat</Text>
      <Text variant="body" tone="secondary" className="text-center">
        DM-first inbox lands in a later wave.
      </Text>
    </View>
  );
}
