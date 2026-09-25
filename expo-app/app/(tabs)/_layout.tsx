import { Tabs } from 'expo-router';
import { Globe, House, MessagesSquare, User } from 'lucide-react-native';

import { HEX } from '@/lib/theme/tokens';

const ICON_PROPS = { strokeWidth: 2.5 } as const;

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: true,
        // Family 1 of 3: tabs shift rather than slide (push = root Stack,
        // sheet = Sheet/Dialog primitives in components/ui/).
        animation: 'shift',
        headerStyle: { backgroundColor: HEX.background },
        headerTitleStyle: { fontFamily: 'SpaceGrotesk_700Bold', fontSize: 20 },
        tabBarStyle: {
          backgroundColor: HEX['secondary-background'],
          borderTopColor: HEX.border,
          borderTopWidth: 2,
        },
        tabBarLabelStyle: { fontFamily: 'PlusJakartaSans_500Medium', fontSize: 12 },
        tabBarActiveTintColor: HEX.foreground,
        tabBarInactiveTintColor: HEX['muted-foreground'],
      }}>
      <Tabs.Screen
        name="index"
        options={{
          title: 'Nexus',
          tabBarIcon: ({ color, size }) => <House color={color} size={size} {...ICON_PROPS} />,
        }}
      />
      <Tabs.Screen
        name="worlds"
        options={{
          title: 'Worlds',
          tabBarIcon: ({ color, size }) => <Globe color={color} size={size} {...ICON_PROPS} />,
        }}
      />
      <Tabs.Screen
        name="chat"
        options={{
          title: 'Chat',
          tabBarIcon: ({ color, size }) => (
            <MessagesSquare color={color} size={size} {...ICON_PROPS} />
          ),
        }}
      />
      <Tabs.Screen
        name="identity"
        options={{
          title: 'You',
          tabBarIcon: ({ color, size }) => <User color={color} size={size} {...ICON_PROPS} />,
        }}
      />
    </Tabs>
  );
}
