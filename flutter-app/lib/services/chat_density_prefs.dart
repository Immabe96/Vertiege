import 'package:shared_preferences/shared_preferences.dart';

enum ChatMessageDensity { cozy, compact }

/// Local chat message spacing preference (cozy vs compact).
class ChatDensityPrefs {
  ChatDensityPrefs._();

  static const _key = 'chat_message_density';

  static Future<ChatMessageDensity> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return raw == ChatMessageDensity.compact.name
        ? ChatMessageDensity.compact
        : ChatMessageDensity.cozy;
  }

  static Future<void> save(ChatMessageDensity density) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, density.name);
  }
}
