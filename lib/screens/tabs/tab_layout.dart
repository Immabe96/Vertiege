import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/notification_provider.dart';

final scrollToTopProvider = StateProvider<int>((ref) => 0);

class TabLayout extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const TabLayout({super.key, required this.navigationShell});

  static const _destinations = [
    (icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Nexus'),
    (icon: Icons.public_outlined, activeIcon: Icons.public, label: 'Explore'),
    (icon: Icons.chat_outlined, activeIcon: Icons.chat, label: 'Chats'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Identity'),
    (icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Alerts'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationProvider).notifications.where((n) => !n.read).length;
    final theme = Theme.of(context);
    final index = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(color: theme.shadowColor.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: List.generate(_destinations.length, (i) {
                  final isActive = i == index;
                  final dest = _destinations[i];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (i == index) ref.read(scrollToTopProvider.notifier).state++;
                        navigationShell.goBranch(i, initialLocation: i == index);
                      },
                      child: Semantics(
                        label: dest.label,
                        selected: isActive,
                        button: true,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
                          decoration: BoxDecoration(
                            color: isActive ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (i == 4 && unread > 0)
                                Badge(
                                  label: Text('$unread', style: const TextStyle(fontSize: 10)),
                                  child: Icon(isActive ? dest.activeIcon : dest.icon, size: 22,
                                      color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline),
                                )
                              else
                                Icon(isActive ? dest.activeIcon : dest.icon, size: 22,
                                    color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline),
                              if (isActive)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 4, height: 4,
                                  decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
