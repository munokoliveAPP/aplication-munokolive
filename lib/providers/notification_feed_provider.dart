import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munokolive_music/providers/user_provider.dart';
import 'package:flutter/foundation.dart';

// Model for a feed item
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String type; // 'validation_request', 'new_content', 'system'
  final String? targetId; // ID of the object (place, event, user)
  final String? targetRoute; // Where to go when clicked
  final bool isRead;
  final String? avatarUrl; // Sender's avatar
  final String? senderName; // Sender's name

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.targetId,
    this.targetRoute,
    this.isRead = false,
    this.avatarUrl,
    this.senderName,
  });
}

// Provider for the list of notifications
final notificationFeedProvider =
    StateNotifierProvider<
      NotificationFeedNotifier,
      AsyncValue<List<NotificationItem>>
    >((ref) {
      return NotificationFeedNotifier(ref);
    });

class NotificationFeedNotifier
    extends StateNotifier<AsyncValue<List<NotificationItem>>> {
  final Ref _ref;
  Timer? _timer;
  DateTime _lastChecked = DateTime.now().subtract(const Duration(days: 7));
  Set<String> _dismissedIds = {};
  // Local list to hold real-time notifications
  RealtimeChannel? _missionSubscription;
  RealtimeChannel? _generalNotificationSubscription;
  final List<NotificationItem> _realtimeNotifications = [];

  NotificationFeedNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _missionSubscription?.unsubscribe();
    _generalNotificationSubscription?.unsubscribe();
    super.dispose();
  }

  void addRealtimeNotification(NotificationItem item) {
    _realtimeNotifications.insert(0, item);
    // Refresh the state merging poll results and realtime items
    fetchNotifications();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString('last_notification_check');
    final dismissedList = prefs.getStringList('dismissed_notification_ids');

    if (lastStr != null) {
      _lastChecked = DateTime.parse(lastStr);
    }

    // Charger les notifications déjà balayées/supprimées par l'utilisateur
    if (dismissedList != null) {
      _dismissedIds = dismissedList.toSet();
    }

    // Initialize Mission Subscription
    _setupMissionSubscription();

    fetchNotifications();

    // Poll every 10 seconds (Turbo Mode)
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchNotifications();
    });
  }

  Future<void> _setupMissionSubscription() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _missionSubscription = Supabase.instance.client
        .channel('public:urgent_requests:${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'urgent_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'requester_id',
            value: user.id,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord.isEmpty) return;

            final status = newRecord['status'] as String? ?? 'pending';
            final role = newRecord['role_needed'] as String? ?? 'Mission';
            final id = newRecord['id'] as String;

            String title = "Mise à jour Mission SOS";
            String body = "Du nouveau concernant votre recherche de $role.";

            // Determine message based on status
            switch (status) {
              case 'pending':
                // Usually initial insert
                title = "SOS Lancé : $role";
                body =
                    "Votre demande est en cours de diffusion aux héros alentour.";
                break;
              case 'broadcasted':
                title = "SOS Diffusé !";
                body =
                    "Votre alerte a atteint les musiciens/pasteurs de la zone.";
                break;
              case 'accepted':
                title = "Héros Trouvé !";
                body =
                    "Quelqu'un a accepté votre mission pour $role ! Touchez pour voir.";
                break;
              case 'completed':
                title = "Mission Accomplie ?";
                body =
                    "La mission est marquée comme terminée. Merci de confirmer.";
                break;
              case 'cancelled':
                title = "Mission Annulée";
                body = "Votre demande pour $role a été annulée.";
                break;
            }

            // Create notification
            final item = NotificationItem(
              id: 'mission_${id}_$status',
              title: title,
              body: body,
              timestamp: DateTime.now(),
              type: 'mission_update',
              targetId: id,
              targetRoute: '/mission/status', // We will handle this in UI
            );

            addRealtimeNotification(item);
          },
        )
        .subscribe();
  }

  Future<void> fetchNotifications() async {
    try {
      final userProfile = _ref.read(currentUserProfileProvider).value;
      if (userProfile == null) return;

      final prefs = await SharedPreferences.getInstance();
      final clearedStr = prefs.getString('cleared_notifications_until');
      final clearedUntil = clearedStr != null
          ? DateTime.parse(clearedStr)
          : null;

      final isAdmin = userProfile.role == 'admin';
      List<NotificationItem> items = [
        ..._realtimeNotifications,
      ]; // Start with realtime items

      // 0. Fetch Persistent Notifications from DB
      try {
        final dbNotifications = await Supabase.instance.client
            .from('notifications')
            .select()
            .eq('user_id', userProfile.id)
            .order('created_at', ascending: false)
            .limit(20);

        final dbItems = (dbNotifications as List).map((data) {
          return NotificationItem(
            id: data['id'],
            title: data['title'],
            body: data['message'] ?? '',
            timestamp: DateTime.tryParse(data['created_at']) ?? DateTime.now(),
            type: data['type'] ?? 'system',
            isRead: data['is_read'] ?? false,
          );
        }).toList();

        // Merge avoiding duplicates
        for (var item in dbItems) {
          if (!items.any((existing) => existing.id == item.id)) {
            items.add(item);
          }
        }
      } catch (e) {
        // Ignore DB fetch error, stick to realtime/local
        debugPrint("Error fetching notifications: $e");
      }

      // 1. ADMIN NOTIFICATIONS (Pending Validations) - Always show regardless of clear
      if (isAdmin) {
        // Pending Users
        final pendingUsersCount = await Supabase.instance.client
            .from('users')
            .count(CountOption.exact)
            .eq('is_validated', false);

        if (pendingUsersCount > 0) {
          items.add(
            NotificationItem(
              id: 'admin_users',
              title: 'Validations Membres',
              body:
                  '$pendingUsersCount nouveau(x) membre(s) en attente de validation.',
              timestamp: DateTime.now(),
              type: 'validation_request',
              targetRoute: '/admin/users',
            ),
          );
        }

        // Pending Places
        final pendingPlacesCount = await Supabase.instance.client
            .from('locations')
            .count(CountOption.exact)
            .eq('is_validated', false);

        if (pendingPlacesCount > 0) {
          items.add(
            NotificationItem(
              id: 'admin_places',
              title: 'Validations Lieux',
              body:
                  '$pendingPlacesCount lieu(x) sacré(s) en attente de validation.',
              timestamp: DateTime.now(),
              type: 'validation_request',
              targetRoute: '/admin/places',
            ),
          );
        }

        // Pending Events
        final pendingEventsCount = await Supabase.instance.client
            .from('events')
            .count(CountOption.exact)
            .eq('is_validated', false);

        if (pendingEventsCount > 0) {
          items.add(
            NotificationItem(
              id: 'admin_events',
              title: 'Validations Événements',
              body:
                  '$pendingEventsCount événement(s) en attente de validation.',
              timestamp: DateTime.now(),
              type: 'validation_request',
              targetRoute: '/admin/events',
            ),
          );
        }
      }

      // 2. USER NOTIFICATIONS (New Content)
      // New Places (validated since last check)
      // We fetch places created recently (last 7 days) and validated
      final recentPlaces = await Supabase.instance.client
          .from('locations')
          .select('id, name, created_at')
          .eq('is_validated', true)
          .gte(
            'created_at',
            _lastChecked.subtract(const Duration(days: 1)).toIso8601String(),
          ) // Overlap slightly
          .order('created_at', ascending: false)
          .limit(3);

      for (var place in recentPlaces) {
        final createdAt = DateTime.parse(place['created_at']);

        // Skip if cleared
        if (clearedUntil != null && createdAt.isBefore(clearedUntil)) continue;

        if (createdAt.isAfter(_lastChecked)) {
          items.add(
            NotificationItem(
              id: 'place_${place['id']}',
              title: 'Nouveau Lieu Sacré !',
              body: 'Découvrez "${place['name']}" qui vient d\'être ajouté.',
              timestamp: createdAt,
              type: 'new_content',
              targetId: place['id'],
              targetRoute: '/place/details',
            ),
          );
        }
      }

      // New Events
      final recentEvents = await Supabase.instance.client
          .from('events')
          .select('id, name, created_at')
          .eq('is_validated', true)
          .gte(
            'created_at',
            _lastChecked.subtract(const Duration(days: 1)).toIso8601String(),
          )
          .order('created_at', ascending: false)
          .limit(3);

      for (var event in recentEvents) {
        final createdAt = DateTime.parse(event['created_at']);

        // Skip if cleared
        if (clearedUntil != null && createdAt.isBefore(clearedUntil)) continue;

        if (createdAt.isAfter(_lastChecked)) {
          items.add(
            NotificationItem(
              id: 'event_${event['id']}',
              title: 'Nouvel Événement !',
              body: 'Ne manquez pas "${event['name']}".',
              timestamp: createdAt,
              type: 'new_content',
              targetId: event['id'],
              targetRoute: '/event/details',
            ),
          );
        }
      }

      // Filtrer les notifications que l'utilisateur a explicitement balayées
      items = items.where((n) => !_dismissedIds.contains(n.id)).toList();

      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearAll() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cleared_notifications_until', now.toIso8601String());
    // Quand on efface tout, on considère aussi que toutes les notifications
    // actuelles sont balayées.
    _dismissedIds.clear();
    await prefs.setStringList('dismissed_notification_ids', []);

    // Refresh to apply filter
    fetchNotifications();
  }

  /// Supprime/dissimule une notification spécifique (balayage à la main)
  Future<void> dismissNotification(String id) async {
    _dismissedIds.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'dismissed_notification_ids',
      _dismissedIds.toList(),
    );

    // Mettre à jour immédiatement la liste visible
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((n) => n.id != id).toList());
  }

  Future<void> markAsRead() async {
    _lastChecked = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'last_notification_check',
      _lastChecked.toIso8601String(),
    );
    // Note: We don't clear the list immediately so the user can still see them in the modal
    // But next fetch will filter them out if logic depends strictly on time
    // For Admin notifications, they persist until validated (count > 0)
  }
}
