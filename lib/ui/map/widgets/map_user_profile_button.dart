import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/auth_service.dart';
import '../../admin/widgets/control_center_sheet.dart';
import '../../theme/app_theme.dart';

class MapUserProfileButton extends ConsumerWidget {
  const MapUserProfileButton({super.key});

  void _openControlCenter(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ControlCenter',
      barrierColor: Colors.black54,
      pageBuilder: (context, anim1, anim2) {
        return const ControlCenterSheet();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Center(
      child: GestureDetector(
        onTap: () => _openControlCenter(context),
        child: Hero(
          tag: 'user_avatar_control',
          child: userAsync.when(
            data: (user) {
              final photoUrl = user?.photoUrl;
              final firstName = user?.firstName ?? '';

              return Stack(
                children: [
                  // Main Profile Photo
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: AppTheme.backgroundDark,
                      backgroundImage: photoUrl != null
                          ? CachedNetworkImageProvider(photoUrl)
                          : null,
                      child: photoUrl == null
                          ? Text(
                              firstName.isNotEmpty
                                  ? firstName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),
                  ),
                  // Miniature Settings Icon Badge
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: const CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 2,
              ),
            ),
            error: (_, __) => Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withValues(alpha: 0.2),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: const Icon(Icons.error_outline, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
