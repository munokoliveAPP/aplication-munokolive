/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'dart:ui';
import 'dart:async'; // Added for Timer
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';
import 'package:munokolive_music/ui/navigation/main_screen.dart'; // Added for fallback navigation
import '../theme/app_theme.dart';
import 'package:munokolive_music/l10n/app_localizations.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController(); // Added
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _referralCodeFocus = FocusNode(); // Added

  late ConfettiController _confettiController;

  bool _isLoading = false;
  bool _isLogin = true;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool _isFocused = false;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  late AnimationController _backgroundController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _skeletonController;

  // State for visual progress
  double _progressValue = 0.0;
  String _loadingText = '';
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _skeletonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _emailFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);
    _confirmPasswordFocus.addListener(_onFocusChange);
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose(); // Added
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _referralCodeFocus.dispose(); // Added
    _backgroundController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _skeletonController.dispose();
    _confettiController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused =
          _emailFocus.hasFocus ||
          _passwordFocus.hasFocus ||
          _confirmPasswordFocus.hasFocus;
    });
  }

  void _validateEmail() {
    final val = _emailController.text.trim();
    String? error;
    if (val.isNotEmpty && !val.contains('@')) {
      error = AppLocalizations.of(context)!.invalidEmail;
    }
    if (error != _emailError) {
      if (error != null) {
        HapticFeedback.lightImpact();
      }
      setState(() => _emailError = error);
    }
  }

  void _validateConfirmPassword() {
    if (_isLogin) {
      return;
    }
    final val = _confirmPasswordController.text;
    String? error;
    if (val.isNotEmpty && val != _passwordController.text) {
      error = AppLocalizations.of(context)!.passwordsMismatch;
    }
    if (error != _confirmPasswordError) {
      if (error != null) {
        HapticFeedback.lightImpact();
      }
      setState(() => _confirmPasswordError = error);
    }
  }

  void _validatePassword() {
    final val = _passwordController.text;
    String? error;
    if (val.isNotEmpty && val.length < 6) {
      error = AppLocalizations.of(context)!.passwordMinLength;
    }
    if (error != _passwordError) {
      if (error != null) {
        HapticFeedback.lightImpact();
      }
      setState(() => _passwordError = error);
    }
    if (!_isLogin && _confirmPasswordController.text.isNotEmpty) {
      _validateConfirmPassword();
    }
  }

  Widget _buildSkeletonInput() {
    return AnimatedBuilder(
      animation: _skeletonController,
      builder: (context, child) {
        return Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withValues(
              alpha:
                  0.1 + 0.1 * math.sin(_skeletonController.value * 2 * math.pi),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrbitingIcon(Widget child, double angleOffset) {
    const double rad = math.pi / 180;
    const double radius = 65; // Reduced distance from center
    const double center = 80; // Center for 160x160 container
    final double angle = (_rotationController.value * 360 + angleOffset) * rad;

    final double x =
        center + radius * -1 * math.sin(angle); // -sin for clockwise
    final double y = center + radius * -1 * math.cos(angle);

    return Positioned(
      left: x - 13, // Center the icon (size 26)
      top: y - 13,
      child: Transform.rotate(
        angle: -angle, // Keep icon upright
        child: child,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.fixFormErrors),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Reset progress
    setState(() {
      _isLoading = true;
      _progressValue = 0.0;
      _loadingText = AppLocalizations.of(context)!.initializing;
    });

    // Start Visual Progress Timer
    _startProgressTimer();

    try {
      final auth = ref.read(authServiceProvider);
      if (_isLogin) {
        setState(
          () => _loadingText = AppLocalizations.of(context)!.authenticating,
        );
        await auth.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // Success
        setState(() {
          _progressValue = 1.0;
          _loadingText = AppLocalizations.of(context)!.success;
        });
        _confettiController.play();
        HapticFeedback.heavyImpact();

        // Force refresh user profile to avoid "stuck" state
        ref.invalidate(userProfileProvider);

        // Artificial delay for effect & ensure state propagation
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          // Explicitly check navigation if AuthWrapper didn't take over
          final user = Supabase.instance.client.auth.currentUser;
          if (user != null) {
            setState(
              () => _loadingText = AppLocalizations.of(context)!.redirecting,
            );

            // FALLBACK NAVIGATION: If AuthWrapper doesn't react within 2 seconds
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted &&
                  Supabase.instance.client.auth.currentUser != null) {
                // Check if we are still on this screen (login page)
                // We can't easily check if we are still top route, but we can try to pushReplacement
                // However, AuthWrapper is the parent. If we pushReplacement, we replace AuthWrapper?
                // No, LoginPage is child of AuthWrapper (via BiometricGate).
                // If we are here, it means AuthWrapper is still rendering LoginPage.

                // Let's force a reload of the whole app structure or just push MainScreen
                debugPrint("⚠️ AuthWrapper stuck. Forcing navigation.");

                // Safest bet: Navigate to MainScreen and let MainScreen redirect if needed?
                // Or CompleteProfilePage if we suspect profile is missing.

                // If we push MainScreen, we bypass AuthWrapper logic for this session.
                // That's acceptable for a fallback to unblock the user.
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                );
              }
            });
          }
        }
      } else {
        setState(() => _loadingText = AppLocalizations.of(context)!.verifying);
        final referralCode = _referralCodeController.text.trim();
        if (referralCode.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.referralCodeRequired),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        final referrerId = await auth.validateReferralCode(referralCode);
        if (!mounted) return;

        if (referrerId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.invalidReferralCode),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        setState(
          () => _loadingText = AppLocalizations.of(context)!.creatingAccount,
        );
        await auth.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          {'referred_by': referrerId, 'referrer_code': referralCode},
        );

        setState(() {
          _progressValue = 1.0;
          _loadingText = AppLocalizations.of(context)!.welcome;
        });
        _confettiController.play();
        HapticFeedback.heavyImpact();

        ref.invalidate(userProfileProvider);
        await Future.delayed(const Duration(milliseconds: 1500));
      }
      // Navigation is handled by authStateChanges
    } catch (e) {
      _progressTimer?.cancel();
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _progressValue = 0.0;
          _loadingText = "";
        });

        String message = l10n.genericError;
        final errorStr = e.toString();

        if (errorStr.contains('invalid-credential') ||
            errorStr.contains('wrong-password') ||
            errorStr.contains('user-not-found') ||
            errorStr.contains('Invalid login credentials')) {
          // Security: Report failed attempt for Brute Force Protection
          try {
            await Supabase.instance.client.rpc('record_failed_login');
          } catch (_) {
            // Fail silently if reporting fails (don't block UI)
          }

          message = l10n.invalidCredentials;

          // Re-check mounted after async call
          if (!mounted) return;
        } else if (errorStr.contains('over_email_send_rate_limit') ||
            errorStr.contains(
              'For security purposes, you can only request this after',
            )) {
          // Supabase rate limit when too many verification emails are requested
          message = l10n.securityDelay;
        } else if (errorStr.contains('User already registered')) {
          message = l10n.emailInUse;
        } else if (errorStr.contains('Unable to validate email address')) {
          message = l10n.invalidEmailMessage;
        } else if (errorStr.contains(
          'Password should be at least 6 characters',
        )) {
          message = l10n.weakPassword;
        } else if (errorStr.contains('network-request-failed') ||
            errorStr.contains('SocketException')) {
          message = l10n.networkError;
        } else if (errorStr.contains('rate-limited') ||
            errorStr.contains('Too many requests')) {
          message = l10n.rateLimitError;
        } else {
          message =
              '${l10n.errorPrefix}${errorStr.replaceAll(RegExp(r'\[.*?\]'), '').trim()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action:
                (errorStr.contains('invalid-credential') ||
                    errorStr.contains('user-not-found') ||
                    errorStr.contains('Invalid login credentials'))
                ? SnackBarAction(
                    label: AppLocalizations.of(
                      context,
                    )!.registerButton.toUpperCase(),
                    textColor: Colors.white,
                    onPressed: () => setState(() => _isLogin = false),
                  )
                : null,
          ),
        );
      }
    } finally {
      if (mounted) {
        // Don't set isLoading to false immediately on success to keep the "Success" state visible until nav
        if (_progressValue < 1.0) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_progressValue < 0.9) {
          _progressValue += 0.05;
        } else {
          // Slow down near the end
          if (_progressValue < 0.95) _progressValue += 0.005;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Animated Background with Theme Gradient
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.backgroundGradientStart,
                      AppTheme.backgroundDark,
                      AppTheme.backgroundGradientStart.withValues(
                        alpha: 0.5 + 0.5 * _backgroundController.value,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Floating Orbs
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 50,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                    blurRadius: 50,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // Confetti (Moved to end of Stack)

          // Focus Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isFocused ? 0.7 : 0.0,
                child: Container(color: Colors.black),
              ),
            ),
          ),

          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo with Orbiting Icons
                            SizedBox(
                              width: 160,
                              height: 160,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Rotating Gradient Ring
                                  AnimatedBuilder(
                                    animation: _rotationController,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle:
                                            _rotationController.value *
                                            2 *
                                            3.14159,
                                        child: Container(
                                          width: 110,
                                          height: 110,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: SweepGradient(
                                              colors: [
                                                AppTheme.primaryColor
                                                    .withValues(alpha: 0.0),
                                                AppTheme.primaryColor,
                                                AppTheme.primaryColor
                                                    .withValues(alpha: 0.0),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // Orbiting Icons (Guitar only)
                                  AnimatedBuilder(
                                    animation: _rotationController,
                                    builder: (context, child) {
                                      return Stack(
                                        children: [
                                          // Swirling Guitar (Music Note as placeholder for Guitar)
                                          _buildOrbitingIcon(
                                            Transform.rotate(
                                              angle: -0.5, // Tilted
                                              child: Icon(
                                                Icons
                                                    .queue_music, // Represents the guitar
                                                color: AppTheme.primaryColor
                                                    .withValues(alpha: 0.9),
                                                size: 32,
                                              ),
                                            ),
                                            0, // Angle 0
                                          ),
                                        ],
                                      );
                                    },
                                  ),

                                  // Central Logo
                                  AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale:
                                            0.9 + 0.1 * _pulseController.value,
                                        child: Container(
                                          width: 90,
                                          height: 90,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            // color: AppTheme.textPrimary, // Removed white background
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.primaryColor
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 20,
                                                spreadRadius: 5,
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: Image.asset(
                                              'assets/Logo.png',
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Titre Lumineux
                            const Text(
                              'Munokolive',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                shadows: [
                                  Shadow(
                                    color: AppTheme.primaryColor,
                                    blurRadius: 20,
                                  ),
                                  Shadow(
                                    color: AppTheme.primaryColor,
                                    blurRadius: 40,
                                  ),
                                  Shadow(
                                    color: AppTheme.textPrimary,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Login Form
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 50 * (1 - value)),
                                  child: Opacity(opacity: value, child: child),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(
                                  maxWidth: 500,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.textPrimary.withValues(
                                      alpha: 0.2,
                                    ),
                                    width: 1.5,
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.textPrimary.withValues(
                                        alpha: 0.1,
                                      ),
                                      AppTheme.textPrimary.withValues(
                                        alpha: 0.05,
                                      ),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 20,
                                      sigmaY: 20,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 500,
                                              ),
                                              child: Text(
                                                _isLogin
                                                    ? AppLocalizations.of(
                                                        context,
                                                      )!.welcomeBack
                                                    : AppLocalizations.of(
                                                        context,
                                                      )!.joinFamily,
                                                key: ValueKey<bool>(_isLogin),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _isLogin
                                                  ? AppLocalizations.of(
                                                      context,
                                                    )!.loginToContinue
                                                  : AppLocalizations.of(
                                                      context,
                                                    )!.createAccountSubtitle,
                                              style: TextStyle(
                                                color: AppTheme.textSecondary
                                                    .withValues(alpha: 0.7),
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            if (_isLoading) ...[
                                              _buildSkeletonInput(),
                                              const SizedBox(height: 16),
                                              _buildSkeletonInput(),
                                            ] else ...[
                                              TextFormField(
                                                controller: _emailController,
                                                focusNode: _emailFocus,
                                                style: const TextStyle(
                                                  color: AppTheme.textPrimary,
                                                ),
                                                textInputAction:
                                                    TextInputAction.next,
                                                decoration: InputDecoration(
                                                  labelText:
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.emailLabel,
                                                  labelStyle: const TextStyle(
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                                  errorText: _emailError,
                                                  prefixIcon: const Icon(
                                                    Icons.email,
                                                    color:
                                                        AppTheme.primaryColor,
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: Colors.grey
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                        ),
                                                      ),
                                                  focusedBorder: AppTheme
                                                      .inputBorderActive,
                                                  filled: true,
                                                  fillColor: AppTheme
                                                      .backgroundDark
                                                      .withValues(alpha: 0.5),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                        horizontal: 16,
                                                      ),
                                                ),
                                                validator: (val) {
                                                  if (val == null ||
                                                      val.isEmpty) {
                                                    return AppLocalizations.of(
                                                      context,
                                                    )!.emailRequired;
                                                  }
                                                  if (!val.contains('@')) {
                                                    return AppLocalizations.of(
                                                      context,
                                                    )!.invalidEmail;
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 24),
                                              TextFormField(
                                                controller: _passwordController,
                                                focusNode: _passwordFocus,
                                                obscureText: obscurePassword,
                                                style: const TextStyle(
                                                  color: AppTheme.textPrimary,
                                                ),
                                                textInputAction: _isLogin
                                                    ? TextInputAction.done
                                                    : TextInputAction.next,
                                                onFieldSubmitted: (_) {
                                                  if (_isLogin) {
                                                    _submit();
                                                  } else {
                                                    FocusScope.of(
                                                      context,
                                                    ).requestFocus(
                                                      _confirmPasswordFocus,
                                                    );
                                                  }
                                                },
                                                decoration: InputDecoration(
                                                  labelText:
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.passwordLabel,
                                                  labelStyle: const TextStyle(
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                                  errorText: _passwordError,
                                                  prefixIcon: const Icon(
                                                    Icons.lock,
                                                    color:
                                                        AppTheme.primaryColor,
                                                  ),
                                                  suffixIcon: IconButton(
                                                    icon: Icon(
                                                      obscurePassword
                                                          ? Icons.visibility_off
                                                          : Icons.visibility,
                                                      color: AppTheme
                                                          .textSecondary,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        obscurePassword =
                                                            !obscurePassword;
                                                      });
                                                    },
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: Colors.grey
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                        ),
                                                      ),
                                                  focusedBorder: AppTheme
                                                      .inputBorderActive,
                                                  filled: true,
                                                  fillColor: AppTheme
                                                      .backgroundDark
                                                      .withValues(alpha: 0.5),
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                        horizontal: 16,
                                                      ),
                                                ),
                                                validator: (val) =>
                                                    val!.length < 6
                                                    ? AppLocalizations.of(
                                                        context,
                                                      )!.passwordMinLength
                                                    : null,
                                              ),
                                              if (!_isLogin) ...[
                                                const SizedBox(height: 24),
                                                TextFormField(
                                                  controller:
                                                      _confirmPasswordController,
                                                  focusNode:
                                                      _confirmPasswordFocus,
                                                  obscureText:
                                                      obscureConfirmPassword,
                                                  style: const TextStyle(
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                  textInputAction:
                                                      TextInputAction.next,
                                                  onFieldSubmitted: (_) =>
                                                      FocusScope.of(
                                                        context,
                                                      ).requestFocus(
                                                        _referralCodeFocus,
                                                      ),
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.confirmPasswordLabel,
                                                    labelStyle: const TextStyle(
                                                      color: AppTheme
                                                          .textSecondary,
                                                    ),
                                                    errorText:
                                                        _confirmPasswordError,
                                                    prefixIcon: const Icon(
                                                      Icons.lock_outline,
                                                      color:
                                                          AppTheme.primaryColor,
                                                    ),
                                                    suffixIcon: IconButton(
                                                      icon: Icon(
                                                        obscureConfirmPassword
                                                            ? Icons
                                                                  .visibility_off
                                                            : Icons.visibility,
                                                        color: AppTheme
                                                            .textSecondary,
                                                      ),
                                                      onPressed: () => setState(
                                                        () => obscureConfirmPassword =
                                                            !obscureConfirmPassword,
                                                      ),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          borderSide:
                                                              BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .withValues(
                                                                      alpha:
                                                                          0.3,
                                                                    ),
                                                              ),
                                                        ),
                                                    focusedBorder: AppTheme
                                                        .inputBorderActive,
                                                    filled: true,
                                                    fillColor: AppTheme
                                                        .backgroundDark
                                                        .withValues(alpha: 0.5),
                                                  ),
                                                  validator: (val) {
                                                    if (val !=
                                                        _passwordController
                                                            .text) {
                                                      return AppLocalizations.of(
                                                        context,
                                                      )!.passwordsMismatch;
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 24),
                                                TextFormField(
                                                  controller:
                                                      _referralCodeController,
                                                  focusNode: _referralCodeFocus,
                                                  style: const TextStyle(
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                  textInputAction:
                                                      TextInputAction.done,
                                                  onFieldSubmitted: (_) =>
                                                      _submit(),
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.referralCodeLabel,
                                                    labelStyle: const TextStyle(
                                                      color: AppTheme
                                                          .textSecondary,
                                                    ),
                                                    prefixIcon: const Icon(
                                                      Icons.people,
                                                      color:
                                                          AppTheme.primaryColor,
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          borderSide:
                                                              BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .withValues(
                                                                      alpha:
                                                                          0.3,
                                                                    ),
                                                              ),
                                                        ),
                                                    focusedBorder: AppTheme
                                                        .inputBorderActive,
                                                    filled: true,
                                                    fillColor: AppTheme
                                                        .backgroundDark
                                                        .withValues(alpha: 0.5),
                                                  ),
                                                  validator: (val) {
                                                    if (val == null ||
                                                        val.trim().isEmpty) {
                                                      return AppLocalizations.of(
                                                        context,
                                                      )!.referralCodeRequired;
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ],
                                            ],
                                            if (_isLogin && !_isLoading)
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8.0,
                                                      ),
                                                  child: TextButton(
                                                    onPressed: () async {
                                                      final email =
                                                          _emailController.text
                                                              .trim();
                                                      if (email.isEmpty) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              AppLocalizations.of(
                                                                context,
                                                              )!.pleaseEnterEmail,
                                                            ),
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                        );
                                                        return;
                                                      }
                                                      try {
                                                        await ref
                                                            .read(
                                                              authServiceProvider,
                                                            )
                                                            .sendPasswordResetEmail(
                                                              email,
                                                            );
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                AppLocalizations.of(
                                                                  context,
                                                                )!.resetEmailSent,
                                                              ),
                                                              backgroundColor:
                                                                  Colors.green,
                                                            ),
                                                          );
                                                        }
                                                      } catch (e) {
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                '${AppLocalizations.of(context)!.errorPrefix}$e',
                                                              ),
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    },
                                                    style: TextButton.styleFrom(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                    child: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.forgotPassword,
                                                      style: TextStyle(
                                                        color: AppTheme
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.8,
                                                            ),
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                        decorationColor:
                                                            AppTheme
                                                                .primaryColor
                                                                .withValues(
                                                                  alpha: 0.5,
                                                                ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(height: 24),
                                            Container(
                                              width: double.infinity,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                gradient:
                                                    AppTheme.buttonGradient,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.primaryColor
                                                        .withValues(alpha: 0.4),
                                                    blurRadius: 16,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: ElevatedButton(
                                                onPressed: _isLoading
                                                    ? null
                                                    : _submit,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  shadowColor:
                                                      Colors.transparent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  _isLogin
                                                      ? 'SE CONNECTER'
                                                      : 'REJOINDRE LA FAMILLE',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Google Sign In Removed
                                            const SizedBox(height: 24),
                                            GestureDetector(
                                              onTap: () => setState(
                                                () => _isLogin = !_isLogin,
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                      horizontal: 24,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme
                                                      .backgroundLight
                                                      .withValues(alpha: 0.5),
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                  border: Border.all(
                                                    color: AppTheme.primaryColor
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: RichText(
                                                  text: TextSpan(
                                                    text: _isLogin
                                                        ? 'Pas encore de compte ? '
                                                        : 'Déjà un compte ? ',
                                                    style: TextStyle(
                                                      color: AppTheme
                                                          .textPrimary
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                      fontSize: 14,
                                                    ),
                                                    children: [
                                                      TextSpan(
                                                        text: _isLogin
                                                            ? 'Créer un compte'
                                                            : 'Se connecter',
                                                        style: const TextStyle(
                                                          color: AppTheme
                                                              .primaryColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Confetti Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14159 / 2, // down
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Circular Progress with Value
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: _progressValue,
                            strokeWidth: 6,
                            color: AppTheme.primaryColor,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        Text(
                          '${(_progressValue * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Loading Text
                    Text(
                      _loadingText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Simple Linear Progress Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progressValue,
                          backgroundColor: Colors.white24,
                          color: AppTheme.primaryColor,
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
