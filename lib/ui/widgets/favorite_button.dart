import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/favorites_service.dart';
import '../../models/favorite_model.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/user_provider.dart';
import '../theme/app_theme.dart';

/// Bouton favori réutilisable
class FavoriteButton extends ConsumerStatefulWidget {
  final FavoriteType type;
  final String itemId;
  final Map<String, dynamic>? metadata;
  final Color? color;

  const FavoriteButton({
    super.key,
    required this.type,
    required this.itemId,
    this.metadata,
    this.color,
  });

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton> {
  bool _isLoading = false;

  Future<void> _toggleFavorite() async {
    final userAsync = ref.read(authStateProvider);
    final user = userAsync.value;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final favoritesService = ref.read(favoritesServiceProvider);
      final isFavorite = await favoritesService.isFavorite(
        userId: user.uid,
        type: widget.type,
        itemId: widget.itemId,
      );

      if (isFavorite) {
        await favoritesService.removeFavorite(
          userId: user.uid,
          type: widget.type,
          itemId: widget.itemId,
        );
      } else {
        await favoritesService.addFavorite(
          userId: user.uid,
          type: widget.type,
          itemId: widget.itemId,
          metadata: widget.metadata,
        );
      }

      // Invalidate provider to refresh UI
      ref.invalidate(userFavoritesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.value;
    if (user == null) return const SizedBox.shrink();

    final isFavoriteAsync = ref.watch(
      isFavoriteProvider(
        FavoriteCheckParams(type: widget.type, itemId: widget.itemId),
      ),
    );

    return isFavoriteAsync.when(
      data: (isFavorite) => IconButton(
        icon: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite
                    ? (widget.color ?? AppTheme.primaryColor)
                    : (widget.color ?? Colors.white),
              ),
        onPressed: _isLoading ? null : _toggleFavorite,
        tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
      ),
      loading: () => const IconButton(
        icon: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        onPressed: null,
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
