import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munokolive_music/models/user_profile.dart';
import 'package:munokolive_music/providers/rewards_provider.dart';
import 'package:munokolive_music/ui/widgets/cached_circle_avatar.dart';
import 'package:munokolive_music/ui/profile/view_profile_page.dart';
import 'package:confetti/confetti.dart';

class RewardCardsCarousel extends ConsumerStatefulWidget {
  const RewardCardsCarousel({super.key});

  @override
  ConsumerState<RewardCardsCarousel> createState() =>
      _RewardCardsCarouselState();
}

class _RewardCardsCarouselState extends ConsumerState<RewardCardsCarousel> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  late ConfettiController _confettiController;
  final Set<String> _congratulatedUserIds = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // Auto-scroll logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage >= 4) {
          // Assuming 4 cards
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _stopAutoScroll() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bestWorker = ref.watch(bestWorkerProvider);
    final bestSponsor = ref.watch(bestSponsorProvider);
    final bestMusician = ref.watch(bestMusicianProvider);
    final bestManOfGod = ref.watch(bestManOfGodProvider);

    final cards = [
      _buildCardWrapper(
        context,
        title: "MEILLEUR OUVRIER",
        userAsync: bestWorker,
        primaryColor: Colors.purpleAccent,
        icon: Icons.engineering,
      ),
      _buildCardWrapper(
        context,
        title: "MEILLEUR PARRAIN",
        userAsync: bestSponsor,
        primaryColor: Colors.greenAccent,
        icon: Icons.handshake,
      ),
      _buildCardWrapper(
        context,
        title: "MEILLEUR MUSICIEN",
        userAsync: bestMusician,
        primaryColor: Colors.amber,
        icon: Icons.music_note,
      ),
      _buildCardWrapper(
        context,
        title: "MEILLEUR HOMME DE DIEU",
        userAsync: bestManOfGod,
        primaryColor: Colors.cyanAccent,
        icon: Icons.church,
        isLight: true,
      ),
    ];

    return Stack(
      alignment: Alignment.center,
      children: [
        Listener(
          onPointerDown: (_) => _stopAutoScroll(),
          onPointerUp: (_) {
            // Restart with a slight delay to allow user to finish reading/interaction
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) _startAutoScroll();
            });
          },
          onPointerCancel: (_) => _startAutoScroll(),
          child: SizedBox(
            height:
                190, // Increased slightly to prevent clipping of shadows/buttons
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: cards,
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
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
  }

  Widget _buildCardWrapper(
    BuildContext context, {
    required String title,
    required AsyncValue<UserProfile?> userAsync,
    required Color primaryColor,
    required IconData icon,
    bool isLight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: _buildCard(
        context,
        title: title,
        userAsync: userAsync,
        primaryColor: primaryColor,
        icon: icon,
        isLight: isLight,
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required AsyncValue<UserProfile?> userAsync,
    required Color primaryColor,
    required IconData icon,
    bool isLight = false,
  }) {
    return userAsync.when(
      data: (user) {
        // Fallback if no user found, use a placeholder user for display
        final displayUser =
            user ??
            UserProfile(
              id: 'placeholder',
              firstName: 'À',
              lastName: 'Venir',
              email: '',
              points: 0,
              role: 'user',
              createdAt: DateTime.now(),
              category: '',
              photoUrl: null, // Will use default avatar
            );

        final isPlaceholder = displayUser.id == 'placeholder';

        return Container(
          width: double.infinity, // Fill the PageView item
          height: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: 0.2),
                primaryColor.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.1),
                blurRadius: 15,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "LIVE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.info_outline,
                        color: isLight ? Colors.black54 : Colors.white54,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  // Profile Pic with Glow
                  GestureDetector(
                    onTap: () {
                      if (!isPlaceholder) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ViewProfilePage(userId: displayUser.id),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.8),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: isPlaceholder
                          ? CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey.withValues(
                                alpha: 0.2,
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: Colors.white54,
                                size: 28,
                              ),
                            )
                          : CachedCircleAvatar(
                              imageUrl: displayUser.photoUrl,
                              radius: 28,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!isPlaceholder) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ViewProfilePage(userId: displayUser.id),
                            ),
                          );
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: primaryColor.withValues(alpha: 0.9),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${displayUser.firstName} ${displayUser.lastName}",
                            style: TextStyle(
                              color: isLight ? Colors.white : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isPlaceholder
                                ? "En attente"
                                : "${displayUser.points} pts",
                            style: TextStyle(
                              color: isLight ? Colors.white70 : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Congratulate Button (Bottom Right)
              if (!isPlaceholder)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final isCongratulated = _congratulatedUserIds.contains(
                        displayUser.id,
                      );

                      return GestureDetector(
                        onTap: isCongratulated
                            ? null
                            : () {
                                setState(() {
                                  _congratulatedUserIds.add(displayUser.id);
                                });
                                _confettiController.play();

                                // Haptic feedback
                                // HapticFeedback.mediumImpact(); // Optional if services available

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "Félicitations envoyées à ${displayUser.firstName} ! 👏",
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isCongratulated
                                ? Colors.green.withValues(alpha: 0.8)
                                : primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isCongratulated
                                  ? Colors.green
                                  : primaryColor.withValues(alpha: 0.5),
                            ),
                            boxShadow: isCongratulated
                                ? [
                                    BoxShadow(
                                      color: Colors.green.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCongratulated
                                    ? Icons.check
                                    : Icons.celebration,
                                color: isCongratulated
                                    ? Colors.white
                                    : primaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isCongratulated ? "Envoyé" : "Féliciter",
                                style: TextStyle(
                                  color: isCongratulated
                                      ? Colors.white
                                      : primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => _buildSkeleton(primaryColor),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildSkeleton(Color color) {
    return Container(
      width: 280,
      height: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: CircularProgressIndicator(color: color, strokeWidth: 2),
      ),
    );
  }
}
