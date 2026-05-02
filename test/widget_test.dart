import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:virtual_status_worlds/app.dart';

void main() {
  testWidgets('App renders onboarding when no resident', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VirtualStatusWorldsApp()));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
