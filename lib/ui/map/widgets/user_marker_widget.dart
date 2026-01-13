import 'package:flutter/material.dart';

class UserMarkerWidget extends StatelessWidget {
  final String? photoUrl;
  final bool isOnline;

  const UserMarkerWidget({super.key, this.photoUrl, this.isOnline = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 60, // Extra space for arrow
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Arrow (Triangle at bottom)
          Positioned(
            bottom: 0,
            child: ClipPath(
              clipper: ArrowClipper(),
              child: Container(width: 15, height: 10, color: Colors.white),
            ),
          ),
          // Circle Profile
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: photoUrl != null
                  ? Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: Colors.grey,
                        size: 24,
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.grey, size: 24),
            ),
          ),
          // Online Dot
          if (isOnline)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
