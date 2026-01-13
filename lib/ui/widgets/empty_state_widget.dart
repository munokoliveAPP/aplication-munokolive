import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget élégant pour les états vides
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.2),
                    AppTheme.secondaryColor.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// États vides pré-configurés
class EmptyStates {
  static Widget places() => const EmptyStateWidget(
    icon: Icons.place_outlined,
    title: 'Aucun lieu disponible',
    message: 'Soyez le premier à partager un lieu sacré avec la communauté.',
    actionLabel: 'Ajouter un lieu',
  );

  static Widget events() => const EmptyStateWidget(
    icon: Icons.event_busy,
    title: 'Aucun événement',
    message:
        'Il n\'y a pas d\'événements pour le moment.\nCréez-en un pour rassembler la communauté !',
    actionLabel: 'Créer un événement',
  );

  static Widget search({required String query}) => EmptyStateWidget(
    icon: Icons.search_off,
    title: 'Aucun résultat',
    message:
        'Aucun résultat trouvé pour "$query".\nEssayez avec d\'autres mots-clés.',
  );

  static Widget contacts() => const EmptyStateWidget(
    icon: Icons.people_outline,
    title: 'Aucun contact',
    message:
        'Vos contacts apparaîtront ici.\nExplorez la carte pour découvrir des membres !',
  );

  static Widget generic({String? message}) => EmptyStateWidget(
    icon: Icons.inbox_outlined,
    title: 'Rien à afficher',
    message: message ?? 'Il n\'y a rien à afficher pour le moment.',
  );
}
