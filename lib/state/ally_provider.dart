import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ally.dart';
import '../services/ally_service.dart';

class AllyState {
  final List<Ally> allies;
  final List<Ally> pendingRequests;
  final bool isLoading;

  const AllyState({
    this.allies = const [],
    this.pendingRequests = const [],
    this.isLoading = false,
  });

  AllyState copyWith({
    List<Ally>? allies,
    List<Ally>? pendingRequests,
    bool? isLoading,
  }) =>
      AllyState(
        allies: allies ?? this.allies,
        pendingRequests: pendingRequests ?? this.pendingRequests,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AllyNotifier extends Notifier<AllyState> {
  @override
  AllyState build() => const AllyState();

  Future<void> loadAll(String residentId) async {
    state = state.copyWith(isLoading: true);
    final allies = await AllyService.fetchAllies(residentId);
    final pending = await AllyService.fetchPendingRequests(residentId);
    state = state.copyWith(
      allies: allies,
      pendingRequests: pending,
      isLoading: false,
    );
  }

  Future<void> sendRequest({
    required String requesterId,
    required String receiverId,
  }) async {
    await AllyService.sendAllegianceRequest(
      requesterId: requesterId,
      receiverId: receiverId,
    );
  }

  Future<void> acceptRequest(String requestId) async {
    await AllyService.acceptAllegianceRequest(requestId);
    state = state.copyWith(
      pendingRequests: state.pendingRequests
          .where((r) => r.id != requestId)
          .toList(),
    );
  }

  Future<void> declineRequest(String requestId) async {
    await AllyService.declineAllegianceRequest(requestId);
    state = state.copyWith(
      pendingRequests: state.pendingRequests
          .where((r) => r.id != requestId)
          .toList(),
    );
  }

  Future<void> block(String requestId) async {
    await AllyService.blockResident(requestId);
    state = state.copyWith(
      pendingRequests: state.pendingRequests
          .where((r) => r.id != requestId)
          .toList(),
    );
  }

  /// Returns the relationship status between current resident and another.
  /// null = no relationship, AllegianceStatus = current state.
  Future<AllegianceStatus?> relationshipStatus(
    String residentId,
    String otherId,
  ) async {
    final rel = await AllyService.getRelationship(residentId, otherId);
    return rel?.status;
  }

  bool isAlly(String otherId) =>
      state.allies.any((a) => a.requesterId == otherId || a.receiverId == otherId);
}

final allyProvider = NotifierProvider<AllyNotifier, AllyState>(
  AllyNotifier.new,
);
