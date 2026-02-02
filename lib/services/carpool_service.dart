/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/carpool_model.dart';

final carpoolServiceProvider = Provider<CarpoolService>((ref) {
  return CarpoolService(Supabase.instance.client);
});

class CarpoolService {
  final SupabaseClient _supabase;

  CarpoolService(this._supabase);

  // Get carpools for a specific event
  Future<List<CarpoolOffer>> getCarpoolsForEvent(String eventId) async {
    try {
      final response = await _supabase
          .from('carpools')
          .select()
          .eq('event_id', eventId)
          .gt('departure_time', DateTime.now().toIso8601String())
          .gt('available_seats', 0); // Only show available rides

      return (response as List).map((data) => CarpoolOffer.fromMap(data)).toList();
    } catch (e) {
      // Return empty list or rethrow depending on needs.
      // For now, logging would be good but we keep it simple.
      return [];
    }
  }

  // Create a new carpool offer
  Future<void> createCarpoolOffer(CarpoolOffer offer) async {
    await _supabase.from('carpools').insert(offer.toMap());
  }

  // Book a seat (simple decrement for now, ideally transaction + passengers table)
  Future<bool> bookSeat(String carpoolId) async {
    try {
      // This is a simplified logic. In real app, use RPC or transaction.
      await _supabase.rpc('book_carpool_seat', params: {'carpool_id': carpoolId});
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Cancel a carpool
  Future<void> deleteCarpool(String carpoolId) async {
     await _supabase.from('carpools').delete().eq('id', carpoolId);
  }
}
