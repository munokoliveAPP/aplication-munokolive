import 'package:flutter/material.dart';

class EventCategory {
  final String name;
  final IconData icon;
  final Color color;
  final String group;

  const EventCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.group,
  });
}

class CategoryGridWidget extends StatefulWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryGridWidget({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<CategoryGridWidget> createState() => _CategoryGridWidgetState();
}

class _CategoryGridWidgetState extends State<CategoryGridWidget> {
  static const List<EventCategory> _categories = [
    // Gospel Spirituel
    EventCategory(
      name: 'Concert de Louange',
      icon: Icons.music_note,
      color: Color(0xFFDF00FF),
      group: 'Gospel Spirituel',
    ),
    EventCategory(
      name: 'Soirée d\'Adoration',
      icon: Icons.favorite,
      color: Color(0xFF800080),
      group: 'Gospel Spirituel',
    ),
    EventCategory(
      name: 'Camp de Prière',
      icon: Icons.church,
      color: Color(0xFF9C27B0),
      group: 'Gospel Spirituel',
    ),
    EventCategory(
      name: 'Croisade d\'Évangélisation',
      icon: Icons.people,
      color: Color(0xFF7B1FA2),
      group: 'Gospel Spirituel',
    ),
    EventCategory(
      name: 'Conférence Biblique',
      icon: Icons.menu_book,
      color: Color(0xFF6A1B9A),
      group: 'Gospel Spirituel',
    ),
    // Divertissement Chrétien
    EventCategory(
      name: 'Cinéma Gospel',
      icon: Icons.movie,
      color: Color(0xFFE91E63),
      group: 'Divertissement Chrétien',
    ),
    EventCategory(
      name: 'Festival de Musique',
      icon: Icons.festival,
      color: Color(0xFFC2185B),
      group: 'Divertissement Chrétien',
    ),
    EventCategory(
      name: 'Stand-up/Humour Chrétien',
      icon: Icons.sentiment_very_satisfied,
      color: Color(0xFFAD1457),
      group: 'Divertissement Chrétien',
    ),
    EventCategory(
      name: 'Sortie Détente (Pique-nique)',
      icon: Icons.outdoor_grill,
      color: Color(0xFF880E4F),
      group: 'Divertissement Chrétien',
    ),
    // Formation & Jeunesse
    EventCategory(
      name: 'Atelier de Chant',
      icon: Icons.mic,
      color: Color(0xFF2196F3),
      group: 'Formation & Jeunesse',
    ),
    EventCategory(
      name: 'Masterclass Instrument',
      icon: Icons.piano,
      color: Color(0xFF1976D2),
      group: 'Formation & Jeunesse',
    ),
    EventCategory(
      name: 'Rencontre de Couples',
      icon: Icons.favorite_border,
      color: Color(0xFF1565C0),
      group: 'Formation & Jeunesse',
    ),
    EventCategory(
      name: 'Forum Jeunesse',
      icon: Icons.groups,
      color: Color(0xFF0D47A1),
      group: 'Formation & Jeunesse',
    ),
    // Solidarité
    EventCategory(
      name: 'Gala de Charité',
      icon: Icons.volunteer_activism,
      color: Color(0xFFFF9800),
      group: 'Solidarité',
    ),
    EventCategory(
      name: 'Don de Sang',
      icon: Icons.bloodtype,
      color: Color(0xFFF57C00),
      group: 'Solidarité',
    ),
    EventCategory(
      name: 'Action Sociale',
      icon: Icons.handshake,
      color: Color(0xFFE65100),
      group: 'Solidarité',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Group categories by group
    final groupedCategories = <String, List<EventCategory>>{};
    for (final category in _categories) {
      groupedCategories.putIfAbsent(category.group, () => []).add(category);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group headers and grids
        ...groupedCategories.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 8),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    color: Color(0xFFDF00FF),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: entry.value.map((category) {
                  final isSelected = widget.selectedCategory == category.name;
                  return _buildCategoryChip(category, isSelected);
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildCategoryChip(EventCategory category, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.onCategorySelected(category.name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    category.color,
                    category.color.withValues(alpha: 0.7),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.3)
                : category.color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: category.color.withValues(alpha: 0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              color: isSelected ? Colors.white : category.color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              category.name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
