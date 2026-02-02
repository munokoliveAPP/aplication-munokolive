import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munokolive_music/models/user_profile.dart';
import 'package:munokolive_music/ui/widgets/smart_snackbar.dart';
import 'package:munokolive_music/services/auth_service.dart';

// 1. STREAMS (Lecture Réactive)

/// Stream des utilisateurs en attente de validation
final pendingUsersProvider = StreamProvider<List<UserProfile>>((ref) {
  ref.watch(authStateProvider); // Force refresh on auth change
  return Supabase.instance.client
      .from('users')
      .stream(primaryKey: ['id'])
      .eq('is_validated', false)
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => UserProfile.fromJson(json)).toList());
});

/// Stream des lieux en attente de validation
final pendingLocationsProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  ref.watch(authStateProvider); // Force refresh on auth change
  return Supabase.instance.client
      .from('locations')
      .stream(primaryKey: ['id'])
      .eq('is_validated', false)
      .order('created_at', ascending: false);
});

/// Stream de tous les utilisateurs (pour l'onglet Utilisateurs)
final allUsersProvider = StreamProvider.autoDispose.family<List<UserProfile>, String>((
  ref,
  searchTerm,
) {
  ref.watch(authStateProvider); // Force refresh on auth change
  var query = Supabase.instance.client
      .from('users')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);

  // Note: Supabase Stream doesn't support 'ilike' filtering natively on the stream itself easily
  // without filtering client-side or using row level filtering.
  // For better performance with search, we usually use .select() instead of .stream()
  // But for admin dashboard live updates, we'll map and filter client-side for now
  // or use a simple limit.

  return query.map((data) {
    final users = data.map((json) => UserProfile.fromJson(json)).toList();
    if (searchTerm.isEmpty) return users;

    final lowerTerm = searchTerm.toLowerCase();
    return users.where((u) {
      final fullName = "${u.firstName} ${u.lastName}".toLowerCase();
      final email = u.email?.toLowerCase() ?? '';
      return fullName.contains(lowerTerm) || email.contains(lowerTerm);
    }).toList();
  });
});

/// Stream des événements en attente de validation
final pendingEventsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  // Force refresh on auth change (Token Refresh)
  ref.watch(authStateProvider);

  return Supabase.instance.client
      .from('events')
      .stream(primaryKey: ['id'])
      .eq('is_validated', false)
      .order('created_at', ascending: false);
});

// 2. ÉTAT OPTIMISTE & ACTIONS (Logique Métier)

