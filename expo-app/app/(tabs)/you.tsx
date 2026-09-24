import { Text } from '@/components/nativewindui/Text';
import { View } from 'react-native';

export default function YouScreen() {
  return (
    <View className="flex-1 items-center justify-center bg-background px-8">
      <Text variant="title1" className="font-bold">
        You
      </Text>
      <Text variant="callout" color="secondary" className="text-center">
        Identity &amp; progress land in a later wave.
      </Text>
    </View>
  );
}
