import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/search_provider.dart';
import '../../services/search_service.dart';
import '../../models/place_model.dart';
import '../../models/event_model.dart';
import '../../models/user_profile.dart';
import '../../ui/profile/user_profile_page.dart';
import '../theme/app_theme.dart';
import '../widgets/cached_image_widget.dart';
import '../places/place_details_page.dart';
import '../events/event_details_page.dart';
import '../widgets/animations.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    ref.read(searchQueryProvider.notifier).state = query;
    if (query.isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).addToHistory(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchHistory = ref.watch(searchHistoryProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Rechercher lieux, événements, contacts...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
          ),
          onChanged: _performSearch,
          onSubmitted: _performSearch,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (searchHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: AppTheme.backgroundDark,
                  builder: (context) => _buildHistorySheet(searchHistory),
                );
              },
            ),
        ],
      ),
      body: _searchController.text.isEmpty
          ? _buildEmptyState(searchHistory)
          : searchResultsAsync.when(
              data: (results) => _buildResults(results),
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

  Widget _buildEmptyState(List<String> history) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (history.isNotEmpty) ...[
          const Text(
            'Recherches récentes',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...history
              .take(5)
              .map(
                (item) => ListTile(
                  leading: const Icon(
                    Icons.history,
                    color: AppTheme.textSecondary,
                  ),
                  title: Text(
                    item,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    _searchController.text = item;
                    _performSearch(item);
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      // Remove from history
                    },
                  ),
                ),
              ),
          const Divider(),
        ],
        const Text(
          'Suggestions',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildSuggestionChip('Lieux près de moi'),
        _buildSuggestionChip('Événements aujourd\'hui'),
        _buildSuggestionChip('Contacts actifs'),
      ],
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ActionChip(
        label: Text(text),
        onPressed: () {
          _searchController.text = text;
          _performSearch(text);
        },
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        labelStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildResults(SearchResults results) {
    if (results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text(
              'Aucun résultat trouvé',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (results.places.isNotEmpty) ...[
          _buildSectionHeader('Lieux', results.places.length),
          ...results.places.map((place) => _buildPlaceTile(place)),
        ],
        if (results.events.isNotEmpty) ...[
          _buildSectionHeader('Événements', results.events.length),
          ...results.events.map((event) => _buildEventTile(event)),
        ],
        if (results.users.isNotEmpty) ...[
          _buildSectionHeader('Contacts', results.users.length),
          ...results.users.map((user) => _buildUserTile(user)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        '$title ($count)',
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPlaceTile(PlaceModel place) {
    return ListTile(
      leading: CachedImageWidget(
        imageUrl: place.images.isNotEmpty ? place.images.first : '',
        width: 50,
        height: 50,
        borderRadius: BorderRadius.circular(8),
      ),
      title: Text(place.name, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        '${place.city}, ${place.neighborhood}',
        style: const TextStyle(color: AppTheme.textSecondary),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.textSecondary,
      ),
      onTap: () {
        context.pushWithTransition(PlaceDetailsPage(place: place));
      },
    );
  }

  Widget _buildEventTile(EventModel event) {
    return ListTile(
      leading: event.imageUrl != null
          ? CachedImageWidget(
              imageUrl: event.imageUrl!,
              width: 50,
              height: 50,
              borderRadius: BorderRadius.circular(8),
            )
          : Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.event, color: Colors.white),
            ),
      title: Text(event.title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        event.location,
        style: const TextStyle(color: AppTheme.textSecondary),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.textSecondary,
      ),
      onTap: () {
        context.pushWithTransition(EventDetailsPage(event: event));
      },
    );
  }

  Widget _buildUserTile(UserProfile user) {
    return ListTile(
      leading: CachedCircleAvatar(
        imageUrl: user.photoUrl,
        fallbackText: user.firstName,
        radius: 25,
      ),
      title: Text(
        '${user.firstName} ${user.lastName}',
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        user.category,
        style: const TextStyle(color: AppTheme.textSecondary),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.textSecondary,
      ),
      onTap: () {
        // Navigate to user profile - UserProfilePage shows current user by default
        // For viewing other users, we'd need to modify UserProfilePage to accept userId
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil de ${user.firstName} ${user.lastName}'),
          ),
        );
        // Navigate to other user's profile
        context.pushWithTransition(UserProfilePage(userId: user.uid));
      },
    );
  }

  Widget _buildHistorySheet(List<String> history) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Historique de recherche',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(searchHistoryProvider.notifier).clearHistory();
                  Navigator.pop(context);
                },
                child: const Text('Effacer'),
              ),
            ],
          ),
          const Divider(),
          ...history.map(
            (item) => ListTile(
              title: Text(item, style: const TextStyle(color: Colors.white)),
              onTap: () {
                _searchController.text = item;
                _performSearch(item);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
