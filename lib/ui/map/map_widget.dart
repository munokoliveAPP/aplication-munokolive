import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/user_profile.dart';
import '../../services/storage_service.dart';
import 'widgets/map_user_profile_button.dart';
import 'widgets/user_profile_sheet.dart';
import 'widgets/zone_stats_widget.dart';
import 'controllers/map_controller.dart';
import '../widgets/central_sos_button.dart';

import 'map_style.dart';
import '../theme/app_theme.dart';

class MapWidget extends ConsumerStatefulWidget {
  const MapWidget({super.key});

  @override
  ConsumerState<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  late GoogleMapController _controller;
  CameraPosition? _lastMovePosition;

  // Zoom par défaut optimisé pour l'identification des quartiers (15-16)
  final CameraPosition _defaultPos = const CameraPosition(
    target: LatLng(48.8566, 2.3522),
    zoom: 16.0,
  );

  @override
  void initState() {
    super.initState();

    // Initialisation du contrôleur (Permissions, Listeners)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapControllerProvider.notifier).initialize();
    });
  }

  Future<void> _restoreCameraPosition() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final savedPos = await storage.getLastCameraPosition();
      if (savedPos != null) {
        _controller.moveCamera(CameraUpdate.newCameraPosition(savedPos));
        ref
            .read(mapControllerProvider.notifier)
            .startRealtimeScan(savedPos.target);
      } else {
        ref
            .read(mapControllerProvider.notifier)
            .startRealtimeScan(_defaultPos.target);
      }
    } catch (e) {
      debugPrint('Error restoring camera position: $e');
    }
  }

  void _showUserProfile(UserProfile user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserProfileSheet(user: user),
    ).then((_) {
      // Effacer la sélection à la fermeture pour permettre la réouverture
      ref.read(mapControllerProvider.notifier).clearSelection();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapControllerProvider);

    // Écouter les changements de sélection utilisateur pour afficher le profil
    ref.listen<MapState>(mapControllerProvider, (previous, next) {
      if (next.selectedUser != null &&
          (previous?.selectedUser?.uid != next.selectedUser!.uid)) {
        _showUserProfile(next.selectedUser!);
      }
    });

    return Stack(
      children: [
        GoogleMap(
          style: customMapStyle, // Style Hybride Économique
          initialCameraPosition: _defaultPos,
          markers: mapState.markers,
          myLocationEnabled: mapState.hasPermission,
          myLocationButtonEnabled: false,
          onMapCreated: (c) {
            _controller = c;
            _restoreCameraPosition();
          },
          onCameraMove: (pos) => _lastMovePosition = pos,
          onCameraIdle: () {
            if (_lastMovePosition != null) {
              ref
                  .read(storageServiceProvider)
                  .saveCameraPosition(_lastMovePosition!);
              ref
                  .read(mapControllerProvider.notifier)
                  .startRealtimeScan(_lastMovePosition!.target);
            }
          },
          mapType: MapType.normal,
          zoomControlsEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
        ),

        // Zone Stats Overlay (Zone d'Influence)
        const ZoneStatsWidget(),

        // User Profile & Control Center Trigger (Top Left)
        const Positioned(
          top: 0,
          left: 16,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: 10),
              child: MapUserProfileButton(),
            ),
          ),
        ),

        // Central SOS Button
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: CentralSOSButton(onSoSTriggered: () {}),
        ),

        // Location Permission / My Location Button
        if (!mapState.hasPermission)
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              heroTag: 'map_location_btn',
              onPressed: () {
                ref.read(mapControllerProvider.notifier).requestPermission();
              },
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(
                Icons.location_disabled,
                color: AppTheme.textPrimary,
              ),
            ),
          )
        else
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              heroTag: 'map_my_location_btn',
              onPressed: () async {
                final pos = await Geolocator.getCurrentPosition();
                _controller.animateCamera(
                  CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
                );
              },
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.my_location, color: AppTheme.textPrimary),
            ),
          ),
      ],
    );
  }
}
