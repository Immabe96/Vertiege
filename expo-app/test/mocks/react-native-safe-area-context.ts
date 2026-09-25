/* eslint-disable @typescript-eslint/no-require-imports */
/** Safe-area without the native module — every screen is a full-bleed device. */
const React = require('react');
const RN = require('react-native');

const insets = { top: 0, right: 0, bottom: 0, left: 0 };

module.exports = {
  __esModule: true,
  SafeAreaProvider: ({ children }: { children?: React.ReactNode }) =>
    React.createElement(RN.View, null, children),
  SafeAreaView: ({ children, ...props }: any) => React.createElement(RN.View, props, children),
  useSafeAreaInsets: () => insets,
  useSafeAreaFrame: () => ({ x: 0, y: 0, width: 0, height: 0 }),
  initialWindowMetrics: { insets, frame: { x: 0, y: 0, width: 0, height: 0 } },
};
