import { Button } from '@/components/nativewindui/Button';
import { Text } from '@/components/nativewindui/Text';
import { useAuthStore } from '@/lib/auth-store';
import { useState } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  TextInput,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

export default function LoginScreen() {
  const signIn = useAuthStore((s) => s.signIn);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit() {
    if (!email.trim() || !password) return;
    setLoading(true);
    setError(null);
    const { error } = await signIn(email.trim(), password);
    if (error) setError(error.message);
    setLoading(false);
  }

  return (
    <SafeAreaView className="flex-1 bg-background">
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        className="flex-1 justify-center px-6">
        <View className="gap-2 pb-10">
          <Text variant="largeTitle" className="font-bold">
            Vertiege
          </Text>
          <Text variant="subhead" color="secondary">
            Sign in to your world
          </Text>
        </View>

        <View className="gap-4">
          <TextInput
            className="rounded-xl border border-border bg-card px-4 py-3 text-foreground"
            placeholder="Email"
            placeholderTextColor="#8E8E93"
            autoCapitalize="none"
            autoComplete="email"
            keyboardType="email-address"
            textContentType="emailAddress"
            value={email}
            onChangeText={setEmail}
          />
          <TextInput
            className="rounded-xl border border-border bg-card px-4 py-3 text-foreground"
            placeholder="Password"
            placeholderTextColor="#8E8E93"
            secureTextEntry
            textContentType="password"
            value={password}
            onChangeText={setPassword}
            onSubmitEditing={onSubmit}
          />

          {error ? (
            <Text variant="footnote" className="text-destructive">
              {error}
            </Text>
          ) : null}

          <Button onPress={onSubmit} disabled={loading}>
            <Text>{loading ? 'Signing in…' : 'Sign in'}</Text>
          </Button>
        </View>

        <View className="pt-8">
          <Pressable className="items-center py-2" onPress={() => setError(null)}>
            <Text variant="footnote" color="secondary">
              Forgot password? Password reset lands with the auth wave.
            </Text>
          </Pressable>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
