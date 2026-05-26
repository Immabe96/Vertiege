import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase.dart';

/// Tracks Supabase Realtime socket health via [RealtimeClient.onOpen] / [onClose].
class RealtimeStatusService {
  RealtimeStatusService({required this.onChanged});

  final void Function(RealtimeConnectionStatus status) onChanged;

  bool _everConnected = false;
  bool _connected = false;
  RealtimeClient? _client;

  bool get connected => _connected;

  bool get showReconnecting => _everConnected && !_connected;

  void attach(RealtimeClient client) {
    if (_client == client) return;
    _client = client;
    _connected = client.isConnected;
    if (_connected) _everConnected = true;
    onChanged(snapshot());

    client.onOpen(() {
      _everConnected = true;
      _setConnected(true);
    });
    client.onClose((_) {
      _setConnected(false);
    });
  }

  void _setConnected(bool value) {
    if (_connected == value) return;
    _connected = value;
    onChanged(snapshot());
  }

  RealtimeConnectionStatus snapshot() => RealtimeConnectionStatus(
    connected: _connected,
    showReconnecting: showReconnecting,
  );
}

class RealtimeConnectionStatus {
  const RealtimeConnectionStatus({
    required this.connected,
    required this.showReconnecting,
  });

  final bool connected;
  final bool showReconnecting;
}

const _connectedIdle = RealtimeConnectionStatus(
  connected: true,
  showReconnecting: false,
);

class RealtimeStatusNotifier extends Notifier<RealtimeConnectionStatus> {
  RealtimeStatusService? _service;
  bool _attached = false;

  @override
  RealtimeConnectionStatus build() {
    if (!isSupabaseConfigured()) {
      return _connectedIdle;
    }

    _service ??= RealtimeStatusService(
      onChanged: (status) {
        state = status;
      },
    );
    if (!_attached) {
      _service!.attach(getSupabase().realtime);
      _attached = true;
    }
    ref.onDispose(() {
      _service = null;
      _attached = false;
    });
    return _service!.snapshot();
  }
}

/// Supabase Realtime socket connected (true when Supabase is not configured).
final realtimeConnectedProvider = Provider<bool>((ref) {
  return ref.watch(realtimeStatusProvider).connected;
});

/// True after the socket was open at least once and is now disconnected.
final realtimeReconnectingProvider = Provider<bool>((ref) {
  return ref.watch(realtimeStatusProvider).showReconnecting;
});

final realtimeStatusProvider =
    NotifierProvider<RealtimeStatusNotifier, RealtimeConnectionStatus>(
      RealtimeStatusNotifier.new,
    );
