import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munokolive_music/models/user_profile.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  // Current User (Synchronous check from session)
  User? get currentUser => _supabase.auth.currentUser;

  // Session Stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign Up with Email & Password (Basic)
  Future<AuthResponse> signUpWithEmail(
    String email,
    String password, [
    Map<String, dynamic>? data,
  ]) async {
    try {
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      return res;
    } catch (e) {
      debugPrint("Sign Up Error: $e");
      rethrow;
    }
  }

  // Sign In with Email & Password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res;
    } catch (e) {
      debugPrint("Sign In Error: $e");
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Helper: Get User Profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (e) {
      debugPrint("Get Profile Error: $e");
      return null;
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.flutter://login-callback',
    );
  }

  // Update Password
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  // Update User Profile (Public method)
  Future<void> updateUserProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String category,
    String? subCategory,
    String? churchName,
    String? photoUrl,
    DateTime? birthDate,
    String? referredBy,
    String? phoneNumber,
    String? country,
    String? city,
    String? commune,
    String? neighborhood,
    bool? isAvailable,
  }) async {
    final updates = {
      'id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'category': category,
      'sub_category': subCategory,
      'church_name': churchName,
      'photo_url': photoUrl,
      'birth_date': birthDate?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'referred_by': referredBy,
      'phone_number': phoneNumber,
      'country': country,
      'city': city,
      'commune': commune,
      'neighborhood': neighborhood,
      'is_available': isAvailable,
    }..removeWhere((_, v) => v == null);

    // Check for referral code
    final user = await _supabase
        .from('users')
        .select('referral_code')
        .eq('id', userId)
        .maybeSingle();
    if (user == null || user['referral_code'] == null) {
      updates['referral_code'] =
          '${firstName.substring(0, 3).toUpperCase()}${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }

    await _supabase.from('users').upsert(updates);

    // If referred, increment the referrer's count via RPC
    if (referredBy != null) {
      try {
        await _supabase.rpc(
          'increment_referral_count',
          params: {'referrer_code': referredBy},
        );
      } catch (e) {
        debugPrint('Failed to increment referral count: $e');
      }
    }
  }

  // Validate Referral Code - Returns Referrer ID if valid, null otherwise
  Future<String?> validateReferralCode(String code) async {
    try {
      final data = await _supabase
          .from('users')
          .select('id')
          .eq('referral_code', code)
          .maybeSingle();

      if (data != null && data['id'] != null) {
        return data['id'] as String;
      }
      return null;
    } catch (e) {
      debugPrint("Validate Referral Code Error: $e");
      return null;
    }
  }

  // Delete Account
  Future<void> deleteAccount(String userId) async {
    try {
      // Try to delete via RPC (secure way)
      await _supabase.rpc('delete_user_account');
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint("Delete Account Error: $e");
      // Fallback: just sign out
      await _supabase.auth.signOut();
      rethrow;
    }
  }

  // Upload Profile Image with Timeout and Retry
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = 'profiles/$userId/avatar.$fileExt';
      final filePath = fileName;

      // Try to upload with a timeout
      await _supabase.storage
          .from('files')
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          )
          .timeout(const Duration(seconds: 15)); // 15s timeout

      final imageUrl = _supabase.storage.from('files').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      // Return null so the profile update can still proceed without the image
      return null;
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref
      .watch(authServiceProvider)
      .authStateChanges
      .map((event) => event.session?.user);
});
