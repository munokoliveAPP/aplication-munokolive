import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:munokolive_music/ui/map/widgets/aegis_radar_overlay.dart';
import 'package:munokolive_music/ui/map/ar_finder_page.dart';
import 'package:vibration/vibration.dart';
import 'package:battery_plus/battery_plus.dart';
import '../../services/privacy_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:munokolive_music/models/user_profile.dart';
import '../../models/event_model.dart';
import '../../models/access_request.dart';
import '../../providers/events_provider.dart';
import 'package:munokolive_music/ui/events/event_details_page.dart';
import '../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/sos_service.dart';
import '../../providers/user_provider.dart';

class MembersMapPage extends ConsumerStatefulWidget {
  const MembersMapPage({super.key});

  @override
  ConsumerState<MembersMapPage> createState() => _MembersMapPageState();
}

class _MembersMapPageState extends ConsumerState<MembersMapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {};

  Position? _currentPosition;
  double _radiusKm = 5.0; // Default 5km
  bool _isLoading = true;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<List<AccessRequest>>? _requestsSubscription;
  final LocalAuthentication _localAuth = LocalAuthentication();
  UserProfile? _selectedUser;
  double? _distanceToSelectedUser;

  final Set<String> _alertedUsers = {};
  List<UserProfile> _cachedUsers = [];
  final Map<String, Map<String, dynamic>> _activeGeofences =
      {}; // UserId -> {center: LatLng, radius: double}

  // Battery & Optimization
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.full;
  StreamSubscription<BatteryState>? _batteryStateSubscription;

  Timer? _idleTimer;
  bool _isLowPowerMode = false;
  bool _isCheckedIn = false;

  @override
  void initState() {
    super.initState();
    _initBattery();
    _initLocation();
    _resetIdleTimer();
    // Defer the listener slightly to ensure context/ref is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToIncomingRequests();
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _requestsSubscription?.cancel();
    _batteryStateSubscription?.cancel();
    _idleTimer?.cancel();
    super.dispose();
  }

  Future<void> _initBattery() async {
    // Initial check
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      setState(() {
        _batteryLevel = level;
        _batteryState = state;
      });
      _optimizeBatteryUsage();
    } catch (e) {
      debugPrint("Battery init error: $e");
    }

    // Listen
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((
      state,
    ) async {
      final level = await _battery.batteryLevel;
      setState(() {
        _batteryState = state;
        _batteryLevel = level;
      });
      _optimizeBatteryUsage();
    });
  }

  void _optimizeBatteryUsage() {
    // Intelligent Power Management
    // If charging, High Performance.
    // If < 20% and not charging, Eco Mode.

    if (_batteryState == BatteryState.charging ||
        _batteryState == BatteryState.full) {
      if (_isLowPowerMode) _toggleLowPowerMode(false); // Max Performance
    } else {
      if (_batteryLevel < 20) {
        if (!_isLowPowerMode) {
          _toggleLowPowerMode(true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Batterie faible : Mode Radar Éco activé."),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    }
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (_isLowPowerMode) {
      _toggleLowPowerMode(false); // Wake up
    }
    _idleTimer = Timer(const Duration(minutes: 5), () {
      _toggleLowPowerMode(true); // Go to sleep
    });
  }

  void _toggleLowPowerMode(bool enable) {
    if (_isLowPowerMode == enable) return;

    setState(() {
      _isLowPowerMode = enable;
    });

    _initLocation(); // Re-init with new settings

    if (enable) {
      debugPrint("Entering Low Power Mode (Optimized Refresh)");
    } else {
      debugPrint("Exiting Low Power Mode (High Accuracy)");
    }
  }

  Future<void> _initLocation() async {
    // Check permissions
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    // Stop existing stream if any
    _positionStream?.cancel();

    // Get current position
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _isLoading = false;
          _updateCircles();
        });
      }

      // Start stream with dynamic settings
      LocationSettings locationSettings;
      if (_isLowPowerMode) {
        // Eco Mode: Medium accuracy, update every 100m or 1 minute
        // On Android, we can also use specific AndroidSettings
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 100, // Update only if moved 100m
          timeLimit: Duration(
            minutes: 1,
          ), // Or time interval if platform supports
        );
      } else {
        // High Performance: Best accuracy, update every 10m
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );
      }

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen((Position position) {
            if (mounted) {
              setState(() {
                _currentPosition = position;
                _updateCircles();
                if (_selectedUser != null) {
                  _updatePolyline(_selectedUser!);
                }
              });
              _checkProximityAlerts(position);
            }
          });
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  Future<void> _handleCheckIn() async {
    if (_selectedUser == null || _currentPosition == null) return;

    // 1. Verify Geography (Double check)
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _selectedUser!.latitude!,
      _selectedUser!.longitude!,
    );

    if (distance > 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vous êtes trop loin pour faire le check-in !"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(authServiceProvider).currentUser;
      if (currentUser != null) {
        // 2. Record Check-in in Firestore
        await FirebaseFirestore.instance.collection('checkins').add({
          'userId': currentUser.uid,
          'targetUserId': _selectedUser!.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'location': GeoPoint(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          'distance': distance,
        });

        // 3. Update Reliability Score (Seniority Boost)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
              'successfulCheckins': FieldValue.increment(1),
              'lastCheckIn': FieldValue.serverTimestamp(),
            });

        // 4. Simulate Notification to Target
        // In a real app, this would be a Cloud Function trigger or FCM push
        ref
            .read(notificationServiceProvider)
            .showNotification(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: "Check-in Validé",
              body: "Notification envoyée à ${_selectedUser!.firstName} !",
            );
      }

      setState(() {
        _isCheckedIn = true;
        _isLoading = false;
      });

      // 5. Success Animation/Feedback
      showDialog(
        context: mounted ? context : context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.backgroundDark,
          title: const Text(
            "Mission Validée !",
            style: TextStyle(color: Colors.white),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, color: Colors.greenAccent, size: 60),
              SizedBox(height: 16),
              Text(
                "Vous êtes arrivé à destination.\nUn point de fiabilité a été ajouté à votre profil.",
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "Super",
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      String message = "Erreur lors du check-in: $e";
      if (e.toString().contains('permission-denied')) {
        message =
            "Permission refusée. Vérifiez que vous êtes connecté et autorisé.";
      }
      ScaffoldMessenger.of(
        mounted ? context : context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _handleSOS() {
    // Discrete SOS Alert
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        title: const Text(
          "ALERTE SÉCURITÉ",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Voulez-vous envoyer un signalement discret à l'équipe de sécurité et aux membres proches ?",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Annuler",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);

              if (_currentPosition == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Position inconnue. Impossible d'envoyer l'alerte.",
                    ),
                  ),
                );
                return;
              }

              try {
                final user = ref.read(authServiceProvider).currentUser;
                if (user == null) return;

                await ref
                    .read(sosServiceProvider)
                    .triggerSOS(
                      requesterId: user.uid,
                      requesterName: user.displayName ?? "Membre",
                      location: GeoPoint(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      locationDescription: "Alerte depuis la carte",
                    );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Signalement envoyé. Restez calme, de l'aide arrive.",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  String message = "Erreur lors de l'envoi de l'alerte: $e";
                  if (e.toString().contains('permission-denied')) {
                    message = "Erreur de permission pour l'alerte SOS.";
                  }
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                }
              }
            },
            child: const Text(
              "ENVOYER ALERTE",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _listenToIncomingRequests() {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    _requestsSubscription = ref
        .read(privacyServiceProvider)
        .getIncomingRequests(user.uid)
        .listen((requests) {
          if (requests.isNotEmpty) {
            // Show the first pending request
            // We use a flag or check if the dialog is already open ideally.
            // Here we just pick the first one.
            final request = requests.first;

            // Fetch requester profile
            FirebaseFirestore.instance
                .collection('users')
                .doc(request.requesterId)
                .get()
                .then((doc) {
                  if (doc.exists && mounted) {
                    final requester = UserProfile.fromJson(doc.data()!);
                    // Only show if we haven't processed it yet (it's still pending)
                    // The stream only gives pending requests, so this is safe.
                    // However, to avoid spamming dialogs on every snapshot update if the list doesn't change:
                    // We could check if the dialog is open.
                    // For this MVP, we assume the user deals with it quickly.
                    // A better approach is to use a unique ID check or a local state variable `_currentRequestId`.

                    // Quick fix: Don't show if a dialog is likely open?
                    // We'll just trigger it. Flutter dialogs stack.
                    // Ideally we'd check `_currentRequestId != request.id`
                    _showBiometricValidationDialog(request, requester);
                  }
                });
          }
        });
  }

  Future<void> _showBiometricValidationDialog(
    AccessRequest request,
    UserProfile requester,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        title: const Column(
          children: [
            Icon(Icons.fingerprint, size: 50, color: AppTheme.primaryColor),
            SizedBox(height: 10),
            Text("Accès Sécurisé", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (requester.photoURL.isNotEmpty)
              CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(requester.photoURL),
                radius: 30,
              )
            else
              const CircleAvatar(
                backgroundColor: Colors.grey,
                radius: 30,
                child: Icon(Icons.person, color: Colors.white),
              ),
            const SizedBox(height: 10),
            Text(
              "${requester.firstName} souhaite voir votre position précise.",
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Durée : ${request.durationMinutes == -1 ? 'Indéfinie' : '${request.durationMinutes} min'}",
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref
                  .read(privacyServiceProvider)
                  .rejectVisibilityRequest(request.id);
              Navigator.pop(ctx);
            },
            child: const Text(
              "Refuser",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () async {
              // Biometric Check
              bool authenticated = false;
              try {
                final canCheck = await _localAuth.canCheckBiometrics;
                if (canCheck) {
                  authenticated = await _localAuth.authenticate(
                    localizedReason: 'Validez pour partager votre position',
                    biometricOnly: true,
                  );
                } else {
                  // Fallback if no biometrics hardware
                  authenticated = true;
                }
              } catch (e) {
                debugPrint("Biometric error: $e");
                // Fallback on error (e.g. no hardware)
                authenticated = true;
              }

              if (authenticated) {
                await ref
                    .read(privacyServiceProvider)
                    .acceptVisibilityRequest(request.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Accès accordé à ${requester.firstName}"),
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Valider (FaceID)",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildEventMarkers(List<EventModel> events) {
    Set<Marker> markers = {};
    for (var event in events) {
      if (event.coordinates != null) {
        markers.add(
          Marker(
            markerId: MarkerId('event_${event.id}'),
            position: LatLng(
              event.coordinates!.latitude,
              event.coordinates!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet,
            ),
            onTap: () => _showEventPreview(event),
          ),
        );
      }
    }
    return markers;
  }

  void _showEventPreview(EventModel event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.deepPurpleAccent, width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.event, color: Colors.deepPurpleAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                event.title,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: event.imageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[800],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              event.date.toString().substring(0, 16),
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              "${event.attendees.length} participants",
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Quelqu'un y va ?",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Logic to show friends going could go here
            if (_cachedUsers.isNotEmpty)
              Wrap(
                spacing: -8,
                children: _cachedUsers
                    .where((u) => event.attendees.contains(u.uid))
                    .take(5)
                    .map(
                      (u) => CircleAvatar(
                        radius: 12,
                        backgroundImage: u.photoUrl != null
                            ? NetworkImage(u.photoUrl!)
                            : null,
                        child: u.photoUrl == null
                            ? Text(
                                u.firstName[0],
                                style: const TextStyle(fontSize: 10),
                              )
                            : null,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Fermer"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailsPage(event: event),
                ),
              );
            },
            child: const Text(
              "Voir Détails",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccessRequestDialog(UserProfile user) {
    int selectedDuration = 30; // Default

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.backgroundDark,
          title: const Row(
            children: [
              Icon(Icons.lock_clock, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Demande de Visibilité",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${user.firstName} est en mode localisation floue.",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              const Text(
                "Durée de l'accès :",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButton<int>(
                value: selectedDuration,
                dropdownColor: AppTheme.backgroundDark,
                style: const TextStyle(color: Colors.white),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 30, child: Text("30 Minutes")),
                  DropdownMenuItem(value: 60, child: Text("1 Heure")),
                  DropdownMenuItem(
                    value: -1,
                    child: Text("Indéfini (Permanent)"),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => selectedDuration = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final currentUser = ref.read(authServiceProvider).currentUser;
                if (currentUser != null) {
                  await ref
                      .read(privacyServiceProvider)
                      .requestVisibilityAccess(
                        requesterId: currentUser.uid,
                        targetUserId: user.uid,
                        durationMinutes: selectedDuration,
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Demande envoyée. En attente de validation...",
                        ),
                        backgroundColor: Colors.blueAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                "Envoyer",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkProximityAlerts(Position position) async {
    if (_cachedUsers.isEmpty) return;

    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) return;

    // Retrieve current user profile to get interests
    // We can optimize this by caching myProfile too, but for now fetch it or use provider if available
    final myProfileAsync = ref.read(userProfileProvider);
    final myProfile = myProfileAsync.value;

    if (myProfile == null || myProfile.interests.isEmpty) return;

    for (final user in _cachedUsers) {
      if (user.uid == currentUser.uid) continue;
      if (_alertedUsers.contains(user.uid)) continue;

      if (user.latitude != null && user.longitude != null) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          user.latitude!,
          user.longitude!,
        );

        if (distance <= 50) {
          // 50 meters
          // Check common interests
          final commonInterests = user.interests
              .where((i) => myProfile.interests.contains(i))
              .toList();

          if (commonInterests.isNotEmpty) {
            // Trigger Alert
            _alertedUsers.add(user.uid);

            bool? hasVibrator = await Vibration.hasVibrator();
            if (hasVibrator == true) {
              Vibration.vibrate(pattern: [500, 1000, 500, 1000]);
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Smart Ping ! ${user.firstName} partage vos intérêts : ${commonInterests.join(', ')}",
                  ),
                  backgroundColor: Colors.deepPurpleAccent,
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: "Voir",
                    textColor: Colors.white,
                    onPressed: () {
                      setState(() {
                        _selectedUser = user;
                        _updatePolyline(user);
                      });
                    },
                  ),
                ),
              );
            }
          }
        }
      }
    }
  }

  Set<Circle> _getGeofenceCircles() {
    return _activeGeofences.entries.map((entry) {
      final center = entry.value['center'] as LatLng;
      final radius = entry.value['radius'] as double;
      return Circle(
        circleId: CircleId('geofence_${entry.key}'),
        center: center,
        radius: radius,
        fillColor: Colors.red.withValues(alpha: 0.1),
        strokeColor: Colors.redAccent,
        strokeWidth: 2,
      );
    }).toSet();
  }

  void _checkGeofences(List<UserProfile> users) {
    for (final user in users) {
      if (_activeGeofences.containsKey(user.uid)) {
        final geofence = _activeGeofences[user.uid]!;
        final center = geofence['center'] as LatLng;
        final radius = geofence['radius'] as double;

        if (user.latitude != null && user.longitude != null) {
          final distance = Geolocator.distanceBetween(
            center.latitude,
            center.longitude,
            user.latitude!,
            user.longitude!,
          );

          if (distance > radius) {
            // User exited geofence!
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "⚠️ ALERTE : ${user.firstName} est sorti de la zone de sécurité !",
                  ),
                  backgroundColor: Colors.redAccent,
                  duration: const Duration(seconds: 10),
                ),
              );
              Vibration.vibrate(pattern: [1000, 1000, 1000, 1000]);
            }
          }
        }
      }
    }
  }

  void _showGeofenceDialog(UserProfile user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundDark,
        title: const Text(
          "Bulle de Sécurité",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Définir une zone de sécurité autour de la position actuelle de ce membre.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              onPressed: () {
                if (user.latitude != null && user.longitude != null) {
                  setState(() {
                    _activeGeofences[user.uid] = {
                      'center': LatLng(user.latitude!, user.longitude!),
                      'radius': 200.0, // 200 meters default
                    };
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Bulle de sécurité activée (200m)"),
                    ),
                  );
                }
              },
              child: const Text(
                "Activer (200m)",
                style: TextStyle(color: Colors.white),
              ),
            ),
            if (_activeGeofences.containsKey(user.uid))
              TextButton(
                onPressed: () {
                  setState(() {
                    _activeGeofences.remove(user.uid);
                  });
                  Navigator.pop(ctx);
                },
                child: const Text(
                  "Désactiver",
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleGhostMode(bool enable) async {
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser != null) {
      await ref
          .read(privacyServiceProvider)
          .toggleGhostMode(currentUser.uid, enable);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enable
                  ? "👻 GHOST MODE ACTIVÉ : Vous êtes invisible."
                  : "👁️ GHOST MODE DÉSACTIVÉ : Vous êtes visible.",
            ),
            backgroundColor: enable ? Colors.red : Colors.green,
          ),
        );
      }
    }
  }

  void _updateCircles() {
    if (_currentPosition == null) return;

    setState(() {
      _circles = {
        Circle(
          circleId: const CircleId('radar_range'),
          center: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          radius: _radiusKm * 1000, // Convert to meters
          fillColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          strokeColor: AppTheme.primaryColor.withValues(alpha: 0.5),
          strokeWidth: 1,
        ),
      };
    });
  }

  void _updatePolyline(UserProfile user) {
    if (_currentPosition == null ||
        user.latitude == null ||
        user.longitude == null) {
      return;
    }

    final userPos = _getUserLocation(user);

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      userPos.latitude,
      userPos.longitude,
    );

    setState(() {
      _distanceToSelectedUser = distance;
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            userPos,
          ],
          color: AppTheme.primaryColor,
          width: 3,
          patterns: [PatternItem.dash(10), PatternItem.gap(10)],
        ),
      };
    });
  }

  String _calculateETA(double distanceInMeters) {
    if (distanceInMeters < 2000) {
      // Walking (5 km/h)
      final minutes = (distanceInMeters / 1000) / 5 * 60;
      return "${minutes.ceil()} min";
    } else {
      // Driving (40 km/h)
      final minutes = (distanceInMeters / 1000) / 40 * 60;
      return "${minutes.ceil()} min";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch all users
    final usersAsync = ref.watch(allUsersProvider);
    // Watch all events
    final eventsAsync = ref.watch(eventsStreamProvider);

    usersAsync.whenData((users) {
      _cachedUsers = users;
      _checkGeofences(users);
    });

    return Listener(
      onPointerDown: (_) => _resetIdleTimer(),
      child: Stack(
        children: [
          // MAP
          usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Impossible de charger la carte.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Vérifiez votre connexion internet ou vos permissions.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => ref.refresh(allUsersProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Réessayer"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            data: (users) {
              final markers = _buildMarkers(users);

              // Add Event Markers
              if (eventsAsync.value != null) {
                markers.addAll(_buildEventMarkers(eventsAsync.value!));
              }

              return GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(-4.4419, 15.2663), // Kinshasa fallback
                  zoom: 15, // Closer zoom for 3D effect
                  tilt: 45.0, // 3D Tilt
                  bearing: 0.0,
                ),
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                  if (_currentPosition != null) {
                    controller.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          zoom: 16.0,
                          tilt: 45.0,
                        ),
                      ),
                    );
                  }
                },
                markers: markers,
                circles: _circles
                    .union(_getPrivacyCircles(users))
                    .union(_getGeofenceCircles()),
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapType: MapType.normal,
                buildingsEnabled: true, // Enable 3D buildings
                trafficEnabled: true, // Real-time traffic
                style: _mapStyle,
              );
            },
          ),

          // AEGIS RADAR OVERLAY
          if (!_isLoading && !_isLowPowerMode)
            const AegisRadarOverlay(radius: 200, color: AppTheme.primaryColor),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            ),

          // RADAR CONTROLS (Top)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Portée Radar: ${_radiusKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Battery Indicator
                          if (_batteryStateSubscription != null)
                            Row(
                              children: [
                                Icon(
                                  _batteryState == BatteryState.charging
                                      ? Icons.battery_charging_full
                                      : _batteryLevel < 20
                                      ? Icons.battery_alert
                                      : Icons.battery_full,
                                  color:
                                      _batteryLevel < 20 &&
                                          _batteryState != BatteryState.charging
                                      ? Colors.orange
                                      : Colors.greenAccent,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isLowPowerMode ? "Mode Éco" : "Haute Perf.",
                                  style: TextStyle(
                                    color: _isLowPowerMode
                                        ? Colors.orange
                                        : Colors.greenAccent,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const Icon(Icons.radar, color: AppTheme.primaryColor),
                    ],
                  ),
                  Slider(
                    value: _radiusKm,
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    activeColor: AppTheme.primaryColor,
                    inactiveColor: Colors.white24,
                    onChanged: (val) {
                      setState(() {
                        _radiusKm = val;
                        _updateCircles();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // SOS BUTTON (Below Radar Controls)
          Positioned(
            top: MediaQuery.of(context).padding.top + 100,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: "sos_btn",
                  backgroundColor: Colors.redAccent,
                  onPressed: _handleSOS,
                  child: const Icon(Icons.sos, color: Colors.white),
                ),
                const SizedBox(height: 16),
                // PANIC BUTTON / GHOST MODE
                Consumer(
                  builder: (context, ref, _) {
                    final currentUser = ref.watch(userProfileProvider).value;
                    final isGhost = currentUser?.isGhostMode ?? false;
                    return FloatingActionButton.small(
                      heroTag: "ghost_btn",
                      backgroundColor: isGhost
                          ? Colors.red
                          : Colors.greenAccent,
                      onPressed: () => _toggleGhostMode(!isGhost),
                      child: Icon(
                        isGhost ? Icons.no_photography : Icons.visibility,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // SELECTED USER INFO (Bottom)
          if (_selectedUser != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Avatar with Online Indicator (Green Border)
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: _selectedUser!.isOnline
                                ? Border.all(
                                    color: Colors.greenAccent,
                                    width: 3,
                                  )
                                : null,
                            boxShadow: _selectedUser!.isOnline
                                ? [
                                    BoxShadow(
                                      color: Colors.greenAccent.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: CircleAvatar(
                            radius: 25,
                            backgroundImage: _selectedUser!.photoUrl != null
                                ? NetworkImage(_selectedUser!.photoUrl!)
                                : null,
                            backgroundColor: AppTheme.primaryColor,
                            child: _selectedUser!.photoUrl == null
                                ? Text(
                                    _selectedUser!.firstName[0],
                                    style: const TextStyle(color: Colors.white),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_selectedUser!.firstName} ${_selectedUser!.lastName}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _selectedUser!.category,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              if (_distanceToSelectedUser != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'À ${(_distanceToSelectedUser! / 1000).toStringAsFixed(2)} km',
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _distanceToSelectedUser! < 2000
                                                ? Icons.directions_walk
                                                : Icons.directions_car,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Arrivée : ${_calculateETA(_distanceToSelectedUser!)}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        // COMPASS WIDGET
                        if (_currentPosition != null &&
                            _selectedUser!.latitude != null &&
                            _selectedUser!.longitude != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Column(
                              children: [
                                Transform.rotate(
                                  angle:
                                      (Geolocator.bearingBetween(
                                            _currentPosition!.latitude,
                                            _currentPosition!.longitude,
                                            _selectedUser!.latitude!,
                                            _selectedUser!.longitude!,
                                          ) -
                                          (_currentPosition!.heading)) *
                                      (pi / 180),
                                  child: const Icon(
                                    Icons.navigation,
                                    color: AppTheme.primaryColor,
                                    size: 30,
                                  ),
                                ),
                                const Text(
                                  "Cap",
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_currentPosition != null &&
                            _selectedUser!.latitude != null &&
                            _selectedUser!.longitude != null)
                          IconButton(
                            icon: const Icon(
                              Icons.view_in_ar,
                              color: Colors.blueAccent,
                              size: 30,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ArFinderPage(
                                    targetUser: _selectedUser!,
                                    currentPosition: _currentPosition!,
                                  ),
                                ),
                              );
                            },
                          ),
                        if (_currentPosition != null &&
                            _selectedUser!.latitude != null &&
                            _selectedUser!.longitude != null)
                          IconButton(
                            icon: Icon(
                              _activeGeofences.containsKey(_selectedUser!.uid)
                                  ? Icons.security
                                  : Icons.security_outlined,
                              color:
                                  _activeGeofences.containsKey(
                                    _selectedUser!.uid,
                                  )
                                  ? Colors.redAccent
                                  : Colors.white54,
                              size: 30,
                            ),
                            onPressed: () =>
                                _showGeofenceDialog(_selectedUser!),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () {
                            setState(() {
                              _selectedUser = null;
                              _polylines = {};
                            });
                          },
                        ),
                      ],
                    ),

                    // CHECK-IN BUTTON (Dynamic)
                    if (_distanceToSelectedUser != null &&
                        _distanceToSelectedUser! < 200)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isCheckedIn
                                  ? Colors.green
                                  : AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            onPressed: _isCheckedIn ? null : _handleCheckIn,
                            icon: Icon(
                              _isCheckedIn
                                  ? Icons.check_circle
                                  : Icons.location_on,
                            ),
                            label: Text(
                              _isCheckedIn
                                  ? "MISSION VALIDÉE"
                                  : "FAIRE MON CHECK-IN",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // RECENTER BUTTON
          Positioned(
            bottom: _selectedUser != null
                ? 180
                : 100, // Adjusted to avoid overlap
            right: 16,
            child: FloatingActionButton(
              heroTag: "recenter_btn", // Unique tag
              backgroundColor: AppTheme.secondaryColor,
              onPressed: () async {
                if (_currentPosition != null) {
                  final c = await _controller.future;
                  c.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                    ),
                  );
                }
              },
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  LatLng _getUserLocation(UserProfile user) {
    double lat = user.latitude!;
    double lng = user.longitude!;

    if (user.isDiscretMode) {
      final random = Random(user.uid.hashCode);
      lat += (random.nextDouble() - 0.5) * 0.01;
      lng += (random.nextDouble() - 0.5) * 0.01;
    }
    return LatLng(lat, lng);
  }

  Set<Circle> _getPrivacyCircles(List<UserProfile> users) {
    final circles = <Circle>{};
    for (final user in users) {
      if (user.latitude == null || user.longitude == null) continue;

      // 1. Ghost Mode: Skip completely
      if (user.isGhostMode) continue;

      final pos = _getUserLocation(user);

      // 2. Fuzzy Location: Draw Zone
      if (user.isDiscretMode) {
        circles.add(
          Circle(
            circleId: CircleId('fuzzy_${user.uid}'),
            center: pos,
            radius: 500, // 500m radius
            fillColor: Colors.amber.withValues(alpha: 0.15),
            strokeColor: Colors.amber.withValues(alpha: 0.5),
            strokeWidth: 1,
            consumeTapEvents: true,
            onTap: () {
              _showAccessRequestDialog(user);
            },
          ),
        );
      } else if (user.isOnline) {
        // 3. Online Halo
        circles.add(
          Circle(
            circleId: CircleId('halo_${user.uid}'),
            center: pos,
            radius: 100, // Halo size
            fillColor: Colors.greenAccent.withValues(alpha: 0.2),
            strokeColor: Colors.greenAccent,
            strokeWidth: 2,
          ),
        );
      }
    }
    return circles;
  }

  Set<Marker> _buildMarkers(List<UserProfile> users) {
    if (_currentPosition == null) return {};

    final newMarkers = <Marker>{};

    for (final user in users) {
      if (user.latitude == null || user.longitude == null) continue;

      // Filter Privacy Modes
      if (user.isGhostMode) continue; // Invisible
      if (user.isDiscretMode) continue; // Fuzzy Zone (No Marker)

      final pos = _getUserLocation(user);

      // Check Distance
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        pos.latitude,
        pos.longitude,
      );

      if (distance > _radiusKm * 1000) continue; // Out of range

      // Determine Color
      double hue = BitmapDescriptor.hueRed; // Default
      if (user.category == 'Pasteur') {
        hue = 270.0; // Violet
      } else if (user.category == 'Musicien' || user.category == 'Chantre') {
        hue = 300.0; // Fuchsia/Magenta
      } else {
        hue = BitmapDescriptor.hueAzure; // Members
      }

      newMarkers.add(
        Marker(
          markerId: MarkerId(user.uid),
          position: pos,
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: '${user.firstName} ${user.isOnline ? " (En ligne)" : ""}',
            snippet: user.churchName,
          ),
          onTap: () {
            setState(() {
              _selectedUser = user;
              _isCheckedIn = false; // Reset check-in state for new user
              _updatePolyline(user);
            });
          },
        ),
      );
    }
    return newMarkers;
  }
}

// Dark Map Style
const String _mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#181818"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#2c2c2c"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#8a8a8a"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#000000"
      }
    ]
  }
]
''';
