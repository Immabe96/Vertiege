/* eslint-disable @typescript-eslint/no-require-imports */
/** Gesture handler without its UI-thread runtime — gestures never fire. */
const React = require('react');
const RN = require('react-native');

function makeGesture(): any {
  const gesture: any = {};
  for (const method of [
    'enabled',
    'activeOffsetX',
    'activeOffsetY',
    'failOffsetX',
    'failOffsetY',
    'maxDuration',
    'minDistance',
    'onBegin',
    'onStart',
    'onUpdate',
    'onEnd',
    'onFinalize',
    'onFail',
    'onCancel',
    'withRef',
    'runOnJS',
    'simultaneousWithExternalGesture',
    'requireExternalGestureToFail',
  ]) {
    gesture[method] = () => gesture;
  }
  return gesture;
}

const Gesture = {
  Pan: () => makeGesture(),
  Tap: () => makeGesture(),
  LongPress: () => makeGesture(),
  Race: () => makeGesture(),
  Simultaneous: () => makeGesture(),
  Exclusive: () => makeGesture(),
  Native: () => makeGesture(),
};

const GestureDetector = ({ children }: { children?: React.ReactNode }) =>
  React.createElement(RN.View, null, children);

module.exports = {
  __esModule: true,
  Gesture,
  GestureDetector,
  gestureHandlerRootHOC: (component: any) => component,
  GestureHandlerRootView: ({ children, ...props }: any) =>
    React.createElement(RN.View, props, children),
  State: {},
  Directions: {},
};
