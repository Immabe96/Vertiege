import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared axis–style transitions for pushed routes (same feel on iOS and Android).
class VPageTransitions {
  VPageTransitions._();

  static const Duration _duration = Duration(milliseconds: 280);
  static const Duration _reverseDuration = Duration(milliseconds: 240);

  static CustomTransitionPage<void> fadeSlide({
    required GoRouterState state,
    required Widget child,
    bool slideUp = false,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: _duration,
      reverseTransitionDuration: _reverseDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offset = slideUp
            ? Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            : Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero);
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: SlideTransition(
            position: offset.animate(animation),
            child: child,
          ),
        );
      },
    );
  }

  /// Horizontal panel slide for chat navigation (DCX-120).
  static CustomTransitionPage<void> panelSlide({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: _duration,
      reverseTransitionDuration: _reverseDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}

/// [GoRoute] with consistent transitions for full-screen pushes.
GoRoute vGoRoute({
  required String path,
  required Widget Function(BuildContext context, GoRouterState state) builder,
  List<RouteBase> routes = const [],
  bool slideUp = false,
  bool panelSlide = false,
  String? name,
  GoRouterRedirect? redirect,
}) {
  return GoRoute(
    path: path,
    name: name,
    redirect: redirect,
    routes: routes,
    pageBuilder: (context, state) => panelSlide
        ? VPageTransitions.panelSlide(
            state: state,
            child: builder(context, state),
          )
        : VPageTransitions.fadeSlide(
            state: state,
            slideUp: slideUp,
            child: builder(context, state),
          ),
  );
}
