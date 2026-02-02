/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';
import 'controllers/map_controller.dart' as local_map;
import 'package:munokolive_music/providers/user_provider.dart';
import 'package:munokolive_music/ui/widgets/cached_circle_avatar.dart';
import 'package:munokolive_music/services/notification_service.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;
import 'package:munokolive_music/ui/contacts/member_details_page.dart';

import 'package:munokolive_music/ui/widgets/network_aware_widget.dart'; // Added
import 'package:munokolive_music/models/location_model.dart';
import 'package:munokolive_music/ui/places/place_details_page.dart';
import 'package:geolocator/geolocator.dart'; // For Position conversion
import 'package:munokolive_music/ui/widgets/blinking_point.dart'; // Added
import 'package:munokolive_music/l10n/app_localizations.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final Map<String, DateTime> _lastNotificationTimes = {};
  late AnimationController _pulseController;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildFilterChip(
    String filterKey,
    String label,
    IconData icon,
    Color color, {
    Color backgroundColor = Colors.black,
  }) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : backgroundColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _centerOnUser() {
    final state = ref.read(local_map.mapControllerProvider);
    state.whenData((position) {
      _mapController.move(position, 17.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(local_map.mapControllerProvider);
    final nearbyUsersAsync = ref.watch(local_map.nearbyUsersProvider);
    final nearbyLocationsAsync = ref.watch(local_map.nearbyLocationsProvider);
    final currentUserAsync = ref.watch(currentUserProfileProvider);
    const Distance distance = Distance();

    // Listen for new users nearby
    ref.listen(local_map.nearbyUsersProvider, (previous, next) {
      next.whenData((users) {
        final mapState = ref.read(local_map.mapControllerProvider);
        if (!mapState.hasValue) return;

        final currentPos = mapState.value!;
        final myLoc = LatLng(currentPos.latitude, currentPos.longitude);

        for (var user in users) {
          final userId = user['id'];
          // Smart Notification Logic: Anti-Spam (30 mins interval)
          final now = DateTime.now();
          if (_lastNotificationTimes.containsKey(userId)) {
            final lastTime = _lastNotificationTimes[userId]!;
            if (now.difference(lastTime) < const Duration(minutes: 30)) {
              continue; // Skip if notified less than 30 mins ago
            }
          }

          final lat = (user['latitude'] as num).toDouble();
          final lng = (user['longitude'] as num).toDouble();
          final userLoc = LatLng(lat, lng);

          // Check distance (e.g., within 2km)
          if (distance.as(LengthUnit.Meter, myLoc, userLoc) < 2000) {
            _lastNotificationTimes[userId] = now; // Update timestamp

            final name = "${user['first_name']} ${user['last_name']}";
            final category = user['category'] ?? 'Membre';

            final l10n = AppLocalizations.of(context)!;
            ref.read(notificationServiceProvider).showNotification(
                  id: userId.hashCode,
                  title: l10n.nearbyUserTitle(category),
                  body: l10n.nearbyUserBody(name),
                );
          }
        }
      });
    });

    // Build Markers
    List<Marker> markers = [];

    // Current User Marker
    mapState.whenData((position) {
      markers.add(
        Marker(
          width: 80, // Restored size for visibility
          height: 80,
          point: position,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final val = _pulseController.value;
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    // Breathing Pulse Effect
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.6 * (1 - val)),
                      blurRadius: 20 + (val * 20),
                      spreadRadius: 5 + (val * 15),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: currentUserAsync.when(
              data: (user) => user != null
                  ? CachedCircleAvatar(imageUrl: user.photoUrl, radius: 30)
                  : const Icon(
                      Icons.my_location,
                      color: Colors.blueAccent,
                      size: 30,
                    ),
              loading: () => const SizedBox(),
              error: (error, stack) =>
                  const Icon(Icons.my_location, color: Colors.blueAccent),
            ),
          ),
        ),
      );
    });

    // Nearby Users (Filtered by 5km Radius)
    nearbyUsersAsync.whenData((users) {
      mapState.whenData((currentPos) {
        final myLoc = LatLng(currentPos.latitude, currentPos.longitude);

        for (var user in users) {
          final category = user['category'] ?? 'Membre';

          // FILTER LOGIC
          if (_selectedFilter != 'ALL') {
            if (_selectedFilter == 'MUSICIANS' &&
                !category.contains('Chantre') &&
                !category.contains('Musicien')) {
              continue;
            }
            if (_selectedFilter == 'MEN_OF_GOD' &&
                !category.contains('Homme de Dieu') &&
                !category.contains('Pasteur')) {
              continue;
            }
            if (_selectedFilter == 'PLACES') {
              continue; // Hide users if looking for places
            }
          }

          final lat = (user['latitude'] as num).toDouble();
          final lng = (user['longitude'] as num).toDouble();

          // Calculate Distance
          final userLoc = LatLng(lat, lng);
          final km = distance.as(LengthUnit.Kilometer, myLoc, userLoc);

          if (km > 5) continue; // Skip if > 5km

          final isAvailable = user['is_available'] as bool? ?? true;
          final isVisibleOnMap = user['is_visible_on_map'] as bool? ?? false;

          Color color = Colors.purpleAccent;
          IconData iconData = Icons.person;

          if (category.contains('Homme de Dieu') ||
              category.contains('Pasteur')) {
            color = Colors.blue;
            iconData = Icons.auto_awesome; // Étoile scintillante/Sainteté
          } else if (category.contains('Chantre')) {
            color = Colors.pink;
            iconData = Icons.mic; // Micro pour Chantre
          } else if (category.contains('Musicien') ||
              category.contains('Instrumentiste')) {
            color = Colors.pink;
            iconData = Icons.music_note; // Clé de sol/Note pour Musicien
          } else if (category.contains('Pianiste')) {
            color = Colors.pink;
            iconData = Icons.grid_view; // Représentation touches piano
          }

          // Grey out unavailable users
          if (!isAvailable) {
            color = Colors.grey;
          }

          markers.add(
            Marker(
              width: 45,
              height: 45,
              point: LatLng(lat, lng),
              child: GestureDetector(
                onTap: () {
                  if (isVisibleOnMap) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MemberDetailsPage(
                          memberData: user,
                          currentUserPosition: Position(
                            latitude: currentPos.latitude,
                            longitude: currentPos.longitude,
                            timestamp: DateTime.now(),
                            accuracy: 0,
                            altitude: 0,
                            heading: 0,
                            speed: 0,
                            speedAccuracy: 0,
                            altitudeAccuracy: 0,
                            headingAccuracy: 0,
                            isMocked: false,
                          ),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.visibility_off,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.memberNearbyDiscreet,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.grey[800],
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  }
                },
                child: isVisibleOnMap
                    ? CachedCircleAvatar(
                        imageUrl: user['photo_url'],
                        radius: 22,
                        borderColor: color,
                      )
                    : Center(
                        child: BlinkingPoint(
                          color: color,
                          size: 24, // Slightly larger for icon
                          child: Icon(iconData, color: Colors.white, size: 14),
                        ),
                      ),
              ),
            ),
          );
        }
      });
    });

    // Locations
    nearbyLocationsAsync.whenData((locations) {
      if (_selectedFilter != 'Tout' && _selectedFilter != 'Lieux') {
        return; // Hide places if filtering users
      }

      for (var loc in locations) {
        final lat = (loc['latitude'] as num).toDouble();
        final lng = (loc['longitude'] as num).toDouble();
        final category = loc['category'] ?? 'Lieu';

        Color color = Colors.cyanAccent;
        IconData iconData = Icons.place;

        if (category == 'Église') {
          color = Colors.orange;
          iconData = Icons.church;
        } else if (category == "Studio d'enregistrement") {
          color = Colors.deepPurple;
          iconData = Icons.mic;
        } else if (category == 'Salle de répétition') {
          color = Colors.green;
          iconData = Icons.music_note;
        } else if (category == 'Espace événementiel') {
          color = Colors.pinkAccent;
          iconData = Icons.event;
        }

        markers.add(
          Marker(
            width: 45,
            height: 45,
            point: LatLng(lat, lng),
            child: GestureDetector(
              onTap: () {
                // Construct Position from current map center/user location estimate
                // or just pass null.
                final mapState = ref.read(local_map.mapControllerProvider);
                Position? userPos;
                if (mapState.hasValue) {
                  userPos = Position(
                    longitude: mapState.value!.longitude,
                    latitude: mapState.value!.latitude,
                    timestamp: DateTime.now(),
                    accuracy: 0,
                    altitude: 0,
                    heading: 0,
                    speed: 0,
                    speedAccuracy: 0,
                    altitudeAccuracy: 0,
                    headingAccuracy: 0,
                  );
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaceDetailsPage(
                      location: LocationModel.fromJson(loc),
                      userPosition: userPos,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(iconData, color: Colors.white, size: 22),
              ),
            ),
          ),
        );
      }
    });

    return NetworkAwareWidget(
      offlineTitle: AppLocalizations.of(context)!.archiveMode,
      offlineSubtitle: AppLocalizations.of(context)!.archiveModeSubtitle,
      onReconnected: () async {
        // Tunnel Exit Sync: Refresh data automatically
        ref.invalidate(local_map.nearbyUsersProvider);
        await ref.read(local_map.nearbyUsersProvider.future);

        ref.invalidate(local_map.nearbyLocationsProvider);
        await ref.read(local_map.nearbyLocationsProvider.future);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.radarSynced),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. Flutter Map (OSM)
            mapState.when(
              data: (position) {
                return RepaintBoundary(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: position,
                      initialZoom: 15.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag
                            .all, // Enable all interactions including rotation
                      ),
                    ),
                    children: [
                      TileLayer(
                        // SUPER LIGHT MAP (CartoDB Positron)
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.munokolive.music',
                      ),
                      MarkerLayer(markers: markers),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
              error: (e, st) {
                final errorStr = e.toString();
                final isServiceDisabled = errorStr.contains(
                  'services de localisation sont désactivés',
                );
                final isPermissionDenied = errorStr.contains('permissions');

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isServiceDisabled
                              ? Icons.location_off
                              : Icons.error_outline,
                          color: Colors.redAccent,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isServiceDisabled
                              ? AppLocalizations.of(context)!.gpsDisabled
                              : isPermissionDenied
                                  ? AppLocalizations.of(context)!.permissionDenied
                                  : AppLocalizations.of(context)!.radarError,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isServiceDisabled
                              ? AppLocalizations.of(context)!.enableLocationMessage
                              : errorStr.replaceAll('Exception: ', ''),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        if (isServiceDisabled)
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Geolocator.openLocationSettings();
                              // Wait a bit then refresh
                              await Future.delayed(const Duration(seconds: 1));
                              ref.invalidate(local_map.mapControllerProvider);
                            },
                            icon: const Icon(Icons.settings),
                            label: Text(AppLocalizations.of(context)!.enableGPS),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          )
                        else if (isPermissionDenied)
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Geolocator.openAppSettings();
                              ref.invalidate(local_map.mapControllerProvider);
                            },
                            icon: const Icon(Icons.settings),
                            label: Text(AppLocalizations.of(context)!.openSettings),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () =>
                                ref.invalidate(local_map.mapControllerProvider),
                            icon: const Icon(Icons.refresh),
                            label: Text(AppLocalizations.of(context)!.retryButton),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 2. Filters & Status (Floating Clean UI)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Online Count Header
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.greenAccent,
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "En ligne : ${nearbyUsersAsync.value?.length ?? 0}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Filters (Horizontal Scroll)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              'ALL',
                              AppLocalizations.of(context)!.allCategories,
                              Icons.all_inclusive,
                              Colors.white,
                              backgroundColor: Colors.black87,
                            ),
                            const SizedBox(width: 10),
                            _buildFilterChip(
                              'MUSICIANS',
                              AppLocalizations.of(context)!.filterMusicians,
                              Icons.music_note,
                              Colors.pinkAccent,
                              backgroundColor: Colors.black87,
                            ),
                            const SizedBox(width: 10),
                            _buildFilterChip(
                              'MEN_OF_GOD',
                              AppLocalizations.of(context)!.filterMenOfGod,
                              Icons.church,
                              Colors.blueAccent,
                              backgroundColor: Colors.black87,
                            ),
                            const SizedBox(width: 10),
                            _buildFilterChip(
                              'PLACES',
                              AppLocalizations.of(context)!.filterPlaces,
                              Icons.place,
                              Colors.orangeAccent,
                              backgroundColor: Colors.black87,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Map Controls (Compass, Zoom, Recenter)
            Positioned(
              right: 16,
              bottom: 100, // Position élevée pour dégager le bas
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Compass (Boussole Vivante)
                  StreamBuilder<CompassEvent>(
                    stream: FlutterCompass.events,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final double? direction = snapshot.data!.heading;
                        if (direction == null) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Transform.rotate(
                            angle: (direction * (math.pi / 180) * -1),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.navigation,
                                color: Colors.redAccent,
                                size: 32,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),

                  // Zoom In
                  FloatingActionButton.small(
                    heroTag: "zoom_in",
                    onPressed: () {
                      final camera = _mapController.camera;
                      _mapController.move(camera.center, camera.zoom + 1);
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.add, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),

                  // Zoom Out
                  FloatingActionButton.small(
                    heroTag: "zoom_out",
                    onPressed: () {
                      final camera = _mapController.camera;
                      _mapController.move(camera.center, camera.zoom - 1);
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.remove, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  // Recenter / My Location Button
                  FloatingActionButton(
                    heroTag: "recenter",
                    onPressed: _centerOnUser,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.my_location, color: Colors.blueAccent),
                  ),
                ],
              ),
            ),

            // 6. Compass Indicator (Custom placement if needed, or default works)
          ],
        ),
      ),
    );
  }
}
