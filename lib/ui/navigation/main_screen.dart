import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/georadar_service.dart';
import '../../services/notification_service.dart';
import '../../services/notification_listener_service.dart';
import '../../services/geofence_service.dart';
import '../../providers/app_state_providers.dart';
import '../../providers/user_provider.dart'; // Import user_provider

// Screens
import '../home/home_screen.dart'; // Accueil
import '../map/map_widget.dart'; // Radar
import '../places/places_screen.dart'; // Lieu
import '../contacts/contacts_screen.dart'; // Contact
import '../events/events_screen.dart'; // Événement
import '../theme/app_theme.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  StreamSubscription<Position>? _positionStream;

  // 5 Menus requested by user
  final List<Widget> _screens = [
    const HomeScreen(), // 0: ACCUEIL
    const MapWidget(), // 1: RADAR (Carte)
    const PlacesScreen(), // 2: LIEU
    const ContactsScreen(), // 3: CONTACT
    const EventsScreen(), // 4: ÉVÉNEMENT
  ];

  @override
  void initState() {
    super.initState();
    _checkAndStartTracking();

    // Start listening for notifications (SOS, etc.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationListenerProvider).startListening();
      ref.read(geofenceServiceProvider).startMonitoring(); // Start Geofencing

      // Listen for notification taps
      ref.read(notificationServiceProvider).onNotificationTap.listen((payload) {
        if (payload != null) {
          _handleNotificationTap(payload);
        }
      });
    });
  }

  void _handleNotificationTap(String payload) {
    if (payload.startsWith('sos:')) {
      // Switch to Map tab (Radar)
      ref.read(bottomNavIndexProvider.notifier).state = 1;

      final sosId = payload.split(':')[1];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Affichage de l\'alerte SOS #$sosId sur la carte...'),
        ),
      );
      // Logic to center map on SOS would go here (via provider)
    } else if (payload == 'message') {
      // Switch to Contacts tab
      ref.read(bottomNavIndexProvider.notifier).state = 3;
    } else if (payload.startsWith('birthday_wish')) {
      // Switch to Contacts tab for Birthday
      ref.read(bottomNavIndexProvider.notifier).state = 3;
      // Ideally switch to "Anniversaires" tab within ContactsScreen,
      // but that requires more complex state management.
      // The Halo header is visible in the main list too (as implemented in ContactsScreen).

      if (payload.contains('action=wish')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dites-leur joyeux anniversaire !'),
            backgroundColor: Color(0xFFFFD700),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (payload.startsWith('event:')) {
      // Switch to Events tab
      ref.read(bottomNavIndexProvider.notifier).state = 4;
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    // Use read directly might be unsafe in dispose if provider is already disposed,
    // but typically safe for singletons/kept alive providers.
    // However, it's better to rely on autoDispose or manual cleanup if possible.
    // For now, we assume MainScreen is the root.
    super.dispose();
  }

  Future<void> _checkAndStartTracking() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _startLocationUpdates();
    }
  }

  Future<void> _startLocationUpdates() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      final profile = await ref
          .read(authServiceProvider)
          .getUserProfile(user.uid);
      if (profile == null) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50 meters
      );

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen((Position position) {
            // Update Global State
            ref.read(userLocationProvider.notifier).state = position;

            // Update Backend/Radar Service
            ref
                .read(geoRadarServiceProvider)
                .updateUserLocation(
                  profile,
                  GeoPoint(position.latitude, position.longitude),
                );
          });
    } catch (e) {
      debugPrint('Error tracking location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Schedule Birthday Notifications when users are loaded
    ref.listen(allUsersProvider, (previous, next) {
      next.whenData((users) {
        ref
            .read(notificationServiceProvider)
            .scheduleBirthdayNotifications(users);
      });
    });

    final currentIndex = ref.watch(bottomNavIndexProvider);
    final badgeState = ref.watch(badgeStateProvider);

    return Scaffold(
      extendBody: true,
      // Use IndexedStack for Keep-Alive State
      body: IndexedStack(index: currentIndex, children: _screens),
      floatingActionButton: null,
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: currentIndex,
        height: 60.0,
        color: AppTheme.backgroundLight.withValues(alpha: 0.95),
        backgroundColor: Colors.transparent,
        buttonBackgroundColor: AppTheme.primaryColor,
        animationDuration: const Duration(milliseconds: 300),
        items: <Widget>[
          const Icon(
            Icons.home,
            size: 30,
            color: AppTheme.textPrimary,
          ), // Accueil

          const Icon(
            Icons.radar,
            size: 30,
            color: AppTheme.textPrimary,
          ), // Radar

          const Icon(
            Icons.place,
            size: 30,
            color: AppTheme.textPrimary,
          ), // Lieu
          // Contact (with Badge)
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.contacts, size: 30, color: AppTheme.textPrimary),
              if (badgeState.contactsOnline > 0)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${badgeState.contactsOnline}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Événement (with Badge)
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.event, size: 30, color: AppTheme.textPrimary),
              if (badgeState.eventsNearby > 0)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${badgeState.eventsNearby}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        onTap: (index) {
          // Haptic Feedback for Menu Change
          HapticFeedback.lightImpact();

          // Update Provider
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}
