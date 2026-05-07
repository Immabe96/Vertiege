import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

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

  static ({Quest quest, String label, String icon, int target}) fromPersisted(
      Map<String, dynamic> json, String label, String icon, int target) {
    return (
      quest: Quest(
        id: json['id'] as String,
        label: label,
        icon: icon,
        target: target,
        progress: json['progress'] as int? ?? 0,
        claimed: json['claimed'] as bool? ?? false,
      ),
      label: label,
      icon: icon,
      target: target,
    );
  }
}

class QuestState {
  final List<Quest> quests;
  final String dateKey; // YYYY-MM-DD, resets daily

  const QuestState({this.quests = const [], this.dateKey = ''});

  int get completedCount => quests.where((q) => q.isComplete).length;
  int get totalXpAvailable => quests.fold(0, (sum, q) => sum + (q.claimed ? 0 : q.xpReward));
}

class QuestNotifier extends Notifier<QuestState> {
  static const _templates = [
    ('post_quest', 'Post in any world', 'create', 1),
    ('react_quest', 'React to 3 posts', 'local_fire_department', 3),
    ('comment_quest', 'Comment on a post', 'chat_bubble', 1),
    ('explore_quest', 'Visit 2 different worlds', 'explore', 2),
  ];

  @override
  QuestState build() => const QuestState();

  /// Call from app.dart _loadStores() instead of auto-loading in constructor.
  Future<void> loadQuests() => _init();

  Future<void> _init() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _load(today);
  }

  Future<void> _load(String dateKey) async {
    final raw = await StorageService.getString('@quests_data');
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data['dateKey'] == dateKey) {
          final rawQuests = data['quests'] as List?;
          if (rawQuests != null) {
            final quests = rawQuests.whereType<Map<String, dynamic>>().map((q) {
              final id = q['id'] as String? ?? '';
              final template = _templates.firstWhere((t) => t.$1 == id, orElse: () => _templates[0]);
              return Quest(
                id: id,
                label: template.$2,
                icon: template.$3,
                target: template.$4,
                progress: q['progress'] as int? ?? 0,
                claimed: q['claimed'] as bool? ?? false,
              );
            }).toList();
            state = QuestState(quests: quests, dateKey: dateKey);
            return;
          }
        }
      } catch (_) {}
    }
    // Fresh day or first load — generate new quests
    final quests = _templates.map((t) => Quest(
      id: t.$1,
      label: t.$2,
      icon: t.$3,
      target: t.$4,
    )).toList();
    state = QuestState(quests: quests, dateKey: dateKey);
    _persist();
  }

  void onPostCreated() {
    _increment('post_quest');
  }

  void onReacted() {
    _increment('react_quest');
  }

  void onCommentAdded() {
    _increment('comment_quest');
  }

  void onWorldVisited() {
    _increment('explore_quest');
  }

  void claimQuest(String questId) {
    final quests = state.quests.map((q) {
      if (q.id == questId && q.isComplete && !q.claimed) {
        return q.copyWith(claimed: true);
      }
      return q;
    }).toList();
    state = QuestState(quests: quests, dateKey: state.dateKey);
    _persist();
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
  }

  void _persist() {
    final json = jsonEncode({
      'dateKey': state.dateKey,
      'quests': state.quests.map((q) => q.toJson()).toList(),
    });
    StorageService.setStringDebounced('@quests_data', json);
  }
}

final questProvider = NotifierProvider<QuestNotifier, QuestState>(
  QuestNotifier.new,
);
