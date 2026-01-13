import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/favorite_model.dart';
import '../services/favorites_service.dart';
import '../services/auth_service.dart';

/// Provider pour les favoris de l'utilisateur actuel
final userFavoritesProvider = StreamProvider<List<FavoriteModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  final favoritesService = ref.read(favoritesServiceProvider);
  return favoritesService.getUserFavorites(user.uid);
});

/// Provider pour vérifier si un item est en favori
final isFavoriteProvider = FutureProvider.family<bool, FavoriteCheckParams>((
  ref,
  params,
) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return false;

  final favoritesService = ref.read(favoritesServiceProvider);
  return favoritesService.isFavorite(
    userId: user.uid,
    type: params.type,
    itemId: params.itemId,
  );
});

class FavoriteCheckParams {
  final FavoriteType type;
  final String itemId;

  FavoriteCheckParams({required this.type, required this.itemId});
}

/// Provider pour les favoris par type
final favoritesByTypeProvider =
    StreamProvider.family<List<FavoriteModel>, FavoriteType>((ref, type) {
      final user = ref.watch(authStateProvider).value;
      if (user == null) return Stream.value([]);

      final favoritesService = ref.read(favoritesServiceProvider);
      return favoritesService.getFavoritesByType(user.uid, type);
    });
