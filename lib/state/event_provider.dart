import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../services/storage_service.dart';
import '../utils/id_generator.dart';

class EventState {
  final Map<String, List<WorldEvent>> eventsByWorld;
  final bool isLoading;

  const EventState({this.eventsByWorld = const {}, this.isLoading = false});

  EventState copyWith({
    Map<String, List<WorldEvent>>? eventsByWorld,
    bool? isLoading,
  }) => EventState(
    eventsByWorld: eventsByWorld ?? this.eventsByWorld,
    isLoading: isLoading ?? this.isLoading,
  );
}

class EventNotifier extends Notifier<EventState> {
  @override
  EventState build() => const EventState();

  /// Call from app.dart _loadStores() instead of auto-loading in constructor.
  Future<void> loadEvents() => _load();

  List<WorldEvent> getEvents(String worldId) =>
      (state.eventsByWorld[worldId] ?? []).where((e) => e.isUpcoming).toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  void createEvent({
    required String worldId,
    required String title,
    required String description,
    required String createdBy,
    required String createdByName,
    required int startsAt,
    int? endsAt,
  }) {
    final event = WorldEvent(
      id: generateId(),
      worldId: worldId,
      title: title,
      description: description,
      createdBy: createdBy,
      createdByName: createdByName,
      startsAt: startsAt,
      endsAt: endsAt ?? startsAt + 3600000,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    final events = List<WorldEvent>.from(state.eventsByWorld[worldId] ?? [])
      ..add(event);
    state = state.copyWith(
      eventsByWorld: {...state.eventsByWorld, worldId: events},
    );
    _persist();
  }

  void toggleRsvp(String worldId, String eventId, String residentId) {
    final events = (state.eventsByWorld[worldId] ?? []).map((e) {
      if (e.id != eventId) return e;
      final rsvpIds = List<String>.from(e.rsvpIds);
      if (rsvpIds.contains(residentId)) {
        rsvpIds.remove(residentId);
      } else {
        rsvpIds.add(residentId);
      }
      return e.copyWith(rsvpIds: rsvpIds);
    }).toList();
    state = state.copyWith(
      eventsByWorld: {...state.eventsByWorld, worldId: events},
    );
    _persist();
  }

  void deleteEvent(String worldId, String eventId) {
    final events = (state.eventsByWorld[worldId] ?? [])
        .where((e) => e.id != eventId)
        .toList();
    state = state.copyWith(
      eventsByWorld: {...state.eventsByWorld, worldId: events},
    );
    _persist();
  }

  Future<void> _load() async {
    final raw = await StorageService.getString('@events_data');
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final eventsByWorld = <String, List<WorldEvent>>{};
      for (final entry in map.entries) {
        eventsByWorld[entry.key] = (entry.value as List)
            .map((e) => WorldEvent.fromJson(e))
            .toList();
      }
      state = EventState(eventsByWorld: eventsByWorld);
    } catch (_) {}
  }

  void _persist() {
    final encoded = <String, dynamic>{};
    for (final entry in state.eventsByWorld.entries) {
      encoded[entry.key] = entry.value.map((e) => e.toJson()).toList();
    }
    StorageService.setStringDebounced('@events_data', jsonEncode(encoded));
  }
}

final eventProvider = NotifierProvider<EventNotifier, EventState>(
  EventNotifier.new,
);
