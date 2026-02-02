import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munokolive_music/models/user_profile.dart';
import 'package:munokolive_music/models/chat_message.dart';
import 'package:munokolive_music/services/auth_service.dart';

// --- Providers ---

// 0. Muted Salons State (Persisted in Memory)
final mutedSalonsProvider = StateProvider<Set<String>>((ref) => {});

// 1. Messages Stream (Live Chat)
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  salonId,
) {
  return Supabase.instance.client
      .from('chat_messages')
      .stream(primaryKey: ['id'])
      .eq('salon_id', salonId)
      .order('created_at', ascending: false)
      .limit(50)
      .map((data) => data.map((json) => ChatMessage.fromJson(json)).toList());
});

// 2. Membership Status (Has Joined?)
final salonMembershipProvider = StreamProvider.family<bool, String>((
  ref,
  salonId,
) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Stream.value(false);

  return Supabase.instance.client
      .from('salon_memberships')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((data) => data.where((m) => m['salon_id'] == salonId).isNotEmpty);
});

// 2.5 All Joined Salons (For List View)
final joinedSalonsListProvider = StreamProvider<List<String>>((ref) {
  // Force refresh on auth change (Token Refresh)
  ref.watch(authStateProvider);

  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Stream.value([]);

  return Supabase.instance.client
      .from('salon_memberships')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((data) => data.map((e) => e['salon_id'].toString()).toList());
});

// 3. Online Presence (Who is here?)
final salonPresenceProvider =
    StateNotifierProvider.family<PresenceNotifier, List<UserProfile>, String>((
      ref,
      salonId,
    ) {
      return PresenceNotifier(salonId, ref);
    });

// 4. Active Topic (Debate Board)
final activeTopicProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, salonId) {
      return Supabase.instance.client
          .from('salon_topics')
          .stream(primaryKey: ['id'])
          .eq('salon_id', salonId)
          .order('created_at', ascending: false)
          .limit(10)
          .map((data) {
            final active = data.where((t) => t['is_active'] == true);
            return active.isNotEmpty ? active.first : null;
          });
    });

// 5. Typing Users (Realtime)
final typingUsersProvider = StateProvider.family<List<String>, String>(
  (ref, salonId) => [],
);

// --- Controller ---

class ChatController {
  final String salonId;
  final Ref ref;

  ChatController(this.ref, this.salonId);

  Future<void> setActiveTopic(String topic, String description) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // 1. Deactivate old topics (Optional: or just rely on sorting by created_at)
    // For cleanliness, we can set others to false, but it's simpler to just insert new one
    // and query for the latest.
    // However, to be strict:
    await Supabase.instance.client
        .from('salon_topics')
        .update({'is_active': false})
        .eq('salon_id', salonId);

    // 2. Insert new topic
    await Supabase.instance.client.from('salon_topics').insert({
      'salon_id': salonId,
      'topic': topic,
      'description': description,
      'created_by': userId,
      'is_active': true,
    });
  }

  Future<void> sendMessage(
    String text,
    UserProfile user, {
    String? replyToId,
  }) async {
    if (text.trim().isEmpty) return;

    await Supabase.instance.client.from('chat_messages').insert({
      'salon_id': salonId,
      'user_id': user.id,
      'content': text.trim(),
      'user_name': user.fullName,
      'user_avatar': user.photoUrl,
      'created_at': DateTime.now().toIso8601String(),
      'reply_to_id': replyToId,
    });
  }

  Future<void> addReaction(String messageId, String emoji) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Fetch current reactions
    final res = await Supabase.instance.client
        .from('chat_messages')
        .select('reactions')
        .eq('id', messageId)
        .single();

    final currentReactions = Map<String, dynamic>.from(res['reactions'] ?? {});

    // Toggle reaction: if already reacted with same emoji, remove it.
    if (currentReactions[userId] == emoji) {
      currentReactions.remove(userId);
    } else {
      currentReactions[userId] = emoji;
    }

    await Supabase.instance.client
        .from('chat_messages')
        .update({'reactions': currentReactions})
        .eq('id', messageId);
  }

  Future<void> sendTypingEvent(String userName) async {
    ref.read(salonPresenceProvider(salonId).notifier).sendTyping(userName);
  }

  Future<void> joinSalon() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client.from('salon_memberships').insert({
      'user_id': userId,
      'salon_id': salonId,
      'joined_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> leaveSalon() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client
        .from('salon_memberships')
        .delete()
        .eq('user_id', userId)
        .eq('salon_id', salonId);
  }

  Future<void> cleanupOldMessages() async {
    // "Manne Fraîche": Remove messages > 72h
    // Note: RLS must allow this, or it must be run by an admin.
    // We try it silently.
    final threeDaysAgo = DateTime.now().subtract(const Duration(hours: 72));
    try {
      await Supabase.instance.client
          .from('chat_messages')
          .delete()
          .lt('created_at', threeDaysAgo.toIso8601String());
    } catch (e) {
      // Silent fail
      debugPrint("Manne Fraiche cleanup error: $e");
    }
  }
}

