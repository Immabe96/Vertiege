import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/l10n/app_localizations.dart';

void main() {
  testWidgets('AppLocalizations loads English strings', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(l10n.appTitle, 'Vertiege');
    expect(l10n.tabNexus, 'Nexus');
    expect(l10n.signOut, 'Sign out');
    expect(l10n.postFailedTapRetry, contains('tap to retry'));
  });
}
