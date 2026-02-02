/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';
import 'package:munokolive_music/models/user_profile.dart';
import 'package:munokolive_music/providers/user_provider.dart';

// Provider to fetch referrals
final referralsProvider = FutureProvider.autoDispose
    .family<List<UserProfile>, String>((ref, userId) async {
      final supabase = Supabase.instance.client;

      // Fetch users referred by this userId
      // Note: referred_by in DB is UUID of the referrer
      final response = await supabase
          .from('users')
          .select()
          .eq('referred_by', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => UserProfile.fromJson(json)).toList();
    });

class ReferralTreePage extends ConsumerStatefulWidget {
  const ReferralTreePage({super.key});

  @override
  ConsumerState<ReferralTreePage> createState() => _ReferralTreePageState();
}

class _ReferralTreePageState extends ConsumerState<ReferralTreePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final referralsAsync = ref.watch(referralsProvider(currentUser.id));

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Mon Arbre de Parrainage'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Animated Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.backgroundGradientStart,
                  AppTheme.backgroundDark,
                ],
              ),
            ),
          ),

          // Particles / Tree Roots Effect
          Positioned.fill(
            child: CustomPaint(
              painter: TreeRootsPainter(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                animationValue: _controller,
              ),
            ),
          ),

          SafeArea(
            child: referralsAsync.when(
              data: (referrals) {
                if (referrals.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.nature_people,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Votre arbre est encore jeune.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Invitez des amis avec votre code parrain pour le faire grandir !',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        // Display Current User Code
                        _buildMyCodeCard(currentUser.id),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header Card with Stats
                      _buildHeaderStats(referrals.length),
                      const SizedBox(height: 24),

                      // My Code
                      _buildMyCodeCard(currentUser.id),
                      const SizedBox(height: 32),

                      // Tree Visualization
                      const Text(
                        "Vos Filleuls Directs",
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // List of Referrals
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: referrals.length,
                        itemBuilder: (context, index) {
                          final user = referrals[index];
                          return _buildReferralCard(user, index);
                        },
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  'Erreur: $err',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.8),
            AppTheme.secondaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text(
                "Total Filleuls",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                "$count",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(height: 40, width: 1, color: Colors.white30),
          const Column(
            children: [
              Text(
                "Points Gagnés",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                "Coming Soon", // Placeholder for points logic
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyCodeCard(String userId) {
    // We need to fetch the referral code of the current user.
    // Assuming we can get it from the user provider or fetch it.
    // For now, let's use a FutureBuilder for just the code if not available in context

    // Actually, let's try to get it from the user profile provider if available
    // But since we are in a widget, we can watch it.

    return Consumer(
      builder: (context, ref, child) {
        final userProfileAsync = ref.watch(currentUserProfileProvider);

        return userProfileAsync.when(
          data: (profile) {
            final code = profile?.referralCode ?? 'Chargement...';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Votre Code Parrain",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Partagez ce code",
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        code,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: code));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Code copié dans le presse-papiers !",
                                ),
                                backgroundColor: AppTheme.primaryColor,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.copy,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildReferralCard(UserProfile user, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
          backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
              ? NetworkImage(user.photoUrl!)
              : null,
          child: user.photoUrl == null || user.photoUrl!.isEmpty
              ? Text(
                  user.firstName.isNotEmpty
                      ? user.firstName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          user.category,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
            const SizedBox(height: 4),
            Text(
              "Filleul",
              style: TextStyle(
                color: Colors.greenAccent.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TreeRootsPainter extends CustomPainter {
  final Color color;
  final Animation<double> animationValue;

  TreeRootsPainter({required this.color, required this.animationValue})
    : super(repaint: animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Draw some organic lines resembling roots/branches
    // Using animation value to make them breathe slightly
    final w = size.width;
    final h = size.height;
    final val = animationValue.value * 10;

    path.moveTo(w * 0.5, h);
    path.quadraticBezierTo(w * 0.5, h * 0.8, w * 0.2, h * 0.6 + val);

    path.moveTo(w * 0.5, h);
    path.quadraticBezierTo(w * 0.5, h * 0.8, w * 0.8, h * 0.6 - val);

    path.moveTo(w * 0.5, h * 0.8);
    path.quadraticBezierTo(w * 0.4, h * 0.7, w * 0.1, h * 0.5 + val);

    path.moveTo(w * 0.5, h * 0.8);
    path.quadraticBezierTo(w * 0.6, h * 0.7, w * 0.9, h * 0.5 - val);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TreeRootsPainter oldDelegate) => true;
}
