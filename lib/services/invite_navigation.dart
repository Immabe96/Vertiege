import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/world_navigation.dart';
import '../services/world_service.dart';
import '../state/resident_provider.dart';
import '../widgets/core/v_feedback.dart';
import 'analytics_events.dart';
import 'analytics_service.dart';
import 'invite_service.dart';

/// Resolves the post-auth route: redeems a pending invite when possible,
/// otherwise returns [fallback] (default home).
Future<String> routeAfterAuth(
  WidgetRef ref, {
  String fallback = '/',
  BuildContext? feedbackContext,
}) async {
  final resident = ref.read(residentProvider).resident;
  if (resident == null || !resident.gateCompleted) {
    return '/onboarding';
  }

  final result = await InviteService.redeemPendingInvite(
    residentId: resident.id,
    residentName: resident.name,
  );

  if (result.errorMessage != null) {
    unawaited(
      AnalyticsService.logEvent(AnalyticsEvents.inviteRedeemFailed),
    );
    final ctx = feedbackContext;
    if (ctx != null && ctx.mounted) {
      VFeedback.showMessage(ctx, result.errorMessage!);
    }
    return fallback;
  }

  final worldId = result.worldId;
  if (worldId != null) {
    await ref.read(residentProvider.notifier).joinWorld(worldId);
    unawaited(
      AnalyticsService.logEvent(
        AnalyticsEvents.inviteCompleted,
        parameters: {'world_id': worldId},
      ),
    );
    return exploreWorldPath(worldId);
  }

  if (fallback == '/' || fallback == '/explore') {
    for (final id in resident.joinedWorldIds) {
      if (WorldService.isRemoteWorldId(id)) {
        return exploreWorldPath(id);
      }
    }
  }

  return fallback;
}
