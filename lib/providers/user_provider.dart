/* Copyright © 2026 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/offline_service.dart';
import 'connectivity_provider.dart';

// Used for Ghost Mode (Impersonation)
final ghostModeUserIdProvider = StateProvider<String?>((ref) => null);

final userProfileProvider = StreamProvider.autoDispose<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  final ghostUserId = ref.watch(ghostModeUserIdProvider);

  // Watch connectivity to trigger auto-refresh when online
  final isOnline = ref.watch(isOnlineProvider);
  // Just watching isOnline is enough to trigger a rebuild when it changes.
  // We can use it to force a refresh if needed, but autoDispose + ref.watch
  // will re-run this provider body when isOnline changes.
  if (isOnline) {
    debugPrint("🌐 UserProvider: Connectivity change detected (Online)");
  }

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);

      final targetUserId = ghostUserId ?? user.id;
      final offlineService = OfflineService();

      // 1. Emit Cached Profile Immediately (Offline First)
      if (ghostUserId == null) {
        final cachedProfile = offlineService.getCurrentUserProfile();
        if (cachedProfile != null) {
          debugPrint(
            "📦 UserProvider: Emitting cached profile for ${cachedProfile.email}",
          );
        }
      }

      Stream<UserProfile?> safeUserStream() async* {
        // Yield Cache First
        if (ghostUserId == null) {
          final cachedProfile = offlineService.getCurrentUserProfile();
          if (cachedProfile != null) {
            yield cachedProfile;
          }
        }

        try {
          // Realtime Stream
          final stream = Supabase.instance.client
              .from('users')
              .stream(primaryKey: ['id'])
              .eq('id', targetUserId)
              .map((data) {
                if (data.isEmpty) return null;
                return UserProfile.fromJson(data.first);
              });

          await for (final profile in stream) {
            // Update Cache on new data
            if (profile != null && ghostUserId == null) {
              await offlineService.saveCurrentUserProfile(profile);
            }
            yield profile;
          }
        } catch (e) {
          debugPrint("⚠️ Realtime Stream Error (UserProvider): $e");
          debugPrint("🔄 Switching to fallback HTTP fetch strategy...");

          try {
            // Fallback: HTTP Request
            final data = await Supabase.instance.client
                .from('users')
                .select()
                .eq('id', targetUserId)
                .maybeSingle();

            if (data != null) {
              final profile = UserProfile.fromJson(data);
              if (ghostUserId == null) {
                await offlineService.saveCurrentUserProfile(profile);
              }
              yield profile;
            } else {
              // User truly does not exist in DB
              // Only yield null if we strictly have NO cache
              if (ghostUserId == null) {
                final cached = offlineService.getCurrentUserProfile();
                if (cached != null) {
                  debugPrint("⚠️ HTTP failed but keeping cache.");
                  // Don't yield null, just keep last yield (cache)
                  // But we must keep stream alive?
                  // async* keeps alive until we return.
                  // Ensure we yield the cached value again to be safe and keep stream active
                  yield cached;
                  // Wait forever to keep stream open without error
                  await Future.delayed(const Duration(days: 365));
                  return;
                }
              }
              yield null;
            }
          } catch (fallbackError) {
            debugPrint("❌ Fallback fetch failed: $fallbackError");

            final cachedProfile = (ghostUserId == null)
                ? offlineService.getCurrentUserProfile()
                : null;

            if (cachedProfile != null) {
              debugPrint(
                "✅ Keeping cached profile visible despite network error.",
              );
              // Do not rethrow, just keep stream open with cache
              yield cachedProfile;
              // Keep stream alive to prevent "done" state or error propagation
              await Future.delayed(const Duration(days: 365));
            } else {
              // No cache, no network -> Error State
              // Check for Infinite Recursion (42P17)
              final errorStr = fallbackError.toString();
              if (errorStr.contains('42P17') ||
                  errorStr.contains('infinite recursion')) {
                throw Exception(
                  "Maintenance Serveur (Code 42P17). Veuillez patienter, une mise à jour est en cours.",
                );
              }

              // We throw so UI shows Error instead of ProfileCreation
              throw Exception(
                "Impossible de charger le profil. Vérifiez votre connexion. ($fallbackError)",
              );
            }
          }
        }
      }

      return safeUserStream();
    },
    // FIX: Don't emit null on loading/error. Keep loading or emit error.
    loading: () {
      // If we have a cached profile, show it even during auth loading?
      // No, auth loading means we don't know who is logged in.
      // Return a never-completing future to keep state as 'Loading'
      return Stream.fromFuture(Completer<UserProfile?>().future);
    },
    error: (error, stack) => Stream.error(error, stack),
  );
});

// Alias for easier access
final currentUserProfileProvider = Provider<AsyncValue<UserProfile?>>((ref) {
  return ref.watch(userProfileProvider);
});
