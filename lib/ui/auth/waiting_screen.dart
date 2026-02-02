import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:munokolive_music/services/auth_service.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';
import 'package:munokolive_music/ui/navigation/main_screen.dart';
import 'package:munokolive_music/providers/user_provider.dart';
import 'package:munokolive_music/l10n/app_localizations.dart';

class WaitingScreen extends ConsumerStatefulWidget {
  const WaitingScreen({super.key});

  @override
  ConsumerState<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends ConsumerState<WaitingScreen>
    with TickerProviderStateMixin {
  late Timer _timer;
  late DateTime _now;
  late Duration _countdown;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;

  // Variables pour la validation temps réel
  bool _isValidated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initializeDateFormatting(Localizations.localeOf(context).toString(), null);
  }

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // Compte à rebours de 24h pour l'effet visuel
    _countdown = const Duration(hours: 24);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
          if (_countdown.inSeconds > 0) {
            _countdown = _countdown - const Duration(seconds: 1);
          }
        });
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _handleValidationSuccess() {
    if (_isValidated) return; // Déjà traité

    setState(() {
      _isValidated = true;
    });

    // Arrêt des animations inutiles
    _rotationController.stop();
    _pulseController.repeat(
      reverse: true,
    ); // Garder le pulse pour la célébration

    // Petit délai pour la célébration avant navigation
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Redirection vers l'accueil (MainScreen)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _launchWhatsApp() async {
    final Uri url = Uri.parse('https://wa.me/2250777916407');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.cannotOpenWhatsApp),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écouter les mises à jour du profil utilisateur en temps réel
    ref.listen(currentUserProfileProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && user.isValidated && mounted) {
          _handleValidationSuccess();
        }
      });
    });

    // Formatters
    final dateFormat = DateFormat.yMMMMEEEEd(
      Localizations.localeOf(context).toString(),
    );

    // Countdown string
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final countdownStr =
        "${twoDigits(_countdown.inHours)}H ${twoDigits(_countdown.inMinutes.remainder(60))}M ${twoDigits(_countdown.inSeconds.remainder(60))}S";

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E0024), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              children: [
                // Date Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    dateFormat.format(_now).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const Spacer(),

                // Hero Section: Animated Logo & Countdown
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Glow (Devient Vert/Or si validé)
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 280 * _pulseAnimation.value,
                          height: 280 * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                _isValidated
                                    ? Colors.greenAccent.withValues(alpha: 0.3)
                                    : AppTheme.primaryColor.withValues(
                                        alpha: 0.2,
                                      ),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.7],
                            ),
                          ),
                        );
                      },
                    ),

                    // Rotating Rings (Disparaissent si validé)
                    if (!_isValidated) ...[
                      RotationTransition(
                        turns: _rotationController,
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const CircularProgressIndicator(
                            value: 0.75,
                            strokeWidth: 2,
                            color: Colors
                                .transparent, // Hack to just use container border
                          ),
                        ),
                      ),
                      RotationTransition(
                        turns: Tween(
                          begin: 1.0,
                          end: 0.0,
                        ).animate(_rotationController),
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 230,
                              height: 230,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(
                                  BorderSide(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.5,
                                    ),
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Anneau de succès statique
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.greenAccent.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                      ),
                    ],

                    // Central Logo
                    Container(
                      width: 180,
                      height: 180,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: _isValidated
                                ? Colors.greenAccent.withValues(alpha: 0.5)
                                : AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _isValidated
                            ? const Icon(
                                Icons.check_circle_outline,
                                color: Colors.greenAccent,
                                size: 100,
                              )
                            : Image.asset(
                                'assets/images/Logo.png',
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Status Text
                if (_isValidated)
                  Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.congratulations,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontFamily: 'Montserrat',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.accountValidated,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.redirectionInProgress,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.verificationInProgress,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontFamily: 'Montserrat',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        countdownStr,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          shadows: [
                            Shadow(
                              color: AppTheme.primaryColor,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          AppLocalizations.of(context)!.profileAnalysisMessage,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),

                const Spacer(),

                // Action Buttons
                if (!_isValidated)
                  Column(
                    children: [
                      // Bouton "Actualiser" (Fallback Solution)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Action A & B : Force Refresh
                            ref.invalidate(userProfileProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.refreshingStatus,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: Text(
                            AppLocalizations.of(context)!.refreshStatusButton,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                            shadowColor: AppTheme.primaryColor.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _launchWhatsApp,
                              icon: const Icon(Icons.support_agent),
                              label: Text(
                                AppLocalizations.of(context)!.supportButton,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.1,
                                ),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await ref.read(authServiceProvider).signOut();
                              },
                              icon: const Icon(
                                Icons.logout,
                                color: Colors.redAccent,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.quitButton,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.1,
                                ),
                                foregroundColor: Colors.redAccent,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: BorderSide(
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
