import '@/global.css';

import {
  PlusJakartaSans_400Regular,
  PlusJakartaSans_500Medium,
  PlusJakartaSans_600SemiBold,
} from '@expo-google-fonts/plus-jakarta-sans';
import { SpaceGrotesk_600SemiBold, SpaceGrotesk_700Bold } from '@expo-google-fonts/space-grotesk';
import { QueryClientProvider } from '@tanstack/react-query';
import * as Font from 'expo-font';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { StatusBar } from 'expo-status-bar';
import { useEffect } from 'react';
import { ActivityIndicator, View } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';

import { ToastProvider } from '@/components/ui/toast';
import { ensureDbReady } from '@/db';
import { useAuthStore } from '@/lib/auth-store';
import { queryClient } from '@/lib/query';

export {
  // Catch any errors thrown by the Layout component.
  ErrorBoundary,
} from 'expo-router';

// Weight *is* the design — a fallback-font flash reads as broken.
void SplashScreen.preventAutoHideAsync().catch(() => {});

export default function RootLayout() {
  const initialized = useAuthStore((s) => s.initialized);
  const init = useAuthStore((s) => s.init);

  const [fontsLoaded, fontError] = Font.useFonts({
    SpaceGrotesk_700Bold,
    SpaceGrotesk_600SemiBold,
    PlusJakartaSans_400Regular,
    PlusJakartaSans_500Medium,
    PlusJakartaSans_600SemiBold,
  });

  useEffect(() => {
    init();
    // Local migrations run in the background — they never gate first paint.
    ensureDbReady().catch((error: unknown) => {
      console.warn('[db] migration failed', error);
    });
  }, [init]);

  useEffect(() => {
    if (fontsLoaded && initialized) {
      SplashScreen.hideAsync().catch(() => {});
    }
  }, [fontsLoaded, initialized]);

  if (fontError) {
    // Never boot into a mis-weighted UI: surface it instead.
    throw fontError;
  }

  if (!fontsLoaded || !initialized) {
    return (
      <View className="flex-1 items-center justify-center bg-background">
        <ActivityIndicator size="large" />
      </View>
    );
  }

  return (
    <QueryClientProvider client={queryClient}>
      <GestureHandlerRootView className="flex-1 bg-background">
        <ToastProvider>
          <StatusBar style="dark" />
          <AuthGate />
        </ToastProvider>
      </GestureHandlerRootView>
    </QueryClientProvider>
  );
}

function AuthGate() {
  const session = useAuthStore((s) => s.session);

  return (
    <Stack screenOptions={{ headerShown: false, animation: 'slide_from_right' }}>
      <Stack.Protected guard={session !== null}>
        <Stack.Screen name="(tabs)" />
      </Stack.Protected>
      <Stack.Protected guard={session === null}>
        <Stack.Screen name="(auth)" />
      </Stack.Protected>
    </Stack>
  );
}
