import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:munokolive_music/models/place_model.dart';
import 'package:munokolive_music/services/place_service.dart';
import 'package:munokolive_music/ui/places/add_place_page.dart';
import 'package:munokolive_music/ui/places/place_details_page.dart';
import '../../providers/app_state_providers.dart';
import '../../ui/theme/app_theme.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/animations.dart';
import '../widgets/cached_image_widget.dart';
import '../../services/analytics_service.dart';

class PlacesScreen extends ConsumerStatefulWidget {
  const PlacesScreen({super.key});

  @override
  ConsumerState<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends ConsumerState<PlacesScreen> {
  final TextEditingController _searchController = TextEditingController();
  PlaceCategory? _selectedCategory;
  String _searchQuery = '';
  bool _showSearchFilters = false;
  bool _filterAroundMe = false;
  double _radiusKm = 10.0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myLoc = ref.watch(userLocationProvider);
    final placesAsync = ref.watch(approvedPlacesProvider);

    // Analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logScreenView(screenName: 'places');
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Nos Lieux'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showSearchFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () =>
                setState(() => _showSearchFilters = !_showSearchFilters),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.pushWithTransition(const AddPlacePage());
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_location_alt),
        label: const Text("Ajouter un lieu"),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Column(
          children: [
            SizedBox(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GlassmorphicContainer(
                width: double.infinity,
                height: 50,
                borderRadius: 25,
                blur: 10,
                alignment: Alignment.center,
                border: 1,
                linearGradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderGradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.5),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: "Rechercher (Ville, Quartier...)",
                    hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.search, color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ),

            // Category Filters (Clusters)
            if (_showSearchFilters)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: PlaceCategory.values.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      String label = '';
                      IconData icon = Icons.place;
                      switch (cat) {
                        case PlaceCategory.studio:
                          label = 'Studios';
                          icon = Icons.mic;
                          break;
                        case PlaceCategory.rehearsalRoom:
                          label = 'Répétition';
                          icon = Icons.music_note;
                          break;
                        case PlaceCategory.eventSpace:
                          label = 'Événements';
                          icon = Icons.event;
                          break;
                        case PlaceCategory.trainingRoom:
                          label = 'Formation';
                          icon = Icons.school;
                          break;
                        case PlaceCategory.other:
                          label = 'Autre';
                          icon = Icons.category;
                          break;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Row(
                            children: [
                              Icon(
                                icon,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(label),
                            ],
                          ),
                          onSelected: (val) => setState(
                            () => _selectedCategory = val ? cat : null,
                          ),
                          backgroundColor: Colors.black45,
                          selectedColor: AppTheme.primaryColor,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            if (_showSearchFilters)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GlassmorphicContainer(
                  width: double.infinity,
                  height: _filterAroundMe ? 140 : 60,
                  borderRadius: 20,
                  blur: 10,
                  alignment: Alignment.center,
                  border: 1,
                  linearGradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  borderGradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SwitchListTile(
                        title: const Row(
                          children: [
                            Icon(Icons.radar, color: AppTheme.secondaryColor),
                            SizedBox(width: 12),
                            Text(
                              "Autour de moi",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        value: _filterAroundMe,
                        onChanged: (val) {
                          setState(() => _filterAroundMe = val);
                        },
                        activeThumbColor: AppTheme.secondaryColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                      if (_filterAroundMe)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Rayon",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  Text(
                                    "${_radiusKm.round()} km",
                                    style: const TextStyle(
                                      color: AppTheme.secondaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _radiusKm,
                                min: 1,
                                max: 50,
                                divisions: 49,
                                activeColor: AppTheme.secondaryColor,
                                inactiveColor: Colors.white24,
                                onChanged: (val) =>
                                    setState(() => _radiusKm = val),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // List
            Expanded(
              child: placesAsync.when(
                loading: () => SkeletonList(
                  itemCount: 5,
                  itemBuilder: (context, index) => const PlaceCardSkeleton(),
                ),
                error: (error, stack) => ErrorStateWidget(
                  message: ErrorHandler.getErrorMessage(error),
                  onRetry: () => ref.invalidate(approvedPlacesProvider),
                ),
                data: (places) {
                  // Filter
                  final filtered = places.where((p) {
                    // Category Filter
                    if (_selectedCategory != null &&
                        p.category != _selectedCategory) {
                      return false;
                    }

                    // Distance Filter
                    if (_filterAroundMe) {
                      if (myLoc == null || p.coordinates == null) {
                        return false; // Hide if no loc data
                      }
                      final distMeters = Geolocator.distanceBetween(
                        myLoc.latitude,
                        myLoc.longitude,
                        p.coordinates!.latitude,
                        p.coordinates!.longitude,
                      );
                      if (distMeters / 1000 > _radiusKm) return false;
                    }

                    // Search Query
                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      return p.name.toLowerCase().contains(q) ||
                          p.city.toLowerCase().contains(q) ||
                          p.commune.toLowerCase().contains(q) ||
                          p.neighborhood.toLowerCase().contains(q);
                    }

                    return true;
                  }).toList();

                  // Sort by distance if "Around Me" is active
                  if (_filterAroundMe && myLoc != null) {
                    filtered.sort((a, b) {
                      if (a.coordinates == null || b.coordinates == null) {
                        return 0;
                      }
                      final distA = Geolocator.distanceBetween(
                        myLoc.latitude,
                        myLoc.longitude,
                        a.coordinates!.latitude,
                        a.coordinates!.longitude,
                      );
                      final distB = Geolocator.distanceBetween(
                        myLoc.latitude,
                        myLoc.longitude,
                        b.coordinates!.latitude,
                        b.coordinates!.longitude,
                      );
                      return distA.compareTo(distB);
                    });
                  }

                  if (filtered.isEmpty) {
                    if (_searchQuery.isNotEmpty ||
                        _selectedCategory != null ||
                        _filterAroundMe) {
                      return EmptyStateWidget(
                        icon: Icons.search_off,
                        title: 'Aucun résultat',
                        message: _searchQuery.isNotEmpty
                            ? 'Aucun lieu ne correspond à "$_searchQuery".'
                            : 'Aucun lieu ne correspond à vos filtres.',
                      );
                    }
                    return EmptyStates.places();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                      bottom: 100,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final place = filtered[index];
                      double? distance;
                      if (myLoc != null && place.coordinates != null) {
                        distance = Geolocator.distanceBetween(
                          myLoc.latitude,
                          myLoc.longitude,
                          place.coordinates!.latitude,
                          place.coordinates!.longitude,
                        );
                      }

                      return GestureDetector(
                        onTap: () {
                          context.pushWithTransition(
                            PlaceDetailsPage(place: place),
                          );
                        },
                        child: GlassmorphicContainer(
                          width: double.infinity,
                          height: 110,
                          borderRadius: 15,
                          blur: 10,
                          alignment: Alignment.center,
                          border: 1,
                          linearGradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                          ),
                          borderGradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.5),
                              Colors.white.withValues(alpha: 0.1),
                            ],
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  bottomLeft: Radius.circular(15),
                                ),
                                child: place.images.isNotEmpty
                                    ? CachedImageWidget(
                                        imageUrl: place.images.first,
                                        width: 110,
                                        height: 110,
                                        fit: BoxFit.cover,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(15),
                                          bottomLeft: Radius.circular(15),
                                        ),
                                      )
                                    : Container(
                                        width: 110,
                                        height: 110,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(15),
                                            bottomLeft: Radius.circular(15),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.place,
                                          color: AppTheme.primaryColor,
                                          size: 40,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            place.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (place.isVerified)
                                                const Icon(
                                                  Icons.verified,
                                                  color: Colors.blueAccent,
                                                  size: 12,
                                                ),
                                              if (place.isVerified)
                                                const SizedBox(width: 4),
                                              Text(
                                                place.categoryLabel,
                                                style: const TextStyle(
                                                  color: AppTheme.primaryColor,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 12,
                                            color: Colors.white54,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              "${place.city}, ${place.neighborhood}",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (distance != null)
                                        Text(
                                          'À ${(distance / 1000).toStringAsFixed(1)} km',
                                          style: const TextStyle(
                                            color: Colors.greenAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(right: 16.0),
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white30,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
