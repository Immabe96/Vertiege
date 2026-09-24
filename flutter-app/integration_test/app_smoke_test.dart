import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vertiege/main.dart' as app;

/// Smoke: app boots to a Flutter UI (login or shell) without crashing.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cold start reaches a MaterialApp frame', (tester) async {
    app.main();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(MaterialApp), findsWidgets);
  });
}
