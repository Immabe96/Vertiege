/* eslint-disable @typescript-eslint/no-require-imports */
/**
 * Minimal Reanimated mock — `react-native-reanimated/mock` pulls in the
 * worklets runtime, which needs a live native module. Component tests only
 * need the JS surface our primitives use.
 */
const RN = require('react-native');

const layoutAnimation = () => {
  const chain: any = () => chain;
  chain.duration = () => chain;
  chain.delay = () => chain;
  chain.springify = () => chain;
  chain.damping = () => chain;
  chain.stiffness = () => chain;
  chain.mass = () => chain;
  chain.velocity = () => chain;
  return chain;
};

const Animated = {
  View: RN.View,
  Text: RN.Text,
  Image: RN.Image,
  ScrollView: RN.ScrollView,
  createAnimatedComponent: <T>(component: T) => component,
};

const sharedValue = <T>(initial: T) => ({ value: initial });

module.exports = {
  __esModule: true,
  default: Animated,
  Animated,
  useSharedValue: sharedValue,
  useAnimatedStyle: (fn: () => object) => (typeof fn === 'function' ? fn() : {}),
  useReducedMotion: () => false,
  useAnimatedProps: (fn: () => object) => (typeof fn === 'function' ? fn() : {}),
  withTiming: <T>(value: T) => value,
  withSpring: <T>(value: T) => value,
  withDelay: <T>(_: number, value: T) => value,
  withRepeat: <T>(value: T) => value,
  withSequence: <T>(...values: T[]) => values[0],
  cancelAnimation: () => {},
  runOnJS: <T>(fn: T) => fn,
  runOnUI: <T>(fn: T) => fn,
  interpolate: () => 0,
  Easing: {
    linear: (t: number) => t,
    ease: (t: number) => t,
    quad: (t: number) => t,
    cubic: (t: number) => t,
    in: (fn: (t: number) => number) => fn,
    out: (fn: (t: number) => number) => fn,
    inOut: (fn: (t: number) => number) => fn,
  },
  FadeIn: layoutAnimation(),
  FadeOut: layoutAnimation(),
  FadeInUp: layoutAnimation(),
  FadeInDown: layoutAnimation(),
  ZoomIn: layoutAnimation(),
  ZoomOut: layoutAnimation(),
  SlideInUp: layoutAnimation(),
  SlideInDown: layoutAnimation(),
  SlideInLeft: layoutAnimation(),
  SlideInRight: layoutAnimation(),
  SlideOutUp: layoutAnimation(),
  SlideOutDown: layoutAnimation(),
  Layout: layoutAnimation(),
  LinearTransition: layoutAnimation(),
};
