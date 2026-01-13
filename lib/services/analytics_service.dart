import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Service Analytics Firebase
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Loguer un événement
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters != null
            ? Map<String, Object>.from(parameters)
            : null,
      );
    } catch (e) {
      // Silent fail - analytics is not critical
    }
  }

  /// Loguer un écran
  Future<void> logScreenView({required String screenName}) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      // Silent fail
    }
  }

  // Événements spécifiques de l'application

  /// Événement consulté
  Future<void> logEventViewed(String eventId) async {
    await logEvent(name: 'event_viewed', parameters: {'event_id': eventId});
  }

  /// Lieu consulté
  Future<void> logPlaceViewed(String placeId) async {
    await logEvent(name: 'place_viewed', parameters: {'place_id': placeId});
  }

  /// Contact consulté
  Future<void> logContactViewed(String userId) async {
    await logEvent(name: 'contact_viewed', parameters: {'user_id': userId});
  }

  /// Favori ajouté
  Future<void> logFavoriteAdded(String type, String itemId) async {
    await logEvent(
      name: 'favorite_added',
      parameters: {'type': type, 'item_id': itemId},
    );
  }

  /// Recherche effectuée
  Future<void> logSearch(String query) async {
    await logEvent(name: 'search', parameters: {'search_term': query});
  }

  /// Événement créé
  Future<void> logEventCreated(String eventId) async {
    await logEvent(name: 'event_created', parameters: {'event_id': eventId});
  }

  /// Lieu créé
  Future<void> logPlaceCreated(String placeId) async {
    await logEvent(name: 'place_created', parameters: {'place_id': placeId});
  }
}
