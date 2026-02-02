# Résumé
- Décrivez brièvement l’objectif du PR et le problème résolu

## Changements
- Listez les principaux changements (fichiers clés, fonctionnalités, refactors)

## Checklist i18n
- [ ] Clés ajoutées dans EN et FR
- [ ] Métadonnées `@key` avec `description` ajoutées
- [ ] Placeholders typés pour toutes les variables `{var}`
- [ ] `flutter gen-l10n` exécuté localement
- [ ] `scripts/check-arb.ps1` passe (aucun doublon, placeholders OK)

## CI
- [ ] L10N Check vert
- [ ] Analyze vert
- [ ] Test vert
- [ ] Build Web vert

## Tests
- [ ] `flutter analyze` sans erreurs
- [ ] `flutter test` passe localement
- [ ] Captures/Previews si pertinent

## Liens
- Ticket/Issue lié :
- Preview/Environnements :
