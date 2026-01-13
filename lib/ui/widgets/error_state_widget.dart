import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget élégant pour les états d'erreur
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onRetry;
  final IconData? icon;

  const ErrorStateWidget({
    super.key,
    this.title = 'Une erreur est survenue',
    required this.message,
    this.actionLabel = 'Réessayer',
    this.onRetry,
    this.icon,
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
                color: Colors.red.withValues(alpha: 0.1),
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                size: 64,
                color: Colors.red.withValues(alpha: 0.6),
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
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
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
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Gestionnaire d'erreurs avec messages personnalisés
class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error.toString().contains('permission-denied')) {
      return 'Vous n\'avez pas la permission d\'accéder à cette ressource.';
    }
    if (error.toString().contains('network')) {
      return 'Problème de connexion. Vérifiez votre internet.';
    }
    if (error.toString().contains('timeout')) {
      return 'Le serveur met trop de temps à répondre.';
    }
    if (error.toString().contains('not-found')) {
      return 'La ressource demandée n\'existe pas.';
    }
    return 'Une erreur inattendue s\'est produite.';
  }

  static Widget buildErrorWidget(dynamic error, VoidCallback? onRetry) {
    return ErrorStateWidget(message: getErrorMessage(error), onRetry: onRetry);
  }
}
