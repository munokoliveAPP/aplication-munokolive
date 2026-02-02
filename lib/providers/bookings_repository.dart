import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munokolive_music/services/auth_service.dart';
import '../models/booking_model.dart';

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  return BookingsRepository(Supabase.instance.client);
});

// Stream des réservations en tant que Client
final clientBookingsStreamProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return const Stream.empty();

  return Supabase.instance.client
      .from('bookings')
      .stream(primaryKey: ['id'])
      .eq('client_id', user.id)
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => BookingModel.fromJson(json)).toList());
});

// Stream des réservations en tant que Prestataire
final providerBookingsStreamProvider = StreamProvider<List<BookingModel>>((
  ref,
) {
  // Force refresh on auth change (Token Refresh)
  ref.watch(authStateProvider);

  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return const Stream.empty();

  return Supabase.instance.client
      .from('bookings')
      .stream(primaryKey: ['id'])
      .eq('provider_id', user.id)
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => BookingModel.fromJson(json)).toList());
});

class BookingsRepository {
  final SupabaseClient _supabase;

  BookingsRepository(this._supabase);

  // Créer une demande
  Future<void> createBooking({
    required String providerId,
    String? serviceId,
    required DateTime bookingDate,
    String? locationName,
    double? latitude,
    double? longitude,
    double? totalPrice,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw "Vous devez être connecté";

    await _supabase.from('bookings').insert({
      'client_id': user.id,
      'provider_id': providerId,
      'service_id': serviceId,
      'booking_date': bookingDate.toIso8601String(),
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'total_price': totalPrice,
      'status': 'pending',
    });
  }

  // Mettre à jour le statut (Accepter, Refuser, En Route, Terminé)
  Future<void> updateStatus(String bookingId, BookingStatus status) async {
    await _supabase
        .from('bookings')
        .update({
          'status': BookingModel.statusToString(status),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', bookingId);
  }
}
