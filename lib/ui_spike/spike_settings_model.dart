import 'package:flutter/foundation.dart';

/// Local state shared across spike backends when switching tabs.
class SpikeSettingsModel extends ChangeNotifier {
  SpikeSettingsModel({
    this.notificationsEnabled = true,
    this.hapticsEnabled = false,
  });

  bool notificationsEnabled;
  bool hapticsEnabled;

  void setNotifications(bool value) {
    if (notificationsEnabled == value) return;
    notificationsEnabled = value;
    notifyListeners();
  }

  void setHaptics(bool value) {
    if (hapticsEnabled == value) return;
    hapticsEnabled = value;
    notifyListeners();
  }
}
