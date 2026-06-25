import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vertiege/theme/v_theme.dart';
import 'package:vertiege/widgets/core/empty_state.dart';
import 'package:vertiege/widgets/explore/section_header.dart';
import 'package:vertiege/widgets/chat/scroll_fab.dart';
import 'package:vertiege/widgets/feed/heart_animation.dart';

void main() {
  testWidgets('App theme is compact light mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: VTheme.light, home: const SizedBox()),
    );
    expect(VTheme.light.brightness, Brightness.light);
  });

  testWidgets('ExploreSectionHeader renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ExploreSectionHeader(title: 'Test Title')),
      ),
    );
    expect(find.text('Test Title'), findsOneWidget);
  });

  testWidgets('AppErrorState renders with retry button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppErrorState(message: 'Test error', onRetry: () {}),
        ),
      ),
    );
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Test error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('ChatScrollFab renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChatScrollFab(onTap: () {})),
      ),
    );
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
  });

  testWidgets('HeartAnimationOverlay shows and removes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );
    HeartAnimationOverlay.show(
      tester.element(find.byType(SizedBox)),
      const Offset(100, 100),
    );
    await tester.pump();
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byIcon(Icons.favorite), findsNothing);
  });
}
