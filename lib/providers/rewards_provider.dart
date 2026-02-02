import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

// Provider for Best Worker (Highest Points)
final bestWorkerProvider = FutureProvider<UserProfile?>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('users')
        .select()
        .order('points', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  } catch (e) {
    return null;
  }
});

// Provider for Best Musician/Singer
final bestMusicianProvider = FutureProvider<UserProfile?>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('users')
        .select()
        // Using 'ilike' for case-insensitive matching if supported, or multiple ORs
        // Assuming category is stored as 'Musicien' or 'Chantre'
        .or('category.eq.Musicien,category.eq.Chantre,category.eq.Artiste')
        .order('points', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  } catch (e) {
    return null;
  }
});

// Provider for Best Man of God
final bestManOfGodProvider = FutureProvider<UserProfile?>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('users')
        .select()
        .or(
          'category.eq.Pasteur,category.eq.Apôtre,category.eq.Prophète,category.eq.Homme de Dieu',
        )
        .order('points', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  } catch (e) {
    return null;
  }
});

// Provider for Best Sponsor (Parrain)
// Ideally this should count referrals. For now, we'll pick a high-point user
// who is not the top worker (to show variety) or just random high scorer.
// Or we can try to use a 'Parrain' category if it exists.
// Let's assume we want the user with most points who is valid.
final bestSponsorProvider = FutureProvider<UserProfile?>((ref) async {
  try {
    // Attempt to find someone with category 'Parrain' or just 2nd best user
    final response = await Supabase.instance.client
        .from('users')
        .select()
        .order('points', ascending: false)
        .limit(2); // Get top 2

    if ((response as List).isEmpty) return null;

    final list = response as List;
    if (list.length > 1) {
      // Return the second best as Parrain if we don't have better logic
      // This is a placeholder logic to ensure we don't always show same person
      return UserProfile.fromJson(list[1]);
    }
    return UserProfile.fromJson(list[0]);
  } catch (e) {
    return null;
  }
});
