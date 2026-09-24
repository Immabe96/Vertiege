import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/ally.dart';
import '../services/ally_service.dart';
import '../utils/haptics.dart';

part 'ally_provider.g.dart';

class AllyState {
  final List<Ally> allies;
  final List<Ally> pendingRequests;
  final bool isLoading;
  final String? loadError;

  const AllyState({
    this.allies = const [],
    this.pendingRequests = const [],
    this.isLoading = false,
    this.loadError,
  });

  AllyState copyWith({
    List<Ally>? allies,
    List<Ally>? pendingRequests,
    bool? isLoading,
    String? loadError,
    bool clearLoadError = false,
  }) => AllyState(
    allies: allies ?? this.allies,
    pendingRequests: pendingRequests ?? this.pendingRequests,
    isLoading: isLoading ?? this.isLoading,
    loadError: clearLoadError ? null : (loadError ?? this.loadError),
  );
}

@Riverpod(name: 'allyProvider', keepAlive: true)
class AllyNotifier extends _$AllyNotifier {
  @override
  AllyState build() => const AllyState();

  Future<void> loadAll(String residentId) async {
    state = state.copyWith(isLoading: true, clearLoadError: true);
    try {
      final allies = await AllyService.fetchAllies(residentId);
      final pending = await AllyService.fetchPendingRequests(residentId);
      state = state.copyWith(
        allies: allies,
        pendingRequests: pending,
        isLoading: false,
        clearLoadError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        loadError: 'Could not load allies. Pull to refresh.',
      );
    }
  }

  Future<void> sendRequest({
    required String requesterId,
    required String receiverId,
  }) async {
    Haptics.light();
    final optimistic = Ally(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      requesterId: requesterId,
      receiverId: receiverId,
      status: AllegianceStatus.pending,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    final snapshot = state.pendingRequests;
    state = state.copyWith(
      pendingRequests: [...state.pendingRequests, optimistic],
      clearLoadError: true,
    );
    try {
      await AllyService.sendAllegianceRequest(
        requesterId: requesterId,
        receiverId: receiverId,
      );
      // Refresh so server ids replace the local temp row.
      await loadAll(requesterId);
    } catch (_) {
      state = state.copyWith(
        pendingRequests: snapshot,
        loadError: 'Could not send ally request. Try again.',
      );
    }
  }

  Future<void> acceptRequest(String requestId) async {
    Haptics.light();
    final pending = state.pendingRequests.where((r) => r.id == requestId).toList();
    final snapshotPending = state.pendingRequests;
    final snapshotAllies = state.allies;
    final accepted = pending.isEmpty
        ? null
        : Ally(
            id: pending.first.id,
            requesterId: pending.first.requesterId,
            receiverId: pending.first.receiverId,
            status: AllegianceStatus.accepted,
            createdAt: pending.first.createdAt,
          );
    state = state.copyWith(
      pendingRequests: state.pendingRequests
          .where((r) => r.id != requestId)
          .toList(),
      allies: accepted == null ? state.allies : [...state.allies, accepted],
      clearLoadError: true,
    );
    try {
      await AllyService.acceptAllegianceRequest(requestId);
    } catch (_) {
      state = state.copyWith(
        pendingRequests: snapshotPending,
        allies: snapshotAllies,
        loadError: 'Could not accept request. Try again.',
      );
    }
  }

  Future<void> declineRequest(String requestId) async {
    Haptics.light();
    final snapshot = state.pendingRequests;
    state = state.copyWith(
      pendingRequests: state.pendingRequests
          .where((r) => r.id != requestId)
          .toList(),
      clearLoadError: true,
    );
    try {
      await AllyService.declineAllegianceRequest(requestId);
    } catch (_) {
      state = state.copyWith(
        pendingRequests: snapshot,
        loadError: 'Could not decline request. Try again.',
      );
    }
  }

  Future<void> block(String requestId) async {
    Haptics.light();
    await AllyService.blockResident(requestId);
    state = state.copyWith(
      pendingRequests: state.pendingRequests
          .where((r) => r.id != requestId)
          .toList(),
    );
  }

  Future<AllegianceStatus?> relationshipStatus(
    String residentId,
    String otherId,
  ) async {
    final rel = await AllyService.getRelationship(residentId, otherId);
    return rel?.status;
  }

  bool isAlly(String otherId) => state.allies.any(
    (a) => a.requesterId == otherId || a.receiverId == otherId,
  );

  bool hasOutgoingPending(String requesterId, String receiverId) =>
      state.pendingRequests.any(
        (a) =>
            a.status == AllegianceStatus.pending &&
            a.requesterId == requesterId &&
            a.receiverId == receiverId,
      );

  bool hasIncomingPending(String receiverId, String requesterId) =>
      state.pendingRequests.any(
        (a) =>
            a.status == AllegianceStatus.pending &&
            a.requesterId == requesterId &&
            a.receiverId == receiverId,
      );

  void clearForSignOut() {
    state = const AllyState();
  }
}
