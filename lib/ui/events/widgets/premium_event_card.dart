import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/event_model.dart';
import '../../theme/app_theme.dart';
import '../../../services/notification_service.dart';
import '../../../services/carpool_service.dart'; // Import CarpoolService
import '../../../services/auth_service.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../widgets/cached_image_widget.dart';

class PremiumEventCard extends ConsumerWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const PremiumEventCard({super.key, required this.event, this.onTap});

  bool get isLive {
    final now = DateTime.now();
    // Assuming event lasts 2 hours
    final end = event.date.add(const Duration(hours: 2));
    return now.isAfter(event.date) && now.isBefore(end);
  }

  bool get isSoon {
    final now = DateTime.now();
    final diff = event.date.difference(now);
    return diff.inHours > 0 && diff.inHours < 48;
  }

  Future<void> _openMap(BuildContext context) async {
    if (event.coordinates != null) {
      final lat = event.coordinates!.latitude;
      final lng = event.coordinates!.longitude;
      final googleMapsUrl = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
      );
      final appleMapsUrl = Uri.parse("https://maps.apple.com/?q=$lat,$lng");

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } else {
      final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(event.location)}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir la carte'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showCarpoolDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Covoiturage', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Membres proches de chez vous participant à l\'événement :',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: Consumer(
                  builder: (context, ref, child) {
                    final matchesAsync = ref.watch(
                      carpoolMatchesProvider(event.id),
                    );
                    return matchesAsync.when(
                      data: (matches) {
                        if (matches.isEmpty) {
                          return const Center(
                            child: Text(
                              'Aucun covoiturage trouvé pour le moment.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: matches.length,
                          itemBuilder: (context, index) {
                            final user = matches[index];
                            return ListTile(
                              leading: CachedCircleAvatar(
                                imageUrl: user.photoUrl,
                                fallbackText: user.firstName,
                                radius: 20,
                              ),
                              title: Text(
                                '${user.firstName} ${user.lastName}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                user.neighborhood ?? user.city ?? 'Inconnu',
                                style: const TextStyle(color: Colors.white54),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.chat_bubble_outline,
                                  color: AppTheme.primaryColor,
                                ),
                                onPressed: () {
                                  // Open Chat (Future implementation)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Chat avec ${user.firstName} bientôt disponible !',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(
                        child: Text(
                          'Erreur: $err',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authServiceProvider).currentUser;
    final isParticipating =
        currentUser != null && event.attendees.contains(currentUser.uid);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 320, // Increased height for more actions
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // ... Background Image & Gradient ...
              // Background Image
              Positioned.fill(
                child: Hero(
                  tag: 'event_image_${event.id}', // Hero Tag for transition
                  child: event.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: event.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[900],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF2A2A2A),
                          child: const Icon(
                            Icons.event,
                            size: 64,
                            color: Colors.white24,
                          ),
                        ),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(
                          alpha: 0.95,
                        ), // Darker at bottom
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // ... Badges (Status, Date) ...
              // Status Badge (Live / Soon)
              if (isLive || isSoon)
                Positioned(
                  top: 16,
                  right: 16,
                  child: GlassmorphicContainer(
                    width: isLive ? 80 : 100,
                    height: 32,
                    borderRadius: 16,
                    blur: 10,
                    alignment: Alignment.center,
                    border: 0,
                    linearGradient: LinearGradient(
                      colors: [
                        isLive
                            ? Colors.red.withValues(alpha: 0.6)
                            : Colors.amber.withValues(alpha: 0.6),
                        isLive
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.amber.withValues(alpha: 0.3),
                      ],
                    ),
                    borderGradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.5),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLive
                              ? Icons.fiber_manual_record
                              : Icons.access_time,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isLive ? 'EN COURS' : 'BIENTÔT',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Date Badge
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('dd').format(event.date),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(event.date).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Location & Time
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.access_time,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('HH:mm').format(event.date),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Social Proof (Pulse)
                      if (event.attendees.isNotEmpty) ...[
                        Row(
                          children: [
                            // Avatars Stack
                            SizedBox(
                              height: 32,
                              width:
                                  (event.attendees.length > 3
                                          ? 3
                                          : event.attendees.length) *
                                      24.0 +
                                  8,
                              child: Stack(
                                children: [
                                  for (
                                    int i = 0;
                                    i <
                                        (event.attendees.length > 3
                                            ? 3
                                            : event.attendees.length);
                                    i++
                                  )
                                    Positioned(
                                      left: i * 20.0,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const CachedCircleAvatar(
                                          radius: 15,
                                          fallbackText: '?',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+${event.attendees.length} y vont',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            // Heatmap Indicator (Trending)
                            if (event.attendees.length > 5)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.orange.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      color: Colors.orange,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'TRENDING',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Actions Row
                      Row(
                        children: [
                          // Primary Action: Participate or Map
                          Expanded(
                            flex: 2,
                            child: isParticipating
                                ? ElevatedButton.icon(
                                    onPressed: () =>
                                        _showCarpoolDialog(context, ref),
                                    icon: const Icon(
                                      Icons.directions_car,
                                      size: 18,
                                    ),
                                    label: const Text('Covoiturage'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: () async {
                                      await ref
                                          .read(carpoolServiceProvider)
                                          .participateInEvent(event);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Inscription réussie ! Points de fidélité ajoutés.',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                      size: 18,
                                    ),
                                    label: const Text('Je participe'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),

                          // Itinéraire (Small)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.map_outlined,
                                color: Colors.white,
                              ),
                              tooltip: 'Itinéraire',
                              onPressed: () => _openMap(context),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Notifications / Remind Me Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.notifications_active_outlined,
                                color: Colors.white,
                              ),
                              tooltip: 'M\'alerter (J-3, J-1, H-2)',
                              onPressed: () async {
                                await ref
                                    .read(notificationServiceProvider)
                                    .scheduleEventReminders(
                                      event.id,
                                      event.title,
                                      event.date,
                                    );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Rappels activés : J-3, J-1 et H-2 !',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
