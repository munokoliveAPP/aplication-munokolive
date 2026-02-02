import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munokolive_music/models/urgent_request_model.dart';

/// Repository for handling Urgent Requests (CRUD)
class UrgentRequestsRepository {
  final SupabaseClient _supabase;

  UrgentRequestsRepository(this._supabase);

  /// Creates a new urgent request
  Future<UrgentRequest> createRequest(UrgentRequest request) async {
    final response = await _supabase
        .from('urgent_requests')
        .insert(request.toJson())
        .select()
        .single();
    return UrgentRequest.fromJson(response);
  }

  /// Updates status of a request (e.g. broadcasted, cancelled)
  Future<void> updateStatus(String requestId, String newStatus) async {
    await _supabase
        .from('urgent_requests')
        .update({'status': newStatus})
        .eq('id', requestId);
  }

  /// Get a single request by ID
  Future<UrgentRequest?> getRequest(String requestId) async {
    try {
      final response = await _supabase
          .from('urgent_requests')
          .select()
          .eq('id', requestId)
          .single();

      // Note: We could fetch assignedUser here if the model supported it.
      // For now, we just return the request.

      return UrgentRequest.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Fetches active requests (for admin dashboard)
  /// Real-time stream is handled by the provider below
}

// --- Providers ---

final urgentRequestsRepositoryProvider = Provider((ref) {
  return UrgentRequestsRepository(Supabase.instance.client);
});

/// Stream of ALL urgent requests (for Admin Dashboard)
/// Joins with user table to get requester details
final adminUrgentRequestsStreamProvider = StreamProvider<List<UrgentRequest>>((
  ref,
) {
  return Supabase.instance.client
      .from('urgent_requests')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .asyncMap((data) async {
        if (data.isEmpty) return <UrgentRequest>[];

        // 1. Extract IDs
        final userIds = data
            .map((e) => e['requester_id'] as String?)
            .where((id) => id != null)
            .toSet()
            .toList();

        if (userIds.isEmpty) {
          return data.map((json) => UrgentRequest.fromJson(json)).toList();
        }

        try {
          // 2. Fetch Users
          final usersResponse = await Supabase.instance.client
              .from('users')
              .select('id, first_name, last_name, photo_url, phone_number')
              .filter('id', 'in', userIds);

          final List<dynamic> usersList = usersResponse as List<dynamic>;

          // 3. Create Lookup
          final userMap = {for (var u in usersList) u['id'] as String: u};

          // 4. Merge and Map
          return data.map((json) {
            final userId = json['requester_id'] as String?;
            if (userId != null && userMap.containsKey(userId)) {
              // Create a mutable copy with 'users' field for fromJson to consume
              final newJson = Map<String, dynamic>.from(json);
              newJson['users'] = userMap[userId];
              return UrgentRequest.fromJson(newJson);
            }
            return UrgentRequest.fromJson(json);
          }).toList();
        } catch (e) {
          // Fallback if user fetch fails
          return data.map((json) => UrgentRequest.fromJson(json)).toList();
        }
      });
});

/// Helper provider to fetch user details for a specific request
/// (Used in the UI to show who is asking)
final requestUserProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
      final supabase = Supabase.instance.client;
      try {
        final response = await supabase
            .from('users')
            .select('first_name, last_name, photo_url, phone_number')
            .eq('id', userId)
            .single();
        return response;
      } catch (e) {
        return null;
      }
    });
