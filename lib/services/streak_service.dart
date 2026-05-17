import 'package:flutter/material.dart';
import '../models/world_streak.dart';
import '../services/supabase.dart';

class StreakService {
  static Future<WorldStreak?> getStreak(String residentId, String worldId) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final data = await client
        .from('world_streaks')
        .select()
        .eq('resident_id', residentId)
        .eq('world_id', worldId)
        .maybeSingle();
    if (data == null) return null;
    return WorldStreak.fromSupabase(data);
  }

  static Future<WorldStreak> updateStreak(String residentId, String worldId) async {
    if (!isSupabaseConfigured()) {
      return WorldStreak(
        residentId: residentId,
        worldId: worldId,
        lastActiveDate: DateTime.now(),
      );
    }

    final client = getSupabase();
    final existing = await getStreak(residentId, worldId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int newStreak;
    int newLongest;

    if (existing == null) {
      newStreak = 1;
      newLongest = 1;
    } else {
      final lastActive = DateTime(
        existing.lastActiveDate.year,
        existing.lastActiveDate.month,
        existing.lastActiveDate.day,
      );
      final diff = today.difference(lastActive).inDays;

      if (diff == 0) {
        newStreak = existing.currentStreak;
        newLongest = existing.longestStreak;
      } else if (diff == 1) {
        newStreak = existing.currentStreak + 1;
        newLongest = (newStreak > existing.longestStreak)
            ? newStreak
            : existing.longestStreak;
      } else {
        newStreak = 1;
        newLongest = existing.longestStreak;
      }
    }

    final streak = WorldStreak(
      residentId: residentId,
      worldId: worldId,
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastActiveDate: now,
    );

    await client.from('world_streaks').upsert({
      'resident_id': residentId,
      'world_id': worldId,
      'current_streak': newStreak,
      'longest_streak': newLongest,
      'last_active_date': now.toIso8601String(),
    });

    return streak;
  }

  static IconData getStreakFlameIcon(int streak) {
    if (streak >= 30) return Icons.local_fire_department;
    if (streak >= 7) return Icons.local_fire_department;
    return Icons.local_fire_department_outlined;
  }

  static Color getStreakFlameColor(int streak) {
    if (streak >= 30) return const Color(0xFFFFD700);
    if (streak >= 7) return Colors.red;
    return Colors.orange;
  }
}
