import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vertiege/theme/app_theme.dart';
import 'package:vertiege/widgets/core/empty_state.dart';
import 'package:vertiege/ui/feedback/v_states.dart';
import 'package:vertiege/widgets/explore/section_header.dart';
import 'package:vertiege/widgets/chat/scroll_fab.dart';

void main() {
  testWidgets('App theme is compact light mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.theme, home: const SizedBox()),
    );
    expect(AppTheme.theme.brightness, Brightness.light);
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
  testWidgets('AppEmptyState renders title and description', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            title: 'No Data',
            description: 'This is an empty state',
            icon: Icons.inbox,
          ),
        ),
      ),
    );
    expect(find.text('No Data'), findsOneWidget);
    expect(find.text('This is an empty state'), findsOneWidget);
    expect(find.byIcon(Icons.inbox), findsOneWidget);
  });

  testWidgets('VEmptyState renders title and description', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VEmptyState(
            title: 'No Items',
            description: 'There are no items here',
            icon: Icons.list,
          ),
        ),
      ),
    );
    expect(find.text('No Items'), findsOneWidget);
    expect(find.text('There are no items here'), findsOneWidget);
    expect(find.byIcon(Icons.list), findsOneWidget);
  });
}