/// Notifier qui gère les IDs masqués temporairement et exécute les actions
class AdminActionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return {};
  }

  final _supabase = Supabase.instance.client;

  /// Valide ou rejette un utilisateur (avec Edge Function + Fallback)
  Future<void> validateUser(
    BuildContext context, {
    required String userId,
    required bool isValid,
    String? role, // Optional: Assign role during validation
  }) async {
    // 1. Optimistic Update: Masquer immédiatement
    _hide(userId);

    try {
      // 2. Tentative Edge Function
      try {
        final Map<String, dynamic> functionBody = {
          'userId': userId,
          'isValid': isValid,
        };
        if (role != null) {
          functionBody['role'] = role;
        }

        await _supabase.functions.invoke(
          'validate-user',
          body: functionBody,
        );
      } catch (functionError) {
        debugPrint(
          "Edge Function failed ($functionError), using direct DB fallback.",
        );

        // 3. Fallback DB Directe
        if (isValid) {
          final updates = {'is_validated': true, 'status': 'active'};
          if (role != null) {
            updates['role'] = role;
          }

          await _supabase.from('users').update(updates).eq('id', userId);
        } else {
          await _supabase
              .from('users')
              .update({'status': 'rejected'})
              .eq('id', userId);
        }
      }

      // Succès silencieux (l'élément disparaît du Stream automatiquement)

      // 5. Envoyer une notification (si validé)
      if (isValid) {
        await _sendNotification(
          userId: userId,
          title: "Compte Validé",
          message:
              "Félicitations ! Votre compte a été validé par l'administration. Vous avez maintenant accès à toutes les fonctionnalités.",
          type: "account_validated",
        );
      } else {
        // Optionnel: Notification de rejet ? Souvent on ne notifie pas les rejets pour éviter le spam,
        // ou on envoie un email. Pour l'instant, on laisse sans notification in-app car l'accès est bloqué.
      }
    } catch (e) {
      // 4. Rollback en cas d'erreur critique
      _restore(userId);
      if (context.mounted) {
        SmartSnackBar.show(context, message: "Erreur: $e", isError: true);
      }
    }
  }

  /// Helper pour envoyer une notification
  Future<void> _sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': false,
        // 'created_at': now() // Auto
      });
    } catch (e) {
      debugPrint("Erreur envoi notification: $e");
      // On ne bloque pas le flux principal pour une erreur de notif
    }
  }

  /// Valide ou supprime un lieu
  Future<void> validateLocation(
    BuildContext context, {
    required String locationId,
    required bool isValid,
  }) async {
    _hide(locationId);

    try {
      if (isValid) {
        await _supabase
            .from('locations')
            .update({'is_validated': true})
            .eq('id', locationId);

        // Notification au propriétaire du lieu (nécessite de récupérer l'owner_id d'abord)
        // On le fait en "best effort"
        final loc = await _supabase
            .from('locations')
            .select('submitted_by')
            .eq('id', locationId)
            .single();
        if (loc['submitted_by'] != null) {
          await _sendNotification(
            userId: loc['submitted_by'],
            title: "Lieu Validé",
            message:
                "Votre lieu a été validé et est maintenant visible sur la carte.",
            type: "location_validated",
          );
        }

        if (context.mounted) {
          SmartSnackBar.show(
            context,
            message: "Lieu validé !",
            isSuccess: true,
          );
        }
      } else {
        await _supabase.from('locations').delete().eq('id', locationId);

        if (context.mounted) {
          SmartSnackBar.show(
            context,
            message: "Lieu supprimé.",
            isSuccess: true,
          );
        }
      }
    } catch (e) {
      _restore(locationId);
      if (context.mounted) {
        SmartSnackBar.show(context, message: "Erreur: $e", isError: true);
      }
    }
  }

  /// Met à jour le rôle d'un utilisateur
  Future<void> updateUserRole(
    BuildContext context, {
    required String userId,
    required String newRole,
  }) async {
    // 1. Optimistic Update (Optionnel, mais on masque pour éviter les clics multiples)
    _hide(userId);

    try {
      await _supabase.from('users').update({'role': newRole}).eq('id', userId);

      if (context.mounted) {
        SmartSnackBar.show(
          context,
          message: "Rôle mis à jour: $newRole",
          isSuccess: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        SmartSnackBar.show(context, message: "Erreur: $e", isError: true);
      }
    } finally {
      // Restore visibility regardless of success/failure to allow further edits
      _restore(userId);
    }
  }

  /// Supprime un utilisateur définitivement
  Future<void> deleteUser(BuildContext context, String userId) async {
    _hide(userId);
    try {
      await _supabase.from('users').delete().eq('id', userId);
      if (context.mounted) {
        SmartSnackBar.show(
          context,
          message: "Utilisateur supprimé !",
          isSuccess: true,
        );
      }
    } catch (e) {
      _restore(userId);
      if (context.mounted) {
        SmartSnackBar.show(context, message: "Erreur: $e", isError: true);
      }
    }
  }

  /// Valide ou supprime un événement
  Future<void> validateEvent(
    BuildContext context, {
    required String eventId,
    required bool isValid,
  }) async {
    _hide(eventId);
    try {
      if (isValid) {
        await _supabase
            .from('events')
            .update({'is_validated': true})
            .eq('id', eventId);

        // Notification au propriétaire
        final evt = await _supabase
            .from('events')
            .select('submitted_by')
            .eq('id', eventId)
            .single();
        if (evt['submitted_by'] != null) {
          await _sendNotification(
            userId: evt['submitted_by'],
            title: "Événement Validé",
            message:
                "Votre événement a été validé et est maintenant visible dans l'agenda.",
            type: "event_validated",
          );
        }

        if (context.mounted) {
          SmartSnackBar.show(
            context,
            message: "Événement validé !",
            isSuccess: true,
          );
        }
      } else {
        await _supabase.from('events').delete().eq('id', eventId);

        if (context.mounted) {
          SmartSnackBar.show(
            context,
            message: "Événement supprimé.",
            isSuccess: true,
          );
        }
      }
    } catch (e) {
      _restore(eventId);
      if (context.mounted) {
        SmartSnackBar.show(context, message: "Erreur: $e", isError: true);
      }
    }
  }

  // Helpers pour l'état local
  void _hide(String id) {
    state = {...state, id};
  }

  void _restore(String id) {
    state = {...state}..remove(id);
  }
}

/// Provider global pour les actions admin
final adminActionProvider = NotifierProvider<AdminActionNotifier, Set<String>>(
  () {
    return AdminActionNotifier();
  },
);
