import 'dart:math' as math show cos, pi, sin;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/notification_service.dart';
import '../../services/georadar_service.dart';
import '../theme/app_theme.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hasPermission = false;
  Position? _currentPosition;
  List<DocumentSnapshot> _nearbyUsers = [];
  final double _scanRadiusMeters = 5000; // 5km range for radar visual

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    NotificationService().init();
    _checkPermissionAndInit();
  }

  Future<void> _checkPermissionAndInit() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      if (mounted) setState(() => _hasPermission = true);
      _initRadar();
    }
  }

  Future<void> _requestPermission() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      if (mounted) setState(() => _hasPermission = true);
      _initRadar();
    }
  }

  Future<void> _initRadar() async {
    try {
      // 1. Get current location
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _currentPosition = pos;
      });

      final radarService = ref.read(geoRadarServiceProvider);
      // 2. Start GeoFirestore scan
      radarService.startScan(
        initialRadiusMeters: _scanRadiusMeters,
        center: GeoPoint(pos.latitude, pos.longitude),
        onFound: (docs) {
          if (!mounted) return;
          setState(() {
            _nearbyUsers = docs;
          });
          _checkProximity(docs);
        },
      );
    } catch (e) {
      debugPrint('Radar init error: $e');
    }
  }

  void _checkProximity(List<DocumentSnapshot> docs) {
    if (_currentPosition == null) return;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final geo = data['geo'] as Map<String, dynamic>;
      final gp = geo['geopoint'] as GeoPoint;

      // Calculate distance
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        gp.latitude,
        gp.longitude,
      );

      // Alert if < 100m
      if (distance < 100) {
        _triggerAlert(data['role'] ?? 'Membre', distance);
        break; // Alert once per scan update
      }
    }
  }

  void _triggerAlert(String role, double distance) {
    HapticFeedback.heavyImpact();
    NotificationService().showNotification(
      id: 1,
      title: 'Proximité Détectée !',
      body: 'Un $role est à ${distance.toStringAsFixed(0)}m !',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    ref.read(geoRadarServiceProvider).stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(geoRadarServiceProvider);
    // Keep the provider alive by watching it

    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.radar, size: 80, color: Colors.white24),
              const SizedBox(height: 20),
              const Text(
                'Le Radar nécessite votre localisation',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _requestPermission,
                icon: const Icon(Icons.location_on),
                label: const Text('Activer le Radar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Stack(
          children: [
            // Radar Sweep Animation
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  return Transform.rotate(
                    angle: _controller.value * 2 * math.pi,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.transparent,
                            AppTheme.primaryColor.withValues(alpha: 0.1),
                            AppTheme.primaryColor.withValues(alpha: 0.5),
                          ],
                          stops: const [0.5, 0.75, 1.0],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Concentric Circles
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (int i = 1; i <= 3; i++)
                    Container(
                      width: 100.0 * i,
                      height: 100.0 * i,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Render dots for nearby users
            if (_currentPosition != null)
              ..._nearbyUsers.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final geo = data['geo'] as Map<String, dynamic>;
                final gp = geo['geopoint'] as GeoPoint;

                // Calculate relative position
                final distance = Geolocator.distanceBetween(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  gp.latitude,
                  gp.longitude,
                );

                final bearing = Geolocator.bearingBetween(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  gp.latitude,
                  gp.longitude,
                );

                // Map to screen (max radius 150px = 500m)
                final r = (distance / _scanRadiusMeters) * 150.0;
                if (r > 150) return const SizedBox();

                final theta = (bearing * math.pi / 180.0);
                final x = r * math.sin(theta);
                final y = -r * math.cos(theta);

                final isPastor = (data['role'] == 'Pasteur');

                return Transform.translate(
                  offset: Offset(x, y),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isPastor
                              ? const Color(0xFF800080)
                              : Colors.greenAccent,
                          isPastor
                              ? const Color(0xFF800080)
                              : Colors.greenAccent,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isPastor
                                      ? const Color(0xFF800080)
                                      : Colors.greenAccent)
                                  .withValues(alpha: 0.8),
                          blurRadius: 5,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            // Center Icon (Me)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDF00FF),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDF00FF).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.radar, color: Colors.white, size: 30),
            ),
            // Text
            Positioned(
              bottom: 150,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Scanning... ${_nearbyUsers.length} trouvé(s)',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
