import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/search_service.dart';
import '../services/smart_cache_service.dart';
import 'dart:async';

final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService();
});

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
      return SearchHistoryNotifier(ref.read(smartCacheServiceProvider));
    });

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  final SmartCacheService _cache;
  static const String _cacheKey = 'search_history';

  SearchHistoryNotifier(this._cache) : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _cache.get<List<dynamic>>(_cacheKey);
    if (history != null) {
      state = history.cast<String>();
    }
  }

  Future<void> addToHistory(String query) async {
    if (query.trim().isEmpty) return;

    final normalizedQuery = query.trim();
    final updated =
        [normalizedQuery, ...state.where((item) => item != normalizedQuery)]
            .take(20) // Limiter à 20 éléments
            .toList();

    state = updated;
    await _cache.save(_cacheKey, updated, expiration: const Duration(days: 30));
  }

  void clearHistory() {
    state = [];
    _cache.invalidate(_cacheKey);
  }
}

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<SearchResults>((
  ref,
) async {
  final query = ref.watch(searchQueryProvider);
  final searchService = ref.read(searchServiceProvider);

  if (query.trim().isEmpty) {
    return SearchResults.empty();
  }

  // Debounce avec délai
  await Future.delayed(const Duration(milliseconds: 300));

  // Vérifier que la query n'a pas changé
  final currentQuery = ref.read(searchQueryProvider);
  if (currentQuery != query) {
    throw Exception('Query changed');
  }

  return searchService.searchAll(query);
});
