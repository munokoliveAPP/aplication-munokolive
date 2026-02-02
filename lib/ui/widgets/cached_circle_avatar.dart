import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';

class CachedCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final VoidCallback? onTap;
  final Color? borderColor;

  const CachedCircleAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (borderColor ?? AppTheme.primaryColor).withValues(
                alpha: 0.5,
              ),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: borderColor ?? AppTheme.primaryColor,
            width: 2,
          ),
        ),
        child: ClipOval(
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: 200, // Optimisation mémoire
                  memCacheHeight: 200, // Optimisation mémoire
                  placeholder: (context, url) => Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.person, color: Colors.white54),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.error, color: Colors.red),
                  ),
                )
              : Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.person, color: Colors.white54),
                ),
        ),
      ),
    );
  }
}
