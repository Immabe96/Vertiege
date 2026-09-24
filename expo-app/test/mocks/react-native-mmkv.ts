/**
 * Jest stand-in for `react-native-mmkv`.
 *
 * The real entry point pulls in `react-native-nitro-modules`, which throws at
 * import time because there is no native NitroModules host in Jest. MMKV ships
 * a dependency-free in-memory implementation for exactly this case — reuse it
 * so tests exercise the same API surface as production.
 */
export { createMockMMKV as createMMKV } from 'react-native-mmkv/lib/createMMKV/createMockMMKV';
