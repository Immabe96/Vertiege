import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/storage_service.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../services/supabase.dart';
import 'resident_provider.dart';

part 'quest_provider.g.dart';

class Quest {
  final String id;
  final String label;
  final String icon;
  final int target;
  final int progress;
  final bool claimed;

  const Quest({
    required this.id,
    required this.label,
    required this.icon,
    required this.target,
    this.progress = 0,
    this.claimed = false,
  });

  Quest copyWith({
    String? id,
    String? label,
    String? icon,
    int? target,
    int? progress,
    bool? claimed,
  }) {
    return Quest(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      claimed: claimed ?? this.claimed,
    );
  }

  bool get isComplete => progress >= target;
  int get xpReward => target * 10;

  Map<String, dynamic> toJson() => {
    'id': id,
    'progress': progress,
    'claimed': claimed,
  };

  static Quest fromTemplate(
    (String, String, String, int) template, {
    int progress = 0,
    bool claimed = false,
  }) {
    return Quest(
      id: template.$1,
      label: template.$2,
      icon: template.$3,
      target: template.$4,
      progress: progress,
      claimed: claimed,
    );
  }
}

class QuestState {
  final List<Quest> quests;
  final String dateKey;
  final bool isLoading;

  const QuestState({
    this.quests = const [],
    this.dateKey = '',
    this.isLoading = false,
  });

  int get completedCount => quests.where((q) => q.isComplete).length;
  int get totalXpAvailable =>
      quests.fold(0, (sum, q) => sum + (q.claimed ? 0 : q.xpReward));

  QuestState copyWith({
    List<Quest>? quests,
    String? dateKey,
    bool? isLoading,
  }) =>
      QuestState(
        quests: quests ?? this.quests,
        dateKey: dateKey ?? this.dateKey,
        isLoading: isLoading ?? this.isLoading,
      );
}

@Riverpod(name: 'questProvider', keepAlive: true)
class QuestNotifier extends _$QuestNotifier {
  static const _templates = [
    ('post_quest', 'Post in any world', 'create', 1),
    ('react_quest', 'React to 3 posts', 'local_fire_department', 3),
    ('comment_quest', 'Comment on a post', 'chat_bubble', 1),
    ('explore_quest', 'Visit 2 different worlds', 'explore', 2),
  ];

  @override
  QuestState build() => const QuestState();

  Future<void> loadQuests() => _init();

  Future<void> _init() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _load(today);
  }

  Future<void> _load(String dateKey) async {
    state = state.copyWith(isLoading: true);
    try {
      final fromCloud = await _loadFromCloud(dateKey);
      if (fromCloud != null) {
        state = QuestState(quests: fromCloud, dateKey: dateKey);
        _persist();
        return;
      }

      final raw = await StorageService.getString('@quests_data');
      if (raw != null) {
        try {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          if (data['dateKey'] == dateKey) {
            final rawQuests = data['quests'] as List?;
            if (rawQuests != null) {
              final quests = rawQuests.whereType<Map<String, dynamic>>().map((q) {
                final id = q['id'] as String? ?? '';
                final template = _templates.firstWhere(
                  (t) => t.$1 == id,
                  orElse: () => _templates[0],
                );
                return Quest.fromTemplate(
                  template,
                  progress: q['progress'] as int? ?? 0,
                  claimed: q['claimed'] as bool? ?? false,
                );
              }).toList();
              state = QuestState(quests: quests, dateKey: dateKey);
              _syncAllToCloud();
              return;
            }
          }
        } catch (_) {}
      }

      final quests = _templates.map(Quest.fromTemplate).toList();
      state = QuestState(quests: quests, dateKey: dateKey);
      _persist();
      _syncAllToCloud();
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<List<Quest>?> _loadFromCloud(String dateKey) async {
    if (!isSupabaseConfigured()) return null;
    final userId = maybeSupabase()?.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final rows = await getSupabase()
          .from('user_daily_quests')
          .select('quest_id, progress, target, claimed')
          .eq('user_id', userId)
          .eq('quest_date', dateKey);

      final list = rows as List;
      if (list.isEmpty) return null;

      final byId = <String, Map<String, dynamic>>{};
      for (final row in list) {
        final map = row as Map<String, dynamic>;
        byId[map['quest_id'] as String? ?? ''] = map;
      }

      return _templates.map((t) {
        final row = byId[t.$1];
        if (row == null) {
          return Quest.fromTemplate(t);
        }
        return Quest.fromTemplate(
          t,
          progress: (row['progress'] as num?)?.toInt() ?? 0,
          claimed: row['claimed'] as bool? ?? false,
        );
      }).toList();
    } catch (e) {
      debugPrint('daily quests cloud load failed: $e');
      return null;
    }
  }

  Future<void> _syncQuestToCloud(Quest quest) async {
    if (!isSupabaseConfigured()) return;
    try {
      await getSupabase().rpc(
        'upsert_daily_quest_progress',
        params: {
          'p_quest_id': quest.id,
          'p_progress': quest.progress,
          'p_target': quest.target,
        },
      );
    } catch (e) {
      debugPrint('upsert_daily_quest_progress failed: $e');
    }
  }

  void _syncAllToCloud() {
    for (final q in state.quests) {
      _syncQuestToCloud(q);
    }
  }

  void onPostCreated() => _increment('post_quest');

  void onReacted() => _increment('react_quest');

  void onCommentAdded() => _increment('comment_quest');

  void onWorldVisited() => _increment('explore_quest');

  Future<void> claimQuest(String questId) async {
    final quest = state.quests
        .where((q) => q.id == questId && q.isComplete && !q.claimed)
        .firstOrNull;
    if (quest == null) return;

    var awarded = false;
    if (isSupabaseConfigured()) {
      try {
        final result = await getSupabase().rpc(
          'claim_daily_quest',
          params: {'p_quest_id': questId},
        );
        awarded = (result is int && result > 0) || result != null;
        if (awarded) {
          await ref.read(residentProvider.notifier).refreshGamificationFromServer();
        }
      } catch (e) {
        debugPrint('claim_daily_quest failed: $e');
      }
    }

    if (!awarded) {
      await ref
          .read(residentProvider.notifier)
          .awardActivityXp('daily_quest_${quest.id}', quest.xpReward);
    }

    final quests = state.quests.map((q) {
      if (q.id == questId) return q.copyWith(claimed: true);
      return q;
    }).toList();
    state = QuestState(quests: quests, dateKey: state.dateKey);
    _persist();
    final updated = quests.where((q) => q.id == questId).firstOrNull;
    if (updated != null) await _syncQuestToCloud(updated.copyWith(claimed: true));
    unawaited(
      AnalyticsService.logEvent(
        AnalyticsEvents.questCompleted,
        parameters: {'quest_id': questId},
      ),
    );
  }

  void _increment(String questId) {
    final quests = state.quests.map((q) {
      if (q.id == questId && !q.isComplete) {
        return q.copyWith(progress: q.progress + 1);
      }
      return q;
    }).toList();
    state = QuestState(quests: quests, dateKey: state.dateKey);
    _persist();
    final updated = quests.where((q) => q.id == questId).firstOrNull;
    if (updated != null) _syncQuestToCloud(updated);
  }

  void _persist() {
    final json = jsonEncode({
      'dateKey': state.dateKey,
      'quests': state.quests.map((q) => q.toJson()).toList(),
    });
    StorageService.setStringDebounced('@quests_data', json);
  }

  void clearForSignOut() {
    state = const QuestState();
  }
}
