import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munokolive_music/providers/user_provider.dart';
import 'package:munokolive_music/providers/navigation_provider.dart';
import 'package:munokolive_music/models/user_profile.dart';
import 'package:munokolive_music/ui/auth/login_page.dart';
import 'package:munokolive_music/ui/widgets/buttons/urgent_pulse_button.dart';
import 'package:munokolive_music/ui/settings/settings_page.dart';
import 'package:munokolive_music/providers/notification_feed_provider.dart';
import 'package:munokolive_music/ui/notifications/notifications_sheet.dart';
import 'package:munokolive_music/ui/chat/chat_salons_page.dart';
import 'package:munokolive_music/ui/widgets/cached_circle_avatar.dart';
import 'package:munokolive_music/ui/widgets/modals/urgent_mission_modal.dart';
import 'package:confetti/confetti.dart';
import 'package:munokolive_music/ui/music_groups/music_groups_page.dart';
import 'package:munokolive_music/ui/home/widgets/reward_cards_carousel.dart';
import 'package:munokolive_music/ui/home/widgets/nearby_event_card.dart';
import 'package:munokolive_music/ui/profile/view_profile_page.dart';
import 'package:marquee/marquee.dart';
import 'package:munokolive_music/providers/salon_stats_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _blinkController;
  late ConfettiController _confettiController;
  // ScrollController removed as unused for now

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _blinkController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  bool _isNewMember(UserProfile user) {
    if (user.createdAt == null) return false;
    // createdAt is already a DateTime in UserProfile model
    return DateTime.now().difference(user.createdAt!).inDays < 7;
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final ghostModeUserId = ref.watch(ghostModeUserIdProvider);

    // --- Live Salon Notifications ---
    ref.listen<int>(salonStatsProvider('musicos'), (prev, next) {
      if (prev != null && next > prev) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.music_note, color: Colors.white),
                SizedBox(width: 10),
                Text("Le Salon des Musiciens s'active !"),
              ],
            ),
            backgroundColor: Colors.cyan.withValues(alpha: 0.8),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });

    ref.listen<int>(salonStatsProvider('pastors'), (prev, next) {
      if (prev != null && next > prev) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.church, color: Colors.white),
                SizedBox(width: 10),
                Text("Un Homme de Dieu est en ligne !"),
              ],
            ),
            backgroundColor: Colors.amber.withValues(alpha: 0.8),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F0518), // Deep purple/black bg
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: userAsync.when(
        data: (user) => user == null
            ? null
            : Container(
                margin: const EdgeInsets.only(bottom: 50),
                child: UrgentPulseButton(
                  isAdmin: user.role == 'admin',
                  isNewMember: _isNewMember(user),
                  onUrgentTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const UrgentMissionModal(),
                    );
                  },
                ),
              ),
        loading: () => null,
        error: (_, _) => null,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const LoginPage();

          return Stack(
            children: [
              // Background gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1A0B2E),
                        const Color(0xFF0F0518),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // Decorative circles
              Positioned(
                top: -100,
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purpleAccent.withValues(alpha: 0.1),
                    boxShadow: [BoxShadow(blurRadius: 100)],
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    if (ghostModeUserId != null)
                      _buildGhostModeBanner(ref, user),

                    // Header (always visible)
                    _buildTopBar(user),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            _buildWelcomeHeader(user),
                            const SizedBox(height: 20),

                            // 1. REWARD CARDS CAROUSEL (Top)
                            const RewardCardsCarousel(),

                            const SizedBox(height: 20),

                            // 2. MIDDLE ROW (Lieux Favoris + Chat)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _buildFeatureTiles(context),
                            ),

                            const SizedBox(height: 20),

                            // 3. EVENT CARD (Bottom)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _buildMainCard(),
                            ),

                            const SizedBox(height: 20),

                            const SizedBox(height: 100), // Space for FAB
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Confetti Overlay
              Align(
                alignment: Alignment.center,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple,
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.purpleAccent),
        ),
        error: (e, st) => Center(child: Text("Erreur: $e")),
      ),
    );
  }

  Widget _buildTopBar(UserProfile user) {
    // Watch notifications to show badge
    final notificationsAsync = ref.watch(notificationFeedProvider);
    final hasNotifications = notificationsAsync.maybeWhen(
      data: (items) => items.isNotEmpty,
      orElse: () => false,
    );

    // Check for active mission notifications (pending or broadcasted)
    bool hasActiveMission = false;
    notificationsAsync.whenData((items) {
      hasActiveMission = items.any(
        (i) =>
            i.type == 'mission_update' &&
            (i.body.contains('diffusion') || i.body.contains('attente')),
      );
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                // Enlarged Profile Pic
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewProfilePage(userId: user.id),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.purpleAccent.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: CachedCircleAvatar(
                      imageUrl: user.photoUrl,
                      radius: 20, // Reduced slightly to save space
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bonjour,",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "${user.firstName} ${user.lastName}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16, // Reduced from 20 to 16
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Actions Group (Notifications & Settings)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Notifications Button
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const NotificationsSheet(),
                        );
                      },
                    ),
                    if (hasNotifications)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: FadeTransition(
                          opacity: _pulseController,
                          child: Container(
                            width: hasActiveMission ? 14 : 10,
                            height: hasActiveMission ? 14 : 10,
                            decoration: BoxDecoration(
                              color: hasActiveMission
                                  ? Colors.orangeAccent
                                  : Colors.redAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (hasActiveMission
                                              ? Colors.orange
                                              : Colors.red)
                                          .withValues(alpha: 0.5),
                                  blurRadius: hasActiveMission ? 8 : 5,
                                  spreadRadius: hasActiveMission ? 3 : 2,
                                ),
                              ],
                            ),
                            child: hasActiveMission
                                ? const Icon(
                                    Icons.priority_high,
                                    size: 10,
                                    color: Colors.black,
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),

                // Divider
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.white.withValues(alpha: 0.2),
                ),

                // Settings Button
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(UserProfile user) {
    return _buildInfoBar();
  }

  Widget _buildInfoBar() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('app_config')
          .stream(primaryKey: ['id'])
          .eq('id', 1),
      builder: (context, snapshot) {
        final message = (snapshot.hasData && snapshot.data!.isNotEmpty)
            ? snapshot.data!.first['ai_message'] as String?
            : null;

        final displayMessage = (message != null && message.isNotEmpty)
            ? message
            : "Bienvenue sur Munokolive Music ! Restez connectés pour les dernières mises à jour.";

        return Container(
          width: double.infinity,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.cyanAccent.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              // INFO Badge
              FadeTransition(
                opacity: Tween<double>(begin: 0.2, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _blinkController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Container(
                  width: 70,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.cyanAccent.withValues(alpha: 0.3),
                        Colors.cyanAccent.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "INFO",
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text("📢", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                "///",
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Marquee(
                  text: displayMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    fontFamily: 'Courier',
                  ),
                  scrollAxis: Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  blankSpace: 20.0,
                  velocity: 30.0,
                  pauseAfterRound: const Duration(seconds: 1),
                  startPadding: 10.0,
                  accelerationDuration: const Duration(seconds: 1),
                  accelerationCurve: Curves.linear,
                  decelerationDuration: const Duration(milliseconds: 500),
                  decelerationCurve: Curves.easeOut,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyStateCard() {
    return NearbyEventCard(
      event: null,
      onTap: () {
        ref.read(navigationProvider.notifier).setIndex(1);
      },
    );
  }

  Widget _buildMainCard() {
    // STREAM EN TEMPS RÉEL
    final eventStream = Supabase.instance.client
        .from('events')
        .stream(primaryKey: ['id'])
        .order('date', ascending: true)
        .limit(10);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: eventStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyStateCard();
        }

        final now = DateTime.now();
        final events = snapshot.data!
            .map((e) {
              e['parsedDate'] = DateTime.parse(e['date']);
              return e;
            })
            .where((e) {
              final date = e['parsedDate'] as DateTime;
              final isFuture = date.isAfter(now);
              final isOngoing =
                  date.isBefore(now) && date.difference(now).abs().inHours < 3;
              return isFuture || isOngoing;
            })
            .toList();

        events.sort((a, b) {
          final dateA = a['parsedDate'] as DateTime;
          final dateB = b['parsedDate'] as DateTime;
          return dateA.compareTo(dateB);
        });

        if (events.isEmpty) {
          return _buildEmptyStateCard();
        }

        final featuredEvent = events.first;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: NearbyEventCard(
            key: ValueKey(featuredEvent['id']),
            event: featuredEvent,
            onTap: () {
              ref.read(navigationProvider.notifier).setIndex(1);
            },
          ),
        );
      },
    );
  }

  Widget _buildTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80, // Match Chat Button height
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTiles(BuildContext context) {
    return Column(
      children: [
        // 1. Groupes Musicaux (Full Width)
        _buildTile(
          context,
          "Nos Groupes Musicaux",
          Icons.music_note_rounded,
          Colors.deepPurpleAccent,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MusicGroupsPage()),
            );
          },
        ),
        const SizedBox(height: 12),
        // 2. Live Salons Row
        Row(
          children: [
            Expanded(
              child: _buildLiveSalonCard(
                context,
                'musicos',
                "Musiciens",
                Icons.queue_music_rounded,
                Colors.cyanAccent,
                [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLiveSalonCard(
                context,
                'pastors',
                "Hommes de Dieu",
                Icons.church_rounded,
                Colors.amberAccent,
                [const Color(0xFFFFD700), const Color(0xFFFF8C00)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveSalonCard(
    BuildContext context,
    String id,
    String title,
    IconData icon,
    Color color,
    List<Color> gradient,
  ) {
    final count = ref.watch(salonStatsProvider(id));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatSalonsPage()),
        );
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              gradient[0].withValues(alpha: 0.2),
              gradient[1].withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: count > 0
                ? color.withValues(alpha: 0.6)
                : color.withValues(alpha: 0.2),
            width: count > 0 ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (count > 0)
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 15,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Text(
                      count == 0 ? "0" : "$count en direct",
                      key: ValueKey<int>(count),
                      style: TextStyle(
                        color: count > 0 ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (count > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, color: Colors.white, size: 6),
                      const SizedBox(width: 4),
                      const Text(
                        "LIVE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGhostModeBanner(WidgetRef ref, UserProfile user) {
    return Container(
      width: double.infinity,
      color: Colors.deepPurpleAccent,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "👻 Mode Fantôme Activé",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () {
              ref.read(ghostModeUserIdProvider.notifier).state = null;
            },
            child: const Text(
              "Quitter",
              style: TextStyle(
                color: Colors.white,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
