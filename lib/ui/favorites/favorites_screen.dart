import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munokolive_music/models/favorite_model.dart';
import 'package:munokolive_music/providers/favorites_provider.dart';
import '../../services/favorites_service.dart';
import '../../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/skeleton_loader.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(userFavoritesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'Mes Favoris',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.place), text: 'Lieux'),
            Tab(icon: Icon(Icons.event), text: 'Événements'),
            Tab(icon: Icon(Icons.people), text: 'Contacts'),
          ],
        ),
      ),
      body: favoritesAsync.when(
        data: (favorites) {
          final places = favorites
              .where((f) => f.type == FavoriteType.place)
              .toList();
          final events = favorites
              .where((f) => f.type == FavoriteType.event)
              .toList();
          final users = favorites
              .where((f) => f.type == FavoriteType.user)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildFavoritesList(
                favorites: places,
                type: FavoriteType.place,
                emptyMessage: 'Aucun lieu favori',
              ),
              _buildFavoritesList(
                favorites: events,
                type: FavoriteType.event,
                emptyMessage: 'Aucun événement favori',
              ),
              _buildFavoritesList(
                favorites: users,
                type: FavoriteType.user,
                emptyMessage: 'Aucun contact favori',
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Erreur: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesList({
    required List<FavoriteModel> favorites,
    required FavoriteType type,
    required String emptyMessage,
  }) {
    if (favorites.isEmpty) {
      return EmptyStateWidget(
        icon: type == FavoriteType.place
            ? Icons.place_outlined
            : type == FavoriteType.event
            ? Icons.event_outlined
            : Icons.people_outlined,
        title: emptyMessage,
        message: 'Ajoutez des favoris pour les retrouver facilement',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        return _buildFavoriteTile(favorite, type);
      },
    );
  }

  Widget _buildFavoriteTile(FavoriteModel favorite, FavoriteType type) {
    return FutureBuilder(
      future: _getFavoriteItem(favorite, type),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: SkeletonLoader(width: double.infinity, height: 80),
          );
        }

        final item = snapshot.data;
        if (item == null) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.white.withValues(alpha: 0.05),
          child: ListTile(
            leading: _buildFavoriteLeading(item, type),
            title: Text(
              _getFavoriteTitle(item, type),
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              _getFavoriteSubtitle(item, type),
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: AppTheme.primaryColor),
              onPressed: () => _removeFavorite(favorite),
            ),
            onTap: () => _navigateToFavorite(item, type),
          ),
        );
      },
    );
  }

  Future<dynamic> _getFavoriteItem(
    FavoriteModel favorite,
    FavoriteType type,
  ) async {
    // Cette méthode devrait récupérer les données réelles depuis Firestore
    // Pour l'instant, on utilise les metadata si disponibles
    return favorite.metadata ?? {};
  }

  String _getFavoriteTitle(dynamic item, FavoriteType type) {
    if (item is Map) {
      return item['name'] ?? item['title'] ?? 'Inconnu';
    }
    return 'Inconnu';
  }

  String _getFavoriteSubtitle(dynamic item, FavoriteType type) {
    if (item is Map) {
      return item['location'] ?? item['city'] ?? '';
    }
    return '';
  }

  Widget _buildFavoriteLeading(dynamic item, FavoriteType type) {
    // Placeholder pour l'image
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        type == FavoriteType.place
            ? Icons.place
            : type == FavoriteType.event
            ? Icons.event
            : Icons.person,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Future<void> _removeFavorite(FavoriteModel favorite) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    await ref
        .read(favoritesServiceProvider)
        .removeFavorite(
          userId: user.uid,
          type: favorite.type,
          itemId: favorite.itemId,
        );
  }

  void _navigateToFavorite(dynamic item, FavoriteType type) {
    // Navigation vers la page de détails
    // À implémenter selon votre structure
  }
}
