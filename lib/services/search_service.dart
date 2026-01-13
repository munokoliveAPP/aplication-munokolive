import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place_model.dart';
import '../models/event_model.dart';
import '../models/user_profile.dart';

/// Service de recherche globale pour l'application
class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Recherche unifiée dans tous les types de contenu
  Future<SearchResults> searchAll(String query) async {
    if (query.trim().isEmpty) {
      return SearchResults.empty();
    }

    final normalizedQuery = query.toLowerCase().trim();

    // Recherches parallèles
    final results = await Future.wait([
      _searchPlaces(normalizedQuery),
      _searchEvents(normalizedQuery),
      _searchUsers(normalizedQuery),
    ]);

    return SearchResults(
      places: results[0] as List<PlaceModel>,
      events: results[1] as List<EventModel>,
      users: results[2] as List<UserProfile>,
    );
  }

  /// Recherche dans les lieux
  Future<List<PlaceModel>> _searchPlaces(String query) async {
    try {
      // Recherche par nom
      final nameQuery = _firestore
          .collection('places')
          .where('status', isEqualTo: 'approved')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .limit(10)
          .get();

      // Recherche par ville
      final cityQuery = _firestore
          .collection('places')
          .where('status', isEqualTo: 'approved')
          .where('city', isGreaterThanOrEqualTo: query)
          .where('city', isLessThan: '${query}z')
          .limit(10)
          .get();

      final results = await Future.wait([nameQuery, cityQuery]);
      final allDocs = <QueryDocumentSnapshot>[];

      for (var snapshot in results) {
        allDocs.addAll(snapshot.docs);
      }

      // Dédupliquer par ID
      final uniqueDocs = <String, QueryDocumentSnapshot>{};
      for (var doc in allDocs) {
        uniqueDocs[doc.id] = doc;
      }

      return uniqueDocs.values
          .map((doc) => PlaceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Recherche dans les événements
  Future<List<EventModel>> _searchEvents(String query) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('status', isEqualTo: 'approved')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '${query}z')
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return EventModel.fromJson(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Recherche dans les utilisateurs
  Future<List<UserProfile>> _searchUsers(String query) async {
    try {
      // Recherche par prénom
      final firstNameQuery = _firestore
          .collection('users')
          .where('status', isEqualTo: 'active')
          .where('firstName', isGreaterThanOrEqualTo: query)
          .where('firstName', isLessThan: '${query}z')
          .limit(10)
          .get();

      // Recherche par nom
      final lastNameQuery = _firestore
          .collection('users')
          .where('status', isEqualTo: 'active')
          .where('lastName', isGreaterThanOrEqualTo: query)
          .where('lastName', isLessThan: '${query}z')
          .limit(10)
          .get();

      final results = await Future.wait([firstNameQuery, lastNameQuery]);
      final allDocs = <QueryDocumentSnapshot>[];

      for (var snapshot in results) {
        allDocs.addAll(snapshot.docs);
      }

      // Dédupliquer
      final uniqueDocs = <String, QueryDocumentSnapshot>{};
      for (var doc in allDocs) {
        uniqueDocs[doc.id] = doc;
      }

      return uniqueDocs.values
          .map(
            (doc) => UserProfile.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Recherche avec suggestions (fuzzy search côté client)
  List<String> getSuggestions(String query, List<String> history) {
    if (query.isEmpty) {
      return history.take(5).toList();
    }

    final normalizedQuery = query.toLowerCase();
    return history
        .where((item) => item.toLowerCase().contains(normalizedQuery))
        .take(5)
        .toList();
  }
}

/// Résultats de recherche
class SearchResults {
  final List<PlaceModel> places;
  final List<EventModel> events;
  final List<UserProfile> users;

  SearchResults({
    required this.places,
    required this.events,
    required this.users,
  });

  factory SearchResults.empty() {
    return SearchResults(places: [], events: [], users: []);
  }

  bool get isEmpty => places.isEmpty && events.isEmpty && users.isEmpty;

  int get totalCount => places.length + events.length + users.length;
}
