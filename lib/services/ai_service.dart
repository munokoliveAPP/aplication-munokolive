/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

class AIService {
  GenerativeModel? _model;
  static const String _apiKey = 'AIzaSyAh55W8nWr6Jt4lIUypDVnttAmVd_gScSg';

  AIService() {
    _model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey);
  }

  Future<String> getSpiritualAdvice(String contextOrMood) async {
    if (_model == null) {
      // Fallback if no API key
      return _getFallbackAdvice(contextOrMood);
    }

    try {
      final prompt = 'En tant que conseiller spirituel chrétien pour des musiciens Gospel, donne un conseil court et inspirant (max 2 phrases) basé sur ce contexte ou humeur : "$contextOrMood". Ajoute une référence biblique si pertinent.';
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text ?? _getFallbackAdvice(contextOrMood);
    } catch (e) {
      return _getFallbackAdvice(contextOrMood);
    }
  }

  String _getFallbackAdvice(String mood) {
    final lowerMood = mood.toLowerCase();
    if (lowerMood.contains('fatigué') || lowerMood.contains('stress')) {
      return "Venez à moi, vous tous qui êtes fatigués et chargés, et je vous donnerai du repos. (Matthieu 11:28)";
    } else if (lowerMood.contains('triste') || lowerMood.contains('déçu')) {
      return "L'Éternel est près de ceux qui ont le cœur brisé. (Psaume 34:18)";
    } else if (lowerMood.contains('joie') || lowerMood.contains('heureux')) {
      return "Poussez vers l'Éternel des cris de joie, vous tous, habitants de la terre! (Psaume 100:1)";
    } else {
      return "Que tout ce qui respire loue l'Éternel ! Ton talent est un don précieux pour le Royaume.";
    }
  }

  // Future feature: Music Recommendation
  Future<List<String>> getMusicSuggestions(String mood) async {
    // This would require a real model or a database of songs with tags.
    // For now, return generic suggestions.
    return [
      "Dena Mwana - Souffle",
      "Morijah - Allo Allô",
      "KS Bloom - C'est Dieu",
    ];
  }
}
