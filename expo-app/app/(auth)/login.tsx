import { zodResolver } from '@hookform/resolvers/zod';
import { useState } from 'react';
import { Controller, useForm } from 'react-hook-form';
import { KeyboardAvoidingView, Platform, Pressable, TextInput, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { Button } from '@/components/nativewindui/Button';
import { Text } from '@/components/nativewindui/Text';
import { useAuthStore } from '@/lib/auth-store';
import { signInSchema, type SignInValues } from '@/lib/validation/auth';

const fieldClass = 'rounded-xl border border-border bg-card px-4 py-3 text-foreground';

export default function LoginScreen() {
  const signIn = useAuthStore((s) => s.signIn);
  const [serverError, setServerError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const { control, handleSubmit } = useForm<SignInValues>({
    resolver: zodResolver(signInSchema),
    defaultValues: { email: '', password: '' },
  });

  const onSubmit = handleSubmit(async (values) => {
    setLoading(true);
    setServerError(null);
    const { error } = await signIn(values.email.trim(), values.password);
    if (error) setServerError(error.message);
    setLoading(false);
  });

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
          <View className="gap-1.5">
            <Controller
              control={control}
              name="email"
              render={({ field: { onChange, onBlur, value }, fieldState }) => (
                <>
                  <TextInput
                    className={fieldClass}
                    placeholder="Email"
                    placeholderTextColor="#8E8E93"
                    autoCapitalize="none"
                    autoComplete="email"
                    keyboardType="email-address"
                    textContentType="emailAddress"
                    value={value}
                    onChangeText={onChange}
                    onBlur={onBlur}
                    accessibilityLabel="Email"
                  />
                  {fieldState.error ? (
                    <Text variant="footnote" className="text-destructive">
                      {fieldState.error.message}
                    </Text>
                  ) : null}
                </>
              )}
            />
            <Controller
              control={control}
              name="password"
              render={({ field: { onChange, onBlur, value }, fieldState }) => (
                <>
                  <TextInput
                    className={fieldClass}
                    placeholder="Password"
                    placeholderTextColor="#8E8E93"
                    secureTextEntry
                    textContentType="password"
                    value={value}
                    onChangeText={onChange}
                    onBlur={onBlur}
                    onSubmitEditing={onSubmit}
                    accessibilityLabel="Password"
                  />
                  {fieldState.error ? (
                    <Text variant="footnote" className="text-destructive">
                      {fieldState.error.message}
                    </Text>
                  ) : null}
                </>
              )}
            />
          </View>

          {serverError ? (
            <Text variant="footnote" className="text-destructive">
              {serverError}
            </Text>
          ) : null}

          <Button onPress={onSubmit} disabled={loading}>
            <Text>{loading ? 'Signing in…' : 'Sign in'}</Text>
          </Button>
        </View>

        <View className="pt-8">
          <Pressable className="items-center py-2" onPress={() => setServerError(null)}>
            <Text variant="footnote" color="secondary">
              Forgot password? Password reset lands with the auth wave.
            </Text>
          </Pressable>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
