import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/favorite_model.dart';

final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FavoritesService();
});

/// Service de gestion des favoris
class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupérer tous les favoris d'un utilisateur
  Stream<List<FavoriteModel>> getUserFavorites(String userId) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return FavoriteModel.fromJson(data);
          }).toList();
        });
  }

  /// Récupérer les favoris par type
  Stream<List<FavoriteModel>> getFavoritesByType(
    String userId,
    FavoriteType type,
  ) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return FavoriteModel.fromJson(data);
          }).toList();
        });
  }

  /// Ajouter un favori
  Future<void> addFavorite({
    required String userId,
    required FavoriteType type,
    required String itemId,
    Map<String, dynamic>? metadata,
  }) async {
    final favorite = FavoriteModel(
      id: '', // Will be set by Firestore
      userId: userId,
      type: type,
      itemId: itemId,
      createdAt: DateTime.now(),
      metadata: metadata,
    );

    // Vérifier si déjà en favori
    final existing = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.name)
        .where('itemId', isEqualTo: itemId)
        .get();

    if (existing.docs.isEmpty) {
      await _firestore.collection('favorites').add(favorite.toJson());
    }
  }

  /// Retirer un favori
  Future<void> removeFavorite({
    required String userId,
    required FavoriteType type,
    required String itemId,
  }) async {
    final favorites = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.name)
        .where('itemId', isEqualTo: itemId)
        .get();

    for (var doc in favorites.docs) {
      await doc.reference.delete();
    }
  }

  /// Vérifier si un item est en favori
  Future<bool> isFavorite({
    required String userId,
    required FavoriteType type,
    required String itemId,
  }) async {
    final favorites = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.name)
        .where('itemId', isEqualTo: itemId)
        .limit(1)
        .get();

    return favorites.docs.isNotEmpty;
  }

  /// Compter les favoris d'un utilisateur
  Future<int> getFavoriteCount(String userId, FavoriteType? type) async {
    var query = _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }
}
