import '../widgets/profile/status_picker.dart';
import 'supabase.dart';

class ResidentStatusService {
  static String presenceModeStorage(ResidentPresence presence) =>
      switch (presence) {
        ResidentPresence.online => 'online',
        ResidentPresence.idle => 'idle',
        ResidentPresence.dnd => 'dnd',
        ResidentPresence.invisible => 'invisible',
      };

  static ResidentPresence presenceFromStorage(String? raw) =>
      switch (raw) {
        'idle' => ResidentPresence.idle,
        'dnd' => ResidentPresence.dnd,
        'invisible' => ResidentPresence.invisible,
        _ => ResidentPresence.online,
      };

  static Future<void> upsertStatus(ResidentStatus status) async {
    if (!isSupabaseConfigured()) return;
    await getSupabase().rpc(
      'upsert_resident_status',
      params: {
        'p_presence_mode': presenceModeStorage(status.presence),
        'p_custom_status': status.customStatus,
      },
    );
  }
}
