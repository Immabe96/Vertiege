import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';

import '../../router/search_navigation.dart';
import '../../router/world_navigation.dart';
import '../../state/resident_provider.dart';
import '../../widgets/core/v_accessible.dart';
import '../../widgets/identity/allies_preview_row.dart';
import 'identity_screen.dart';

/// Identity tab: honour wall + allies (Forui chrome).
class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final residentId = ref.watch(residentProvider).resident?.id;

    return VTabPage(
      title: 'Identity',
      headerActions: [
        if (residentId != null)
          VAccessibleHeaderAction(
            label: 'Preview public profile',
            icon: const Icon(VIcons.user),
            onPress: () => context.push(residentProfilePath(residentId)),
          ),
        VAccessibleHeaderAction(
          label: 'Search residents',
          icon: const Icon(VIcons.search),
          onPress: () => openGlobalSearch(context),
        ),
        VAccessibleHeaderAction(
          label: 'Refresh honour wall',
          icon: const Icon(VIcons.rotateCw),
          onPress: () => refreshHonourWallData(ref, context),
        ),
        VAccessibleHeaderAction(
          label: 'Settings',
          icon: const Icon(VIcons.settings),
          onPress: () => context.push('/settings'),
        ),
      ],
      body: const Column(
        children: [
          AlliesPreviewRow(),
          Expanded(child: IdentityScreen(embedded: true)),
        ],
      ),
    );
  }
}
