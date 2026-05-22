import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../services/verifier_session.dart';
import 'verification_review_screen.dart';

/// Verifier-only shell: review queue + sign out. No main app navigation.
class VerifierPortalScreen extends ConsumerStatefulWidget {
  const VerifierPortalScreen({super.key});

  @override
  ConsumerState<VerifierPortalScreen> createState() =>
      _VerifierPortalScreenState();
}

class _VerifierPortalScreenState extends ConsumerState<VerifierPortalScreen> {
  @override
  void initState() {
    super.initState();
    VerifierSession.enter();
  }

  Future<void> _signOut(BuildContext context) async {
    VerifierSession.exit();
    await AuthService.signOut();
    if (context.mounted) context.go('/verifier/login');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _signOut(context);
      },
      child: VerificationReviewScreen(
        onSignOut: () => _signOut(context),
      ),
    );
  }
}
