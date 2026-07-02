import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:livekit_client/livekit_client.dart';
import '../services/voice_service.dart';

part 'voice_provider.g.dart';

class VoiceState {
  final List<Participant> participants;
  final bool isConnected;
  final bool isConnecting;
  final bool isReconnecting;
  final bool isMuted;
  final bool isDeafened;
  final String? error;
  final String? activeCampfireId;
  final String? activeCampfireName;
  final String? activeWorldId;
  final String? activeWorldName;

  const VoiceState({
    this.participants = const [],
    this.isConnected = false,
    this.isConnecting = false,
    this.isReconnecting = false,
    this.isMuted = false,
    this.isDeafened = false,
    this.error,
    this.activeCampfireId,
    this.activeCampfireName,
    this.activeWorldId,
    this.activeWorldName,
  });

  VoiceState copyWith({
    List<Participant>? participants,
    bool? isConnected,
    bool? isConnecting,
    bool? isReconnecting,
    bool? isMuted,
    bool? isDeafened,
    String? error,
    bool clearError = false,
    String? activeCampfireId,
    String? activeCampfireName,
    String? activeWorldId,
    String? activeWorldName,
  }) => VoiceState(
    participants: participants ?? this.participants,
    isConnected: isConnected ?? this.isConnected,
    isConnecting: isConnecting ?? this.isConnecting,
    isReconnecting: isReconnecting ?? this.isReconnecting,
    isMuted: isMuted ?? this.isMuted,
    isDeafened: isDeafened ?? this.isDeafened,
    error: clearError ? null : error ?? this.error,
    activeCampfireId: activeCampfireId ?? this.activeCampfireId,
    activeCampfireName: activeCampfireName ?? this.activeCampfireName,
    activeWorldId: activeWorldId ?? this.activeWorldId,
    activeWorldName: activeWorldName ?? this.activeWorldName,
  );
}

@Riverpod(name: 'voiceProvider', keepAlive: true)
class VoiceNotifier extends _$VoiceNotifier {
  StreamSubscription<List<Participant>>? _sub;

  @override
  VoiceState build() {
    VoiceService.onDisconnected = () {
      if (state.activeCampfireId == null) return;
      state = state.copyWith(
        isConnected: false,
        isConnecting: false,
        isReconnecting: false,
        error: 'Disconnected from Campfire',
      );
    };
    VoiceService.onReconnecting = () {
      if (state.activeCampfireId == null) return;
      state = state.copyWith(
        isReconnecting: true,
        clearError: true,
      );
    };
    VoiceService.onReconnected = () {
      if (state.activeCampfireId == null) return;
      state = state.copyWith(
        isConnected: true,
        isReconnecting: false,
        clearError: true,
      );
    };
    ref.onDispose(() {
      VoiceService.onDisconnected = null;
      VoiceService.onReconnecting = null;
      VoiceService.onReconnected = null;
      _sub?.cancel();
      VoiceService.dispose();
    });
    _sub = VoiceService.participantsStream.listen((participants) {
      state = state.copyWith(participants: participants);
    });
    return const VoiceState();
  }

  Future<void> joinCampfire({
    required String channelId,
    required String channelName,
    required String residentId,
    required String residentName,
    String worldId = '',
    String worldName = '',
  }) async {
    state = state.copyWith(
      isConnected: false,
      isConnecting: true,
      clearError: true,
      activeCampfireId: channelId,
      activeCampfireName: channelName,
      activeWorldId: worldId,
      activeWorldName: worldName,
    );
    try {
      final connected = await VoiceService.joinCampfire(
        channelId: channelId,
        worldId: worldId,
        residentId: residentId,
        residentName: residentName,
      );
      state = state.copyWith(
        isConnected: connected,
        isConnecting: false,
        error: connected
            ? null
            : 'Could not join this Campfire. Check your access and try again.',
      );
    } catch (_) {
      state = state.copyWith(
        isConnected: false,
        isConnecting: false,
        error: 'Could not join this Campfire. Check your access and try again.',
      );
    }
  }

  Future<void> leaveCampfire() async {
    await VoiceService.leaveCampfire();
    state = const VoiceState();
  }

  Future<void> toggleMute() async {
    await VoiceService.toggleMute();
    state = state.copyWith(isMuted: VoiceService.isMuted);
  }

  Future<void> toggleDeafen() async {
    await VoiceService.toggleDeafen();
    state = state.copyWith(
      isDeafened: !state.isDeafened,
      isMuted: VoiceService.isMuted,
    );
  }
}
