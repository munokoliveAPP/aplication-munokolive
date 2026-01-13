import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../theme/app_theme.dart';

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
  final _confirmPasswordController = TextEditingController(); // Add this
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode(); // Add this

  bool _isLoading = false;
  bool _isLogin = true; // Toggle between Login and Sign Up
  bool obscurePassword = true;
  bool obscureConfirmPassword = true; // Add this
  bool _isFocused = false;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError; // Add this

  late AnimationController _backgroundController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _skeletonController;

  @override
  void initState() {
    super.initState();
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
    _confirmPasswordFocus.addListener(_onFocusChange); // Add this
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(
      _validateConfirmPassword,
    ); // Add this
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // Add this
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose(); // Add this
    _backgroundController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _skeletonController.dispose();
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
      error = 'Email invalide';
    }
    if (error != _emailError) {
      if (error != null) HapticFeedback.lightImpact();
      setState(() => _emailError = error);
    }
  }

  void _validateConfirmPassword() {
    if (_isLogin) return;
    final val = _confirmPasswordController.text;
    String? error;
    if (val.isNotEmpty && val != _passwordController.text) {
      error = 'Les mots de passe ne correspondent pas';
    }
    if (error != _confirmPasswordError) {
      if (error != null) HapticFeedback.lightImpact();
      setState(() => _confirmPasswordError = error);
    }
  }

  void _validatePassword() {
    final val = _passwordController.text;
    String? error;
    if (val.isNotEmpty && val.length < 6) {
      error = 'Min 6 caractères';
    }
    if (error != _passwordError) {
      if (error != null) HapticFeedback.lightImpact();
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

  Widget _buildOrbitingIcon(IconData icon, double angleOffset) {
    const double rad = math.pi / 180;
    const double radius = 65; // Reduced distance from center
    const double center = 80; // Center for 160x160 container
    final double angle = (_rotationController.value * 360 + angleOffset) * rad;

    final double x =
        center + radius * -1 * math.sin(angle); // -sin for clockwise
    final double y = center + radius * -1 * math.cos(angle);

    return Positioned(
      left: x - 15, // Center the icon (size 30)
      top: y - 15,
      child: Transform.rotate(
        angle: -angle, // Keep icon upright
        child: Icon(
          icon,
          color: AppTheme.primaryColor.withValues(alpha: 0.8),
          size: 26, // Slightly smaller icon
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez corriger les erreurs dans le formulaire'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = ref.read(authServiceProvider);
      if (_isLogin) {
        await auth.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await auth.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
      // Navigation is handled by authStateChanges
    } catch (e) {
      if (mounted) {
        String message = 'Une erreur est survenue';
        final errorStr = e.toString();

        if (errorStr.contains('invalid-credential') ||
            errorStr.contains('wrong-password') ||
            errorStr.contains('user-not-found')) {
          message =
              'Email ou mot de passe incorrect.\nSi vous n\'avez pas encore de compte, veuillez vous inscrire.';
        } else if (errorStr.contains('email-already-in-use')) {
          message = 'Cet email est déjà utilisé par un autre compte.';
        } else if (errorStr.contains('invalid-email')) {
          message = 'L\'adresse email est invalide.';
        } else if (errorStr.contains('weak-password')) {
          message = 'Le mot de passe est trop faible (6 caractères min).';
        } else if (errorStr.contains('network-request-failed')) {
          message = 'Problème de connexion internet.';
        } else if (errorStr.contains('rate-limited')) {
          message = 'Trop de tentatives. Veuillez patienter un moment.';
        } else {
          message =
              'Erreur: ${errorStr.replaceAll(RegExp(r'\[.*?\]'), '').trim()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action:
                (errorStr.contains('invalid-credential') ||
                    errorStr.contains('user-not-found'))
                ? SnackBarAction(
                    label: 'S\'INSCRIRE',
                    textColor: Colors.white,
                    onPressed: () => setState(() => _isLogin = false),
                  )
                : null,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

                                  // Orbiting Icons
                                  AnimatedBuilder(
                                    animation: _rotationController,
                                    builder: (context, child) {
                                      return Stack(
                                        children: [
                                          _buildOrbitingIcon(Icons.piano, 0),
                                          _buildOrbitingIcon(
                                            Icons.music_note,
                                            120,
                                          ),
                                          _buildOrbitingIcon(Icons.mic, 240),
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
                                          child: const Icon(
                                            Icons.music_note,
                                            size: 60, // Reduced size
                                            color: Colors
                                                .white, // White icon for better contrast
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
                                                    ? 'Heureux de vous revoir !'
                                                    : 'Rejoindre la Famille',
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
                                                  ? 'Connectez-vous pour continuer'
                                                  : 'Créez votre compte en quelques secondes',
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
                                                  labelText: 'Email',
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
                                                          color: AppTheme
                                                              .inputBorder
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                        ),
                                                      ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    borderSide: const BorderSide(
                                                      color: AppTheme
                                                          .inputBorderActive,
                                                    ),
                                                  ),
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
                                                    return 'Email requis';
                                                  }
                                                  if (!val.contains('@')) {
                                                    return 'Email invalide';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 16),
                                              TextFormField(
                                                controller: _passwordController,
                                                focusNode: _passwordFocus,
                                                obscureText: obscurePassword,
                                                style: const TextStyle(
                                                  color: AppTheme.textPrimary,
                                                ),
                                                textInputAction:
                                                    TextInputAction.done,
                                                onFieldSubmitted: (_) =>
                                                    _submit(),
                                                decoration: InputDecoration(
                                                  labelText: 'Mot de passe',
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
                                                          color: AppTheme
                                                              .inputBorder
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                        ),
                                                      ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    borderSide: const BorderSide(
                                                      color: AppTheme
                                                          .inputBorderActive,
                                                    ),
                                                  ),
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
                                                    ? 'Min 6 caractères'
                                                    : null,
                                              ),
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
                                                          const SnackBar(
                                                            content: Text(
                                                              'Veuillez entrer votre email',
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
                                                            const SnackBar(
                                                              content: Text(
                                                                'Email de réinitialisation envoyé',
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
                                                                'Erreur: $e',
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
                                                      'Mot de passe oublié ?',
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
                                            const SizedBox(height: 16),
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
                                                child: _isLoading
                                                    ? const CircularProgressIndicator(
                                                        color: Colors.white,
                                                      )
                                                    : Text(
                                                        _isLogin
                                                            ? 'SE CONNECTER'
                                                            : 'REJOINDRE LA FAMILLE',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                          letterSpacing: 1.5,
                                                        ),
                                                      ),
                                              ),
                                            ),

                                            // Google Login Button removed as per request
                                            const SizedBox(height: 16),
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
        ],
      ),
    );
  }
}
