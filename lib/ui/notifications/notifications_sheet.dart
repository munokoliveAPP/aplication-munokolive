/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munokolive_music/providers/notification_feed_provider.dart';
import 'package:munokolive_music/ui/admin/super_admin_dashboard.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';
import 'package:munokolive_music/providers/navigation_provider.dart';

import 'package:munokolive_music/ui/widgets/smart_snackbar.dart';
import 'package:munokolive_music/ui/widgets/cached_circle_avatar.dart';
import 'package:munokolive_music/ui/chat/salon_chat_page.dart';
import 'package:munokolive_music/ui/profile/view_profile_page.dart';
import 'package:munokolive_music/ui/widgets/modals/mission_status_dialog.dart';

class NotificationsSheet extends ConsumerWidget {
  const NotificationsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationFeedProvider);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: const Color(0xFF1E0024).withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Notifications",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          // Clear notifications permanently (until new ones arrive)
                          ref
                              .read(notificationFeedProvider.notifier)
                              .clearAll();
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white70,
                        ),
                        tooltip: "Tout effacer",
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text(
                          "Récents",
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: notificationsAsync.when(
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 60,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Aucune nouvelle notification",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) async {
                          await ref
                              .read(notificationFeedProvider.notifier)
                              .dismissNotification(item.id);
                          if (context.mounted) {
                            SmartSnackBar.show(
                              context,
                              message: "Notification supprimée",
                              isSuccess: true,
                            );
                          }
                        },
                        background: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.redAccent.withValues(alpha: 0.9),
                                Colors.deepPurple.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: const Icon(
                            Icons.delete_sweep_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        child: _buildNotificationItem(context, ref, item),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    "Erreur: $e",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),

            // Mark as read button (automatic on open usually, but let's keep it clean)
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) {
    IconData icon;
    Color color;

    if (item.type == 'validation_request') {
      icon = Icons.admin_panel_settings;
      color = Colors.orangeAccent;
    } else if (item.type == 'salon') {
      icon = Icons.forum;
      color = Colors.cyanAccent;
    } else if (item.type == 'message_prive') {
      icon = Icons.chat_bubble;
      color = Colors.pinkAccent;
    } else if (item.type == 'mission_update') {
      icon = Icons.emergency_share;
      color = Colors.deepOrangeAccent;
    } else if (item.title.contains("Lieu")) {
      icon = Icons.place;
      color = Colors.greenAccent;
    } else if (item.title.contains("Événement")) {
      icon = Icons.event;
      color = Colors.purpleAccent;
    } else {
      icon = Icons.notifications;
      color = Colors.blueAccent;
    }

    return GestureDetector(
      onTap: () {
        final navigator = Navigator.of(context);
        navigator.pop(); // Close sheet
        if (item.type == 'salon' && item.targetId != null) {
          final isMusicos = item.targetId == 'musicos';
          navigator.push(
            MaterialPageRoute(
              builder: (_) => SalonChatPage(
                salonId: item.targetId!,
                salonTitle: isMusicos
                    ? "Salon des Musiciens"
                    : "Salon des Pasteurs",
                themeColor: isMusicos ? Colors.cyanAccent : Colors.amber,
              ),
            ),
          );
        } else if (item.type == 'message_prive' && item.targetId != null) {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => ViewProfilePage(userId: item.targetId!),
            ),
          );
        } else if (item.type == 'mission_update' && item.targetId != null) {
          showDialog(
            context: context,
            builder: (_) => MissionStatusDialog(requestId: item.targetId!),
          );
        } else if (item.targetRoute != null) {
          if (item.targetRoute!.startsWith('/admin')) {
            navigator.push(
              MaterialPageRoute(builder: (_) => const SuperAdminDashboard()),
            );
          } else if (item.targetRoute == '/place/details') {
            // Switch to Places tab
            ref.read(navigationProvider.notifier).setIndex(4); // Places Index
          } else if (item.targetRoute == '/event/details') {
            // Switch to Events tab
            ref.read(navigationProvider.notifier).setIndex(1); // Events Index
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            if (item.avatarUrl != null)
              CachedCircleAvatar(imageUrl: item.avatarUrl!, radius: 24)
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(item.timestamp),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (item.targetId != null || item.targetRoute != null)
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white24,
                size: 14,
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return "Il y a ${diff.inMinutes} min";
    } else if (diff.inHours < 24) {
      return "Il y a ${diff.inHours} h";
    } else {
      return "${time.day}/${time.month}";
    }
  }
}
