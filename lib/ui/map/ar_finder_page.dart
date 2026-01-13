import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_profile.dart';

class ArFinderPage extends StatefulWidget {
  final UserProfile targetUser;
  final Position currentPosition;

  const ArFinderPage({
    super.key,
    required this.targetUser,
    required this.currentPosition,
  });

  @override
  State<ArFinderPage> createState() => _ArFinderPageState();
}

class _ArFinderPageState extends State<ArFinderPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  double? _heading;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initCompass();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(firstCamera, ResolutionPreset.medium);

    _initializeControllerFuture = _controller!.initialize();
    if (mounted) setState(() {});
  }

  void _initCompass() {
    FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted) {
        setState(() {
          _heading = event.heading;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller!);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),

          // AR Overlay
          if (_heading != null &&
              widget.targetUser.latitude != null &&
              widget.targetUser.longitude != null)
            _buildArOverlay(),

          // Back Button
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Info Card
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: widget.targetUser.photoUrl != null
                        ? CachedNetworkImageProvider(
                            widget.targetUser.photoUrl!,
                          )
                        : null,
                    child: widget.targetUser.photoUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Recherche de ${widget.targetUser.firstName}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Tournez-vous pour trouver la direction",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArOverlay() {
    // Calculate bearing to target
    final bearingToTarget = Geolocator.bearingBetween(
      widget.currentPosition.latitude,
      widget.currentPosition.longitude,
      widget.targetUser.latitude!,
      widget.targetUser.longitude!,
    );

    // Normalize bearing
    double relativeBearing = bearingToTarget - _heading!;
    while (relativeBearing < -180) {
      relativeBearing += 360;
    }
    while (relativeBearing > 180) {
      relativeBearing -= 360;
    }

    // Field of View check (approx 60 degrees for phone camera)
    if (relativeBearing.abs() > 30) {
      // Target is out of view, show arrow hint
      return Center(
        child: Icon(
          relativeBearing > 0 ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
          color: Colors.white.withValues(alpha: 0.5),
          size: 48,
        ),
      );
    }

    // Target is in view
    // Map relative bearing (-30 to 30) to screen horizontal position
    // Center is 0.
    // Screen width is usually associated with FOV.
    // Let's assume simplified projection.

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalOffset = (relativeBearing / 30) * (screenWidth / 2);

    final distance = Geolocator.distanceBetween(
      widget.currentPosition.latitude,
      widget.currentPosition.longitude,
      widget.targetUser.latitude!,
      widget.targetUser.longitude!,
    );

    return Center(
      child: Transform.translate(
        offset: Offset(horizontalOffset, -50), // slightly up
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.blue, blurRadius: 10),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 30),
                  Text(
                    "${distance.toInt()} m",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            CustomPaint(painter: ArrowPainter(), size: const Size(20, 20)),
          ],
        ),
      ),
    );
  }
}

class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