// --- Presence Notifier (Realtime) ---

class PresenceNotifier extends StateNotifier<List<UserProfile>> {
  final String salonId;
  final Ref ref; // Needed to update typing provider
  RealtimeChannel? _channel;
  final Map<String, Timer> _typingTimers = {};

  PresenceNotifier(this.salonId, this.ref) : super([]) {
    _initPresence();
  }

  void _initPresence() {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    // Create a unique channel for this salon
    _channel = client.channel('presence:$salonId');

    _channel!
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final userName = payload['user_name'] as String?;
            if (userName != null) {
              final current = ref.read(typingUsersProvider(salonId));
              if (!current.contains(userName)) {
                ref.read(typingUsersProvider(salonId).notifier).state = [
                  ...current,
                  userName,
                ];
              }

              // Reset timer for THIS user
              _typingTimers[userName]?.cancel();
              _typingTimers[userName] = Timer(const Duration(seconds: 3), () {
                _typingTimers.remove(userName);
                ref.read(typingUsersProvider(salonId).notifier).state = ref
                    .read(typingUsersProvider(salonId))
                    .where((n) => n != userName)
                    .toList();
              });
            }
          },
        )
        .onPresenceSync((payload) {
          // Update state when presence changes
          final newState = <UserProfile>[];

          // Assuming presenceState returns a list of presence objects directly
          // based on recent supabase_flutter behavior or type error.
          for (final presence in _channel!.presenceState()) {
            // presence is dynamic/Map representing the presence entry
            // which might contain 'user_id', etc. or be a wrapper.
            // Usually payload is in 'payload' or it IS the payload if flattened.
            // We'll treat it as a Map.
            final p = presence as dynamic;

            // If the structure is List<Map>, then p is Map.
            if (p is Map && p['user_id'] != null) {
              newState.add(
                UserProfile(
                  id: p['user_id'],
                  email: '', // Not needed for display
                  firstName: p['first_name'] ?? 'User',
                  lastName: '',
                  role: 'user',
                  photoUrl: p['avatar_url'],
                  category: 'Membre', // Fixed: was []
                ),
              );
            } else if (p is Map && p['payload'] != null) {
              // Fallback if it's wrapped
              final payload = p['payload'];
              if (payload is Map && payload['user_id'] != null) {
                newState.add(
                  UserProfile(
                    id: payload['user_id'],
                    email: '',
                    firstName: payload['first_name'] ?? 'User',
                    lastName: '',
                    role: 'user',
                    photoUrl: payload['avatar_url'],
                    category: 'Membre',
                  ),
                );
              }
            }
            // If the old structure (Map<String, List>) was used, we wouldn't get a List<SinglePresenceState>.
            // So we iterate the list.
          }
          state = newState;
        })
        .subscribe((status, error) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            // Track my presence
            if (user != null) {
              try {
                // Fetch extra details to share
                final resp = await client
                    .from('users')
                    .select()
                    .eq('id', user.id)
                    .single();

                if (_channel != null) {
                  await _channel!.track({
                    'user_id': user.id,
                    'first_name': resp['first_name'],
                    'avatar_url': resp['photo_url'],
                    'online_at': DateTime.now().toIso8601String(),
                  });
                }
              } catch (e) {
                // Silent error or log it
                debugPrint("Error tracking presence: $e");
              }
            }
          }
        });
  }

  @override
  void dispose() {
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> sendTyping(String userName) async {
    if (_channel == null) return;
    await _channel!.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_name': userName},
    );
  }
}

// Global provider to access controller logic easily
final chatControllerProvider = Provider.family<ChatController, String>((
  ref,
  salonId,
) {
  return ChatController(ref, salonId);
});
