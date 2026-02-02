import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// État de la langue
class LocaleState extends StateNotifier<Locale> {
  final SharedPreferences prefs;

  LocaleState(this.prefs) : super(_loadLocale(prefs));

  // Charge la langue sauvegardée ou utilise le français par défaut
  static Locale _loadLocale(SharedPreferences prefs) {
    final languageCode = prefs.getString('language_code');
    if (languageCode == null) return const Locale('fr');
    return Locale(languageCode);
  }

  // Change la langue et sauvegarde la préférence
  Future<void> setLocale(String languageCode) async {
    state = Locale(languageCode);
    await prefs.setString('language_code', languageCode);
  }

  // Convertit le nom de langue affiché en code ISO
  static String getCodeFromDisplayName(String displayName) {
    switch (displayName) {
      case 'English':
        return 'en';
      case 'Español':
        return 'es';
      case 'Lingala':
        return 'ln'; // Note: Lingala support might require custom logic
      case 'Français':
      default:
        return 'fr';
    }
  }

  // Convertit le code ISO en nom affiché
  String getDisplayName() {
    switch (state.languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'ln':
        return 'Lingala';
      case 'fr':
      default:
        return 'Français';
    }
  }
}

// Provider global pour la langue
final localeProvider = StateNotifierProvider<LocaleState, Locale>((ref) {
  throw UnimplementedError('localeProvider doit être initialisé dans main.dart avec override');
});
