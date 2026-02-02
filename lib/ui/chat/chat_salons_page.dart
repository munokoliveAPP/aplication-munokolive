import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:munokolive_music/models/user_profile.dart';
import 'package:munokolive_music/providers/user_provider.dart';
import 'package:munokolive_music/ui/chat/controllers/chat_controller.dart';
import 'package:munokolive_music/ui/widgets/glass_container.dart';
import 'package:munokolive_music/ui/widgets/animated_background.dart';
import 'package:munokolive_music/ui/chat/salon_chat_page.dart';

class ChatSalonsPage extends ConsumerStatefulWidget {
  const ChatSalonsPage({super.key});

  @override
  ConsumerState<ChatSalonsPage> createState() => _ChatSalonsPageState();
}

class _ChatSalonsPageState extends ConsumerState<ChatSalonsPage> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final joinedSalonsAsync = ref.watch(joinedSalonsListProvider);
    final mutedSalons = ref.watch(mutedSalonsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Salons Professionnels"),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Fond animé cohérent
          const Positioned.fill(child: AnimatedBackground()),

          userAsync.when(
            data: (user) {
              if (user == null) {
                return const Center(child: Text("Non connecté"));
              }

              return joinedSalonsAsync.when(
                data: (joinedSalons) =>
                    _buildSalonsList(user, joinedSalons.toSet(), mutedSalons),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) {
                  // Fallback: Show salons even if fetching memberships fails
                  // This ensures the page is never "empty"
                  return _buildSalonsList(user, {}, mutedSalons);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text("Erreur: $e")),
          ),
        ],
      ),
    );
  }

  Widget _buildSalonsList(
    UserProfile user,
    Set<String> joinedSalons,
    Set<String> mutedSalons,
  ) {
    final isAdmin = user.role == 'admin' || user.role == 'super_admin';
    final category = user.category;
    final subCategory = user.subCategory ?? '';

    // L'administrateur a tous les droits d'accès
    final isMusician =
        isAdmin ||
        category.contains('Musicien') ||
        category.contains('Chantre') ||
        category.contains('Instrumentiste') ||
        category.contains('Artiste') ||
        subCategory.contains('Musicien') ||
        subCategory.contains('Chantre') ||
        subCategory.contains('Instrumentiste');

    final isPastor =
        isAdmin ||
        category.contains('Homme de Dieu') ||
        category.contains('Pasteur') ||
        category.contains('Prophète') ||
        category.contains('Apôtre') ||
        category.contains('Évêque') ||
        category.contains('Leader');

    return AnimationLimiter(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            horizontalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            const Text(
              "Espaces Communautaires",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Rejoignez les discussions dédiées à votre ministère.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),

            // 1. Salon des Musicos
            _buildSalonCard(
              id: 'musicos',
              title: "Salon des Musicos",
              subtitle: "Pour les chantres, instrumentistes et techniciens.",
              icon: Icons.queue_music_rounded,
              color: Colors.cyanAccent,
              gradient: [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
              canAccess: isAdmin || isMusician,
              user: user,
              joinedSalons: joinedSalons,
              mutedSalons: mutedSalons,
            ),

            const SizedBox(height: 20),

            // 2. Salon des Hommes de Dieu
            _buildSalonCard(
              id: 'pastors',
              title: "Hommes de Dieu",
              subtitle: "Leaders, Pasteurs et Organisateurs d'événements.",
              icon: Icons.church_rounded,
              color: Colors.amberAccent,
              gradient: [const Color(0xFFFFD700), const Color(0xFFFF8C00)],
              canAccess: isAdmin || isPastor,
              user: user,
              joinedSalons: joinedSalons,
              mutedSalons: mutedSalons,
            ),

            if (isAdmin) ...[
              const SizedBox(height: 40),
              const Divider(color: Colors.white24),
              const SizedBox(height: 20),
              _buildAdminPanel(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSalonCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
    required bool canAccess,
    required UserProfile user,
    required Set<String> joinedSalons,
    required Set<String> mutedSalons,
  }) {
    final isJoined = joinedSalons.contains(id);
    final isMuted = mutedSalons.contains(id);
    final isAdmin = user.role == 'admin' || user.role == 'super_admin';

    return GlassContainer(
      height: 180,
      width: double.infinity,
      borderRadius: 24,
      blur: 15,
      opacity: 0.1,
      border: Border.all(
        color: canAccess
            ? color.withValues(alpha: 0.3)
            : Colors.grey.withValues(alpha: 0.1),
        width: 1.5,
      ),
      child: Stack(
        children: [
          // Background Glow
          if (canAccess)
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: gradient[0].withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!canAccess)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Text(
                                "ACCÈS RÉSERVÉ",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (canAccess && isJoined)
                      IconButton(
                        icon: Icon(
                          isMuted
                              ? Icons.notifications_off
                              : Icons.notifications_active,
                          color: isMuted ? Colors.grey : color,
                        ),
                        onPressed: () {
                          final notifier = ref.read(
                            mutedSalonsProvider.notifier,
                          );
                          if (isMuted) {
                            notifier.update((state) => {...state}..remove(id));
                          } else {
                            notifier.update((state) => {...state}..add(id));
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isMuted
                                    ? "Notifications activées"
                                    : "Notifications coupées",
                              ),
                              backgroundColor: Colors.black87,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Action Buttons
                if (canAccess)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (isJoined) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SalonChatPage(
                                    salonId: id,
                                    salonTitle: title,
                                    themeColor: color,
                                  ),
                                ),
                              );
                            } else {
                              // Join Logic via Controller
                              await ref
                                  .read(chatControllerProvider(id))
                                  .joinSalon();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isJoined
                                ? Colors.white.withValues(alpha: 0.1)
                                : gradient[0],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: isJoined ? 0 : 8,
                            shadowColor: gradient[0].withValues(alpha: 0.4),
                          ),
                          child: Text(
                            isJoined
                                ? "Ouvrir la discussion"
                                : isAdmin
                                ? "Entrer (Mode Admin)"
                                : "Rejoindre le Salon",
                          ),
                        ),
                      ),
                      if (isJoined) ...[
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () async {
                            // Leave Logic via Controller
                            await ref
                                .read(chatControllerProvider(id))
                                .leaveSalon();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: BorderSide(
                              color: Colors.redAccent.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Quitter"),
                        ),
                      ],
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: null, // Disabled
                      icon: const Icon(Icons.lock, size: 16),
                      label: const Text("Vous n'avez pas le profil requis"),
                      style: OutlinedButton.styleFrom(
                        disabledForegroundColor: Colors.grey,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPanel() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      opacity: 0.3,
      borderRadius: 16,
      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      child: const Row(
        children: [
          Icon(Icons.admin_panel_settings, color: Colors.blueAccent),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mode Omniprésent Actif",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Vous voyez tous les salons en tant qu'administrateur.",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
