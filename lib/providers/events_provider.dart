import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../models/user_profile.dart';
import '../services/event_service.dart';
import 'user_provider.dart';

// Filter State
class EventFilter {
  final String category; // 'All', 'Concert', 'Répétition', etc.
  final DateTime? date;
  final bool showPast;

  EventFilter({this.category = 'All', this.date, this.showPast = false});

  EventFilter copyWith({String? category, DateTime? date, bool? showPast}) {
    return EventFilter(
      category: category ?? this.category,
      date: date ?? this.date,
      showPast: showPast ?? this.showPast,
    );
  }
}

final eventFilterProvider = StateProvider<EventFilter>((ref) => EventFilter());

// Real Data Stream
final eventsStreamProvider = StreamProvider<List<EventModel>>((ref) {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getEvents();
});

// Pulse Algorithm Logic
final filteredEventsProvider = Provider<AsyncValue<List<EventModel>>>((ref) {
  final eventsAsync = ref.watch(eventsStreamProvider);
  final filter = ref.watch(eventFilterProvider);
  final currentUserAsync = ref.watch(
    userProfileProvider,
  ); // Need user profile for Smart Matching

  return eventsAsync.whenData((events) {
    var filtered = events;
    final now = DateTime.now();
    final user = currentUserAsync.value;

    // 0. Security/Validation Filter
    // Only show 'approved' events unless user is admin
    final bool isAdmin =
        user != null &&
        (user.status == 'admin' || user.status == 'validated_admin');

    if (!isAdmin) {
      filtered = filtered.where((e) => e.status == 'approved').toList();
    }

    // 1. Auto-Hygiene (Pulse Clean)
    // Remove events where End Date (Start + 2h) is passed by 1 minute
    if (!filter.showPast) {
      filtered = filtered.where((e) {
        final endDate = e.date.add(
          const Duration(hours: 2),
        ); // Assume 2h duration
        final hygieneThreshold = endDate.add(const Duration(minutes: 1));
        return now.isBefore(hygieneThreshold);
      }).toList();
    }

    // Filter by Category
    if (filter.category != 'All') {
      filtered = filtered.where((e) => e.category == filter.category).toList();
    }

    // Filter by Date
    if (filter.date != null) {
      filtered = filtered.where((e) {
        return e.date.year == filter.date!.year &&
            e.date.month == filter.date!.month &&
            e.date.day == filter.date!.day;
      }).toList();
    }

    // 2. Smart Matching & Sorting (The "Pulse")
    // If we have a user profile, we calculate a score.
    // 'user' is already defined above, no need to redeclare

    filtered.sort((a, b) {
      double scoreA = _calculatePulseScore(a, user, now);
      double scoreB = _calculatePulseScore(b, user, now);

      // Sort by Score Descending first
      int scoreComparison = scoreB.compareTo(scoreA);
      if (scoreComparison != 0) return scoreComparison;

      // Then by Date Ascending (Sooner first)
      return a.date.compareTo(b.date);
    });

    return filtered;
  });
});

// Helper: Calculate Pulse Score
double _calculatePulseScore(EventModel event, UserProfile? user, DateTime now) {
  double score = 0.0;

  // A. Recency / Urgency (Live events are top priority)
  final endDate = event.date.add(const Duration(hours: 2));
  bool isLive = now.isAfter(event.date) && now.isBefore(endDate);
  if (isLive) score += 500; // Massive boost for live events

  final hoursUntil = event.date.difference(now).inHours;
  if (hoursUntil > 0 && hoursUntil < 24) score += 50; // Boost for "Today"
  if (hoursUntil > 0 && hoursUntil < 48) score += 20; // Boost for "Tomorrow"

  // B. Social Proof (Heatmap)
  // +1 point per attendee, max 50 points
  int socialScore = event.attendees.length * 2;
  if (socialScore > 50) socialScore = 50;
  score += socialScore;

  // C. Smart Matching (User Interests)
  if (user != null) {
    // 1. Location Match
    if (user.city != null &&
        event.city != null &&
        user.city!.toLowerCase() == event.city!.toLowerCase()) {
      score += 30;
    }

    // 2. Category/Interest Match
    // If event category matches user category (e.g. Musicien -> Concert)
    // Simplified matching logic:
    if (user.category == 'Musicien' &&
        (event.category == 'Concert' || event.category == 'Répétition')) {
      score += 20;
    }
    if (user.category == 'Pasteur' &&
        (event.category == 'Culte' || event.category == 'Conférence')) {
      score += 20;
    }

    // 3. Church Match
    // If user's church is mentioned in description or title (Simple text match)
    if (user.churchName != null &&
        (event.title.contains(user.churchName!) ||
            event.description.contains(user.churchName!))) {
      score += 40;
    }
  }

  return score;
}

// Deprecated: Use pulseEventsProvider instead
final pulseEventsProvider = Provider<AsyncValue<List<EventModel>>>((ref) {
  return ref.watch(filteredEventsProvider);
});
