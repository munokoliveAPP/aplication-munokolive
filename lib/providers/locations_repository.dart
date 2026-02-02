import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/location_model.dart';
import '../services/offline_service.dart';
import 'offline_provider.dart';

final locationsRepositoryProvider = Provider<LocationsRepository>((ref) {
  return LocationsRepository(
    ref.read(offlineServiceProvider),
    Supabase.instance.client,
  );
});

final locationsStreamProvider = StreamProvider.autoDispose<List<LocationModel>>(
  (ref) {
    final repository = ref.watch(locationsRepositoryProvider);
    return repository.getLocations();
  },
);

class LocationsRepository {
  final OfflineService _offlineService;
  final SupabaseClient _supabase;

  LocationsRepository(this._offlineService, this._supabase);

  Stream<List<LocationModel>> getLocations() async* {
    // 1. Emit cached data immediately
    final localLocations = _offlineService.getLocations();
    if (localLocations.isNotEmpty) {
      yield localLocations;
    }

    // 2. Stream from Network (Real-time)
    try {
      yield* _supabase
          .from('locations')
          .stream(primaryKey: ['id'])
          .eq('is_validated', true)
          .order('created_at', ascending: false)
          .map((data) {
            final locations = data.map((e) => LocationModel.fromJson(e)).toList();
            // 3. Update Cache
            _offlineService.saveLocations(locations);
            return locations;
          });
    } catch (e) {
      // Silent error if offline, we already showed cache
    }
  }
}
