import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import '../services/voice_service.dart';

class VoiceState {
  final List<Participant> participants;
  final bool isConnected;
  final bool isConnecting;
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
    isMuted: isMuted ?? this.isMuted,
    isDeafened: isDeafened ?? this.isDeafened,
    error: clearError ? null : error ?? this.error,
    activeCampfireId: activeCampfireId ?? this.activeCampfireId,
    activeCampfireName: activeCampfireName ?? this.activeCampfireName,
    activeWorldId: activeWorldId ?? this.activeWorldId,
    activeWorldName: activeWorldName ?? this.activeWorldName,
  );
}

class VoiceNotifier extends Notifier<VoiceState> {
  StreamSubscription<List<Participant>>? _sub;

  @override
  VoiceState build() {
    ref.onDispose(() {
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

final voiceProvider = NotifierProvider<VoiceNotifier, VoiceState>(
  VoiceNotifier.new,
);
