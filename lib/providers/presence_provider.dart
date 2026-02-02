import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

// State is the Set of User IDs currently online
class PresenceController extends StateNotifier<Set<String>> {
  final SupabaseClient _client;
  RealtimeChannel? _channel;

  PresenceController(this._client) : super({});

  Future<void> init() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // Join Global Presence Channel
    _channel = _client.channel('global_presence');

    _channel!
        .onPresenceSync((payload) {
          final newState = <String>{};

          // presenceState() returns List<PresenceState> or Map based on version
          // Supabase Flutter v2: _channel.presenceState() returns List<PresenceState>
          // But payload in onPresenceSync is dynamic.
          // Safest is to use _channel.presenceState() after sync.

          final presenceState = _channel!.presenceState();

          for (final entry in presenceState) {
            // entry.presences is List<Presence>
            for (final presence in entry.presences) {
              final payload = presence.payload;
              if (payload['user_id'] != null) {
                newState.add(payload['user_id'] as String);
              }
            }
          }

          state = newState;
        })
        .subscribe((status, error) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            // Track self
            try {
              await _channel!.track({
                'user_id': user.id,
                'online_at': DateTime.now().toIso8601String(),
              });
              debugPrint("✅ Presence tracked for ${user.id}");
            } catch (e) {
              debugPrint("❌ Error tracking presence: $e");
            }
          }
        });
  }

  void leave() {
    _channel?.unsubscribe();
    _channel = null;
  }
}

final presenceControllerProvider =
    StateNotifierProvider<PresenceController, Set<String>>((ref) {
      return PresenceController(Supabase.instance.client);
    });
