import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:munokolive_music/ui/navigation/main_screen.dart';
import 'package:munokolive_music/services/storage_service.dart';
import 'package:munokolive_music/services/auth_service.dart';
import 'package:munokolive_music/ui/auth/login_page.dart';
import 'package:munokolive_music/ui/auth/complete_profile_page.dart';
import 'package:munokolive_music/ui/auth/pending_approval_page.dart';
import 'package:munokolive_music/ui/widgets/extraordinary_splash_screen.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';
import 'firebase_options.dart';

import 'package:munokolive_music/services/watchdog_service.dart';
import 'package:munokolive_music/services/security_service.dart';
import 'package:munokolive_music/services/sync_service.dart';
import 'package:munokolive_music/services/notification_service.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:munokolive_music/ui/widgets/global_error_widget.dart';
import 'package:munokolive_music/ui/widgets/error_state_widget.dart';

void main() async {
  // Watchdog & Global Error Handling
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      WatchdogService.init();

      // Custom Error Widget for Release Mode
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return GlobalErrorWidget(
          errorDetails: details,
          isRelease: kReleaseMode,
        );
      };

      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        debugPrint('Firebase init error (ignored for dev): $e');
      }

      // Initialize locale data for date formatting (fr_FR used throughout the app)
      await initializeDateFormatting('fr_FR', null);

      final prefs = await SharedPreferences.getInstance();

      // Initialize Security Service (Check Root, Keys, etc.)
      final securityService = SecurityService();
      await securityService.initialize();

      runApp(
        ProviderScope(
          overrides: [
            // Inject security service into storage service if needed,
            // or just ensure singleton usage via provider if we want shared instance.
            // Since main.dart overrides storageServiceProvider manually:
            storageServiceProvider.overrideWithValue(
              StorageService(Future.value(prefs), securityService),
            ),
            // Override security service to use the one initialized here
            securityServiceProvider.overrideWithValue(securityService),
          ],
          child: const MunoKoLiveApp(),
        ),
      );
    },
    (error, stack) {
      // Catch errors outside Flutter (Async, etc.)
      WatchdogService.reportError(error, stack);
    },
  );
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
    // Start Background Sync Monitoring
    // We do this in initState to ensure it runs once on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).startMonitoring();

      // Initialize Notifications (Local & Timezone)
      ref.read(notificationServiceProvider).init();
    });
  }

  @override
  void dispose() {
    // Ideally stop monitoring, but main app usually lives forever.
    // ref.read(syncServiceProvider).stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'MunoKoLive Gospel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginPage();
          }

          // User is authenticated, check profile status
          return Consumer(
            builder: (context, ref, child) {
              final profileAsync = ref.watch(currentUserProfileProvider);

              return profileAsync.when(
                data: (profile) {
                  if (profile == null) {
                    // Profile not found, force completion
                    return CompleteProfilePage(user: user);
                  }

                  // Check if critical info is missing (first login)
                  if (profile.firstName.isEmpty || profile.lastName.isEmpty) {
                    return CompleteProfilePage(user: user);
                  }

                  // Check status
                  if (profile.status == 'active' ||
                      profile.status == 'admin' ||
                      profile.status == 'validated_admin') {
                    return const MainScreen();
                  } else {
                    // pending or other status
                    return const PendingApprovalPage();
                  }
                },
                loading: () => const ExtraordinarySplashScreen(),
                error: (e, s) {
                  return Scaffold(
                    backgroundColor: Colors.black,
                    body: ErrorStateWidget(
                      title: 'Erreur de chargement du profil',
                      message: ErrorHandler.getErrorMessage(e),
                      onRetry: () => ref.invalidate(currentUserProfileProvider),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const ExtraordinarySplashScreen(),
        error: (e, stack) => const LoginPage(),
      ),
    );
  }
}
