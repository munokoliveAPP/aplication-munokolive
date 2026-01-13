import 'package:flutter/material.dart';
import 'dart:math' as math;

class TitleSuggestionsWidget extends StatefulWidget {
  final String category;
  final Function(String) onSuggestionSelected;
  final TextEditingController titleController;

  const TitleSuggestionsWidget({
    super.key,
    required this.category,
    required this.onSuggestionSelected,
    required this.titleController,
  });

  @override
  State<TitleSuggestionsWidget> createState() => _TitleSuggestionsWidgetState();
}

class _TitleSuggestionsWidgetState extends State<TitleSuggestionsWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  final Map<String, List<String>> _suggestions = {
    'Concert de Louange': [
      'Nuit de Louange et d\'Adoration',
      'Concert Gospel : Chants du Ciel',
      'Soirée de Louange avec [Artiste]',
      'Concert de Musique Chrétienne',
      'Nuit de Gloire et de Louange',
    ],
    'Soirée d\'Adoration': [
      'Soirée d\'Adoration Intense',
      'Nuit d\'Adoration et de Prière',
      'Temps d\'Adoration en Présence',
      'Soirée d\'Adoration avec Louange',
      'Moment d\'Adoration Collective',
    ],
    'Camp de Prière': [
      'Camp de Prière et Jeûne',
      'Retraite Spirituelle de Prière',
      'Week-end de Prière Intensive',
      'Camp de Prière pour la Jeunesse',
      'Retraite de Prière et Méditation',
    ],
    'Croisade d\'Évangélisation': [
      'Croisade d\'Évangélisation : [Lieu]',
      'Grande Campagne d\'Évangélisation',
      'Croisade pour le Salut des Âmes',
      'Évangélisation de Masse',
      'Mission d\'Évangélisation',
    ],
    'Conférence Biblique': [
      'Conférence Biblique : [Thème]',
      'Séminaire d\'Étude Biblique',
      'Conférence sur la Parole de Dieu',
      'Rencontre d\'Enseignement Biblique',
      'Conférence Théologique',
    ],
    'Cinéma Gospel': [
      'Projection Film Chrétien : [Titre]',
      'Cinéma Gospel : Soirée Cinéma',
      'Projection de Film Inspirant',
      'Soirée Cinéma Chrétien',
      'Film Gospel avec Débat',
    ],
    'Festival de Musique': [
      'Festival Gospel : [Nom]',
      'Festival de Musique Chrétienne',
      'Grand Festival Gospel',
      'Festival de Louange',
      'Festival Musical Chrétien',
    ],
    'Stand-up/Humour Chrétien': [
      'Soirée Humour Chrétien',
      'Stand-up Gospel : Rire et Foi',
      'Comédie Chrétienne : [Artiste]',
      'Soirée de Rire et de Foi',
      'Humour avec un Message',
    ],
    'Sortie Détente (Pique-nique)': [
      'Pique-nique Fraternel',
      'Sortie Détente entre Frères',
      'Pique-nique Communautaire',
      'Journée de Détente et Partage',
      'Sortie Nature et Fraternité',
    ],
    'Atelier de Chant': [
      'Atelier de Chant Gospel',
      'Formation au Chant Chrétien',
      'Atelier Vocal : Techniques de Chant',
      'Masterclass de Chant Gospel',
      'Atelier de Technique Vocale',
    ],
    'Masterclass Instrument': [
      'Masterclass [Instrument]',
      'Formation Instrumentale Avancée',
      'Atelier de Musique Instrumentale',
      'Masterclass Musicale',
      'Formation Professionnelle [Instrument]',
    ],
    'Rencontre de Couples': [
      'Rencontre de Couples Chrétiens',
      'Soirée pour Couples',
      'Conférence pour Couples',
      'Atelier de Couples',
      'Rencontre Maritale',
    ],
    'Forum Jeunesse': [
      'Forum de la Jeunesse Chrétienne',
      'Rencontre Jeunesse : [Thème]',
      'Forum Jeunesse et Leadership',
      'Convention Jeunesse',
      'Sommet de la Jeunesse',
    ],
    'Gala de Charité': [
      'Gala de Charité : [Cause]',
      'Soirée de Gala au Profit de...',
      'Gala de Bienfaisance',
      'Événement de Collecte de Fonds',
      'Gala pour une Cause Noble',
    ],
    'Don de Sang': [
      'Collecte de Sang : Don de Vie',
      'Journée de Don de Sang',
      'Action de Don de Sang',
      'Collecte de Sang Communautaire',
      'Don de Sang : Sauvez des Vies',
    ],
    'Action Sociale': [
      'Action Sociale : [Cause]',
      'Journée de Solidarité',
      'Action Communautaire',
      'Projet Social : [Nom]',
      'Initiative de Solidarité',
    ],
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _currentSuggestions {
    return _suggestions[widget.category] ??
        [
          'Événement : ${widget.category}',
          'Rencontre ${widget.category}',
          'Soirée ${widget.category}',
        ];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.category.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _isExpanded = !_isExpanded);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFDF00FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFDF00FF).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: child,
                    );
                  },
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFDF00FF),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Suggestions de titres',
                  style: TextStyle(
                    color: Color(0xFFDF00FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFFDF00FF),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentSuggestions.take(5).map((suggestion) {
              return GestureDetector(
                onTap: () {
                  widget.titleController.text = suggestion;
                  widget.onSuggestionSelected(suggestion);
                  setState(() => _isExpanded = false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    suggestion,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
