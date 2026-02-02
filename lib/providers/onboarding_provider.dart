import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider to check if onboarding has been seen
final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  // FALLBACK DE SÉCURITÉ : Empêche le crash "UnimplementedError" si l'override est oublié.
  // En production, cela doit toujours être overridé dans AppBootstrap avec les vrais SharedPreferences.
  debugPrint("⚠️ ATTENTION: onboardingProvider non initialisé ! Utilisation du mode secours (non persistant).");
  return OnboardingNotifier(null);
});

class OnboardingNotifier extends StateNotifier<bool> {
  final SharedPreferences? prefs;

  // Accepte des prefs nulles pour le mode secours
  OnboardingNotifier(this.prefs)
      : super(prefs?.getBool('seenOnboarding') ?? false);

  Future<void> completeOnboarding() async {
    if (prefs != null) {
      await prefs!.setBool('seenOnboarding', true);
    } else {
      debugPrint("⚠️ Onboarding complété mais non sauvegardé (Prefs manquants)");
    }
    state = true;
  }
}
