import 'package:flutter/foundation.dart';

/// Notifies [GoRouter] to re-run redirect without recreating the router instance.
class GoRouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}
