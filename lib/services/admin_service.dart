/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(Supabase.instance.client);
});

class AdminService {
  final SupabaseClient _supabase;

  AdminService(this._supabase);

  // Get all users
  Future<List<UserProfile>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => UserProfile.fromJson(data))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Ban user
  Future<void> banUser(String userId) async {
    await _supabase.from('users').update({'status': 'banned'}).eq('id', userId);
  }

  // Unban user
  Future<void> unbanUser(String userId) async {
    await _supabase.from('users').update({'status': 'active'}).eq('id', userId);
  }

  // Delete user (Permanently)
  Future<void> deleteUser(String userId) async {
    await _supabase.from('users').delete().eq('id', userId);
  }

  // Promote to Admin
  Future<void> promoteToAdmin(String userId) async {
    await _supabase.from('users').update({'role': 'admin'}).eq('id', userId);
  }

  // Get Statistics
  Future<Map<String, dynamic>> getStats() async {
    // This would typically use a dedicated stats endpoint or complex query
    // Simplified for now
    final usersCount = await _supabase.from('users').count();
    return {'total_users': usersCount};
  }
}
