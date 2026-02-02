/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

final maintenanceModeProvider = StreamProvider<bool>((ref) {
  // Force refresh on auth change (Token Refresh)
  ref.watch(authStateProvider);

  return Supabase.instance.client
      .from('app_config')
      .stream(primaryKey: ['id'])
      .eq('id', 1)
      .map((data) {
        if (data.isEmpty) return false;
        return data.first['maintenance_mode'] as bool? ?? false;
      })
      .handleError((error) {
        // Return false on error to not block the app
        return false;
      });
});
