import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munokolive_music/models/event_model.dart';
import 'package:munokolive_music/services/auth_service.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepository(Supabase.instance.client);
});

final eventsStreamProvider = StreamProvider<List<EventModel>>((ref) {
  // Force refresh on auth change (Token Refresh)
  ref.watch(authStateProvider);

  return ref.watch(eventsRepositoryProvider).getEvents();
});

class EventsRepository {
  final SupabaseClient _client;

  EventsRepository(this._client);

  Stream<List<EventModel>> getEvents() {
    return _client
        .from('events')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => EventModel.fromJson(json)).toList());
  }
}
