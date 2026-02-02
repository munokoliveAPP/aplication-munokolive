import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:munokolive_music/models/location_model.dart';
import 'package:munokolive_music/providers/locations_repository.dart';
import 'package:munokolive_music/providers/user_location_provider.dart';

// 1. Filter Providers
final placesCategoryProvider = StateProvider<String>((ref) => "Tous");
final placesSearchQueryProvider = StateProvider<String>((ref) => "");

// 2. User Location Provider (Imported from shared provider)
// See: lib/providers/user_location_provider.dart

// 3. Computed Provider (The "Brain")
final filteredPlacesProvider = Provider<AsyncValue<List<LocationModel>>>((ref) {
  // Watch all dependencies
  final allPlacesAsync = ref.watch(locationsStreamProvider);
  final category = ref.watch(placesCategoryProvider);
  final searchQuery = ref.watch(placesSearchQueryProvider).toLowerCase();
  final userLocationAsync = ref.watch(userLocationProvider);

  return allPlacesAsync.whenData((places) {
    // A. Filtering
    var filtered = places.where((place) {
      // Search
      if (searchQuery.isNotEmpty) {
        final name = place.name.toLowerCase();
        final address = (place.address ?? '').toLowerCase();
        if (!name.contains(searchQuery) && !address.contains(searchQuery)) {
          return false;
        }
      }

      // Category
      if (category != "Tous") {
        if (place.category.trim().toLowerCase() != category.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();

    // B. Sorting (if we have location)
    userLocationAsync.whenData((position) {
      filtered.sort((a, b) {
        if (a.latitude == null || a.longitude == null) return 1;
        if (b.latitude == null || b.longitude == null) return -1;

        final distA = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          a.latitude!,
          a.longitude!,
        );
        final distB = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          b.latitude!,
          b.longitude!,
        );
        return distA.compareTo(distB);
      });
    });

    return filtered;
  });
});
