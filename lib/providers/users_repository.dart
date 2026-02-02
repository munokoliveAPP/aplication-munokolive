import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/offline_service.dart';
import 'offline_provider.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(
    ref.read(offlineServiceProvider),
    Supabase.instance.client,
  );
});

final usersStreamProvider = StreamProvider.autoDispose<List<UserProfile>>((
  ref,
) {
  final repository = ref.watch(usersRepositoryProvider);
  return repository.getUsers();
});

class UsersRepository {
  final OfflineService _offlineService;
  final SupabaseClient _supabase;

  UsersRepository(this._offlineService, this._supabase);

  Stream<List<UserProfile>> getUsers() async* {
    // 1. Emit cached data immediately
    final localUsers = _offlineService.getUsers();
    if (localUsers.isNotEmpty) {
      yield localUsers;
    }

    // 2. Fetch from Network
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('full_name', ascending: true);

      final users = (response as List)
          .map((e) => UserProfile.fromJson(e))
          .toList();

      // 3. Update Cache
      await _offlineService.saveUsers(users);

      // 4. Yield fresh data
      yield users;
    } catch (e) {
      if (localUsers.isEmpty) {
        rethrow;
      }
    }
  }
}
