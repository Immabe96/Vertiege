import { Text } from '@/components/nativewindui/Text';
import { View } from 'react-native';

export default function ChatScreen() {
  return (
    <View className="flex-1 items-center justify-center bg-background px-8">
      <Text variant="title1" className="font-bold">
        Chat
      </Text>
      <Text variant="callout" color="secondary" className="text-center">
        DM-first inbox lands in a later wave.
      </Text>
    </View>
  );
}
