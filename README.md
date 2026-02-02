# munokolive_music ![L10N Check](https://github.com/munokoliveAPP/aplication-munokolive/actions/workflows/l10n-check.yml/badge.svg) ![Analyze](https://github.com/munokoliveAPP/aplication-munokolive/actions/workflows/analyze.yml/badge.svg) ![Test](https://github.com/munokoliveAPP/aplication-munokolive/actions/workflows/test.yml/badge.svg) ![Build Web](https://github.com/munokoliveAPP/aplication-munokolive/actions/workflows/build-web.yml/badge.svg)

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Conventions i18n

- Arborescence
  - Fichiers ARB: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`
  - Fichier de sortie: `lib/l10n/app_localizations.dart` (généré)
- Règles
  - Chaque clé doit idéalement avoir une métadonnée `@key` avec `description`
  - Les chaînes avec variables `{var}` doivent avoir `@key.placeholders` typés
- Ajout d’une clé
  - Ajouter la clé dans FR et EN
  - Ajouter la métadonnée `@key` (description + placeholders si nécessaire)
- Génération et validation locale

```bash
flutter gen-l10n
flutter analyze
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check-arb.ps1
```

- CI
  - Les workflows vérifient automatiquement i18n, analyse, tests et build web
  - Voir les badges en en-tête pour le statut
