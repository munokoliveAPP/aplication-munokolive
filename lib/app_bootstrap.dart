import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munokolive_music/config/constants.dart';
import 'package:munokolive_music/firebase_options.dart';
import 'package:munokolive_music/main.dart';
import 'package:munokolive_music/providers/locale_provider.dart';
import 'package:munokolive_music/providers/onboarding_provider.dart';
import 'package:munokolive_music/providers/theme_provider.dart';
import 'package:munokolive_music/services/notification_service.dart';
import 'package:munokolive_music/services/offline_service.dart';
import 'package:munokolive_music/ui/widgets/global_error_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// WIDGET D'INITIALISATION ROBUSTE (PATTERN "BOOTSTRAP")
/// Ce widget est la racine absolue de l'application. Il gère :
/// 1. L'affichage immédiat d'un écran de chargement (évite l'écran blanc/noir natif)
/// 2. L'initialisation séquentielle des services critiques (Firebase, Supabase, Hive)
/// 3. La capture globale des erreurs de démarrage
/// 4. L'injection des dépendances (ProviderScope) une fois tout prêt
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  // État de l'initialisation
  bool _isInitialized = false;
  String _currentStep = "Démarrage du système...";
  Object? _initError;
  FlutterErrorDetails? _errorDetails;

  // Dépendances critiques à injecter
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. System UI & Bindings
      setState(() => _currentStep = "Configuration de l'interface...");
      // Déjà fait dans main, mais on sécurise
      WidgetsFlutterBinding.ensureInitialized();

      // Force l'orientation portrait
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // System UI Overlay
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      // 2. Firebase (Critique pour Crashlytics/Auth)
      setState(() => _currentStep = "Connexion aux services Google...");
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        debugPrint("⚠️ Avertissement Firebase: $e");
        // On continue même si Firebase échoue (mode dégradé)
      }

      // 3. Stockage Local (Hive/Prefs)
      setState(() => _currentStep = "Chargement des préférences...");
      try {
        await OfflineService.init();
      } catch (e) {
        debugPrint("⚠️ Avertissement Hive: $e");
      }

      _prefs = await SharedPreferences.getInstance();

      // 4. Supabase (Critique pour la Data)
      setState(() => _currentStep = "Connexion à MunokoLive Cloud...");
      try {
        await Supabase.initialize(
          url: AppConstants.supabaseUrl,
          anonKey: AppConstants.supabaseAnonKey,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
          // debug: kDebugMode,
        );
      } catch (e) {
        // Erreur critique si Supabase ne se lance pas ?
        // On peut réessayer ou laisser passer si mode offline géré.
        // Pour l'instant on log juste, AuthWrapper gérera la non-connexion.
        debugPrint("⚠️ Erreur Supabase Init: $e");
        // On ne throw pas ici pour laisser l'app se lancer en mode "Offline" ou "Erreur UI"
      }

      // 5. Services Secondaires (Non-bloquants)
      setState(() => _currentStep = "Initialisation des notifications...");
      try {
        await NotificationService().init();
      } catch (e) {
        debugPrint("⚠️ Erreur Notifications: $e");
      }

      // 6. Performance Cache
      PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;

      // FIN
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stack) {
      debugPrint("🛑 CRITICAL BOOTSTRAP ERROR: $e");
      if (mounted) {
        setState(() {
          _initError = e;
          _errorDetails = FlutterErrorDetails(
            exception: e,
            stack: stack,
            library: 'AppBootstrap',
            context: ErrorDescription('Initialisation de l\'application'),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // CAS 1: ERREUR CRITIQUE AU DÉMARRAGE
    if (_initError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: GlobalErrorWidget(
          errorDetails: _errorDetails,
          error: _initError,
          isRelease: kReleaseMode,
          onRetry: () {
            setState(() {
              _initError = null;
              _errorDetails = null;
            });
            _initializeApp();
          },
        ),
      );
    }

    // CAS 2: CHARGEMENT (SPLASH SCREEN CUSTOM)
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo ou Icone
                const Icon(
                  Icons.music_note_rounded,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                // Loader
                const CircularProgressIndicator(
                  color: Colors.purpleAccent,
                  strokeWidth: 2,
                ),
                const SizedBox(height: 24),
                // Status Text
                Text(
                  _currentStep,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // CAS 3: SUCCÈS -> LANCEMENT DE L'APP
    return ProviderScope(
      overrides: [
        themeProvider.overrideWith((ref) => ThemeState(_prefs)),
        localeProvider.overrideWith((ref) => LocaleState(_prefs)),
        onboardingProvider.overrideWith(
          (ref) => OnboardingNotifier(_prefs),
        ), // Inject Prefs
      ],
      child: const MunoKoLiveApp(),
    );
  }
}
