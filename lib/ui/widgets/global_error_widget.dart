/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:flutter/material.dart';
import 'package:munokolive_music/l10n/app_localizations.dart';

class GlobalErrorWidget extends StatefulWidget {
  final FlutterErrorDetails? errorDetails;
  final Object? error;
  final bool isRelease;
  final VoidCallback? onRetry;

  const GlobalErrorWidget({
    super.key,
    this.errorDetails,
    this.error,
    this.isRelease = false,
    this.onRetry,
  });

  @override
  State<GlobalErrorWidget> createState() => _GlobalErrorWidgetState();
}

class _GlobalErrorWidgetState extends State<GlobalErrorWidget> {
  String _getErrorMessage() {
    final loc = AppLocalizations.of(context);
    try {
      final buffer = StringBuffer();

      if (widget.errorDetails != null) {
        final details = widget.errorDetails!;

        // 1. Tenter d'extraire un message clair de l'exception
        final exceptionStr = details.exception.toString();
        if (!exceptionStr.contains("Instance of")) {
          buffer.writeln(loc?.errorTitle ?? "ERREUR:");
          buffer.writeln(exceptionStr);
        }

        // 2. Ajouter le résumé (souvent plus lisible pour les erreurs de layout)
        final summaryStr = details.summary.toDescription();
        if (summaryStr.isNotEmpty && summaryStr != "null") {
          buffer.writeln(loc?.errorDetails ?? "\nDÉTAILS:");
          buffer.writeln(summaryStr);
        }

        // 3. Informations de contexte (quel widget ?)
        if (details.context != null) {
          buffer.writeln(loc?.errorContext ?? "\nCONTEXTE:");
          buffer.writeln(details.context.toString());
        }

        // 4. Stack Trace (Limité pour la lisibilité)
        if (details.stack != null) {
          buffer.writeln(loc?.errorTrace ?? "\nTRACE (Top 5):");
          final stackLines = details.stack.toString().split('\n');
          final limit = stackLines.length > 5 ? 5 : stackLines.length;
          buffer.writeln(stackLines.sublist(0, limit).join('\n'));
        }

        // Fallback si tout est vide
        if (buffer.isEmpty) {
          return "${loc?.unknownTechnicalError ?? "Erreur Technique Non Identifiée:\n"}${details.toString()}";
        }

        return buffer.toString();
      } else if (widget.error != null) {
        return widget.error.toString();
      }
      return loc?.unknownError ?? "Erreur inconnue";
    } catch (e) {
      return "${loc?.errorDisplayError ?? "Erreur d'affichage de l'erreur: "}$e";
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(
        0xFF1E1E1E,
      ), // AppTheme.backgroundDark approx
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orangeAccent,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                loc?.systemDiagnostic ?? 'Diagnostic Système',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  _getErrorMessage(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontFamily: 'Courier',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              if (widget.onRetry != null)
                ElevatedButton.icon(
                  onPressed: widget.onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: Text(loc?.restartApp ?? "Relancer l'application"),
                )
              else
                Text(
                  loc?.pleaseRestartApp ?? "Veuillez redémarrer l'application",
                  style: const TextStyle(color: Colors.white38),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
