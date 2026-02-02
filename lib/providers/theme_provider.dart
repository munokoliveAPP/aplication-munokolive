import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// État du thème (Mode Sombre / Mode Clair)
class ThemeState extends StateNotifier<ThemeMode> {
  final SharedPreferences prefs;

  ThemeState(this.prefs) : super(_loadTheme(prefs));

  // Charge le thème sauvegardé ou utilise le thème système par défaut
  static ThemeMode _loadTheme(SharedPreferences prefs) {
    final isDark = prefs.getBool('is_dark_mode');
    if (isDark == null) return ThemeMode.system;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  // Bascule le thème et sauvegarde la préférence
  void toggleTheme(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    prefs.setBool('is_dark_mode', isDark);
  }

  // Récupère l'état actuel sous forme booléenne (pour les switchs UI)
  bool get isDarkMode => state == ThemeMode.dark;
}

// Provider global pour le thème
final themeProvider = StateNotifierProvider<ThemeState, ThemeMode>((ref) {
  throw UnimplementedError('themeProvider doit être initialisé dans main.dart avec override');
});
