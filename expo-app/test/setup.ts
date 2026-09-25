/* eslint-disable @typescript-eslint/no-require-imports */
/**
 * Jest setup for component tests — mocks the native-only modules whose JS
 * implementations assume a running bridge (reanimated worklets, gesture
 * handler's UI-thread runtime) or a fully mounted app shell (safe area).
 *
 * Keep the factories to `require()` calls: the nativewind Babel plugin rewrites
 * JSX/`createElement` in this file, which cannot be referenced from inside a
 * `jest.mock` factory.
 */
jest.mock('react-native-reanimated', () => require('./mocks/react-native-reanimated'));
jest.mock('react-native-gesture-handler', () => require('./mocks/react-native-gesture-handler'));
jest.mock('react-native-safe-area-context', () =>
  require('./mocks/react-native-safe-area-context')
);
