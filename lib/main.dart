/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munokolive_music/ui/auth/complete_profile_page.dart';
import 'package:munokolive_music/ui/auth/login_page.dart';
import 'package:munokolive_music/ui/auth/waiting_screen.dart';
import 'package:munokolive_music/ui/navigation/main_screen.dart';
import 'package:munokolive_music/ui/widgets/offline_error_screen.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';
import 'package:munokolive_music/providers/theme_provider.dart';
import 'package:munokolive_music/providers/user_provider.dart';
import 'package:munokolive_music/ui/auth/update_password_page.dart'; // Added
import 'package:munokolive_music/ui/onboarding/onboarding_screen.dart'; // Added
import 'package:munokolive_music/providers/onboarding_provider.dart'; // Added
import 'package:munokolive_music/ui/auth/biometric_gate.dart'; // Added

import 'package:flutter/foundation.dart'; // For kReleaseMode
import 'package:munokolive_music/ui/widgets/global_error_widget.dart'; // Added
import 'package:munokolive_music/ui/widgets/offline_indicator.dart'; // Added
import 'package:munokolive_music/ui/widgets/user_status_listener.dart'; // Added
import 'package:munokolive_music/app_bootstrap.dart';
import 'package:intl/date_symbol_data_local.dart'; // For locale initialization
import 'package:munokolive_music/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final navigatorKey = GlobalKey<NavigatorState>();

// Global variable to store initialization errors
// Note: Maintenant géré par AppBootstrap, mais gardé pour compatibilité AuthWrapper temporaire
String? globalInitializationError;

void main() async {
  // L'initialisation robuste est déléguée à AppBootstrap
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  // 0. Global Error Handling (Robustesse)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("Global Async Error: $error");
    return true;
  };

  // Custom Error Widget for Build Phase Errors
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return GlobalErrorWidget(errorDetails: details, isRelease: kReleaseMode);
  };

  runApp(const AppBootstrap());
}

class MunoKoLiveApp extends ConsumerStatefulWidget {
  const MunoKoLiveApp({super.key});

  @override
  ConsumerState<MunoKoLiveApp> createState() => _MunoKoLiveAppState();
}

class _MunoKoLiveAppState extends ConsumerState<MunoKoLiveApp> {
  @override
  void initState() {
    super.initState();
    // Listen for Auth Changes (Deep Link handling)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const UpdatePasswordPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Munokolive Music',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'), // Français
        Locale('en'), // English
      ],
      home: const BiometricGate(child: AuthWrapper()),
      // 3. Fluidité & Transitions "Cross-fade"
      builder: (context, child) {
        return OfflineIndicator(
          child: UserStatusListener(
            // Listen for Role/Status changes
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(
                overscroll: false,
              ), // Supprime l'effet "Glow" standard
              child: child!,
            ),
          ),
        );
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check for initialization errors first
    if (globalInitializationError != null) {
      return GlobalErrorWidget(
        error: globalInitializationError,
        isRelease: kReleaseMode,
        onRetry: () {
          // Restart app fully?
          // For now just try to re-render, but init errors are usually fatal until restart
        },
      );
    }

    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final hasSeenOnboarding = ref.watch(onboardingProvider);

    // 1. Prioritize Data (Cache/Online)
    // Even if there is an error (offline) or loading, if we have data, we show it.
    if (userProfileAsync.hasValue) {
      final userProfile = userProfileAsync.value;

      if (userProfile != null) {
        // Check if user is validated or active
        final isAllowedAccess =
            userProfile.status == 'validated' ||
            userProfile.status == 'active' ||
            userProfile.role == 'admin';

        // Check if profile is incomplete (Name and Photo are mandatory)
        final isProfileIncomplete =
            userProfile.firstName.isEmpty ||
            userProfile.photoUrl == null ||
            userProfile.photoUrl!.isEmpty;

        if (isAllowedAccess) {
          // Force Profile Completion if Name is missing
          if (isProfileIncomplete) {
            return CompleteProfilePage(
              user: Supabase.instance.client.auth.currentUser!,
            );
          }
          return const MainScreen();
        } else if (userProfile.status == 'pending') {
          // If pending, allow to complete profile first
          if (isProfileIncomplete) {
            return CompleteProfilePage(
              user: Supabase.instance.client.auth.currentUser!,
            );
          }
          // If profile is filled but status is still pending -> Waiting Screen
          return const WaitingScreen();
        } else {
          // Blocked or other status
          return const WaitingScreen();
        }
      } else {
        // userProfile is NULL -> Not logged in OR User not found in DB
        // CAS CRITIQUE : Utilisateur connecté mais pas de profil dans la table 'users'
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          debugPrint(
            "⚠️ AuthWrapper: User authenticated but profile missing. Redirecting to CompleteProfile.",
          );
          return CompleteProfilePage(user: currentUser);
        }

        // User is not logged in
        if (!hasSeenOnboarding) {
          return const OnboardingScreen();
        }
        // Show LoginPage if onboarding is done
        return const LoginPage();
      }
    }

    // 2. Handle Errors (Only if NO data)
    if (userProfileAsync.hasError) {
      final err = userProfileAsync.error;
      final errorStr = err.toString();
      // Detect network issues (Supabase exceptions often wrap SocketException)
      final isNetworkError =
          errorStr.contains('SocketException') ||
          errorStr.contains('ClientException') ||
          errorStr.contains('Network request failed') ||
          errorStr.contains('Failed host lookup');

      if (isNetworkError) {
        // Since we have no data, we MUST show an error screen.
        // But user wants "continuer a naviger".
        // If no data, we can't navigate.
        // We show the Retry screen.
        return OfflineErrorScreen(
          onRetry: () => ref.refresh(currentUserProfileProvider),
        );
      }

      // Generic Error Screen
      return GlobalErrorWidget(
        error: err,
        isRelease: kReleaseMode,
        onRetry: () => ref.refresh(currentUserProfileProvider),
      );
    }

    // 3. Loading State (Only if NO data and NO error)
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
    );
  }
}
