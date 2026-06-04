import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/utils/navigation.dart';

void main() {
  testWidgets('safeBack pops when stack allows', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/detail',
          builder: (_, _) => Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => safeBack(context, fallback: '/explore'),
                child: const Text('back'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/explore',
          builder: (_, _) => const Scaffold(body: Text('explore')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/detail');
    await tester.pumpAndSettle();
    expect(find.text('back'), findsOneWidget);

    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('safeBack uses fallback when cannot pop', (tester) async {
    final router = GoRouter(
      initialLocation: '/explore/world-1',
      routes: [
        GoRoute(
          path: '/explore/:id',
          builder: (_, state) => Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => safeBack(context, fallback: '/explore'),
                child: const Text('back'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/explore',
          builder: (_, _) => const Scaffold(body: Text('explore')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();
    expect(find.text('explore'), findsOneWidget);
  });
}
