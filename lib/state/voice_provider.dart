import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import '../services/voice_service.dart';

class VoiceState {
  final List<Participant> participants;
  final bool isConnected;
  final bool isMuted;
  final bool isDeafened;
  final String? activeCampfireId;
  final String? activeCampfireName;

  const VoiceState({
    this.participants = const [],
    this.isConnected = false,
    this.isMuted = false,
    this.isDeafened = false,
    this.activeCampfireId,
    this.activeCampfireName,
  });

  VoiceState copyWith({
    List<Participant>? participants,
    bool? isConnected,
    bool? isMuted,
    bool? isDeafened,
    String? activeCampfireId,
    String? activeCampfireName,
  }) =>
      VoiceState(
        participants: participants ?? this.participants,
        isConnected: isConnected ?? this.isConnected,
        isMuted: isMuted ?? this.isMuted,
        isDeafened: isDeafened ?? this.isDeafened,
        activeCampfireId: activeCampfireId ?? this.activeCampfireId,
        activeCampfireName: activeCampfireName ?? this.activeCampfireName,
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
  }) async {
    state = state.copyWith(
      isConnected: true,
      activeCampfireId: channelId,
      activeCampfireName: channelName,
    );
    await VoiceService.joinCampfire(
      channelId: channelId,
      residentId: residentId,
      residentName: residentName,
    );
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
