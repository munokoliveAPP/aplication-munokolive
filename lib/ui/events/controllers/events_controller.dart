import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munokolive_music/models/event_model.dart';
import 'package:munokolive_music/providers/events_repository.dart';

// 1. Filter Providers
final eventsCategoryProvider = StateProvider<String>((ref) => "Tous");
final eventsSearchQueryProvider = StateProvider<String>((ref) => "");

// 2. Computed Provider (The "Brain")
final filteredEventsProvider = Provider<AsyncValue<List<EventModel>>>((ref) {
  final allEventsAsync = ref.watch(eventsStreamProvider);
  final category = ref.watch(eventsCategoryProvider);
  final searchQuery = ref.watch(eventsSearchQueryProvider).toLowerCase();

  // We don't necessarily need to watch userLocation here for *filtering*,
  // but if we wanted to sort by distance we would.
  // For events, Date is usually King. We'll stick to Date sorting (handled by DB/Repo),
  // but we filter here.

  return allEventsAsync.whenData((events) {
    final now = DateTime.now();
    final cutoffDate = now.subtract(const Duration(days: 3));

    return events.where((event) {
      // 1. Date Filter (Keep recent past events for 3 days, and future events)
      if (event.eventDate.isBefore(cutoffDate)) return false;

      // 2. Category Filter
      if (category != "Tous") {
        final eventCategory = (event.category ?? '').trim().toLowerCase();
        final filterCategory = category.trim().toLowerCase();

        if (eventCategory != filterCategory) {
          // Fallback for accents (prière vs priere)
          if (filterCategory.contains('prière') &&
              eventCategory.contains('priere')) {
            // Match!
          } else {
            return false;
          }
        }
      }

      // 3. Search Filter
      if (searchQuery.isNotEmpty) {
        final title = event.name.toLowerCase();
        final location = (event.locationName ?? '').toLowerCase();
        final desc = (event.description ?? '').toLowerCase();

        if (!title.contains(searchQuery) &&
            !location.contains(searchQuery) &&
            !desc.contains(searchQuery)) {
          return false;
        }
      }

      return true;
    }).toList();
  });
});
