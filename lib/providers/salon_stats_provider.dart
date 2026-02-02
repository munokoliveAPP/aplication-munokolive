import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SalonStatsNotifier extends StateNotifier<int> {
  final String salonId;
  RealtimeChannel? _channel;

  SalonStatsNotifier(this.salonId) : super(0) {
    _initListener();
  }

  void _initListener() {
    final client = Supabase.instance.client;
    // We use the same channel topic convention as the chat page
    _channel = client.channel('presence:$salonId');

    _channel!.onPresenceSync((payload) {
      final presenceState = _channel!.presenceState();
      // Calculate distinct users
      final userIds = <String>{};

      for (final entry in presenceState) {
        for (final presence in entry.presences) {
          final payload = presence.payload;
          if (payload['user_id'] != null) {
            userIds.add(payload['user_id'] as String);
          }
        }
      }

      state = userIds.length;
    }).subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

final salonStatsProvider =
    StateNotifierProvider.family<SalonStatsNotifier, int, String>((
      ref,
      salonId,
    ) {
      return SalonStatsNotifier(salonId);
    });
