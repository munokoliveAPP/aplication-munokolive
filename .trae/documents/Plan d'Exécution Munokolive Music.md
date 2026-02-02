# Plan d'Exécution : Munokolive Music 2.0

Suite à l'audit complet du code, voici l'état des lieux et le plan d'action pour répondre à vos exigences strictes.

## 📊 État des Lieux (Audit)
*   **Architecture Actuelle** : Application Flutter mature avec **Supabase** comme backend principal (Auth, Base de Données `users`, `events`, `places`, Stockage `avatars`, `events`).
*   **Firebase** : Présent dans `pubspec.yaml` (Core, Auth, Firestore, Storage) mais **totalement inutilisé** dans le code métier (pas d'imports). **Firebase Messaging (Notifications)** est manquant.
*   **Modules** :
    *   `Lieux` (Places) et `Événements` (Events) sont **déjà implémentés** fonctionnellement (CRUD, Géolocalisation, Supabase), mais manquent de connectivité robuste et de notifications.
    *   **IA** : Présente sous forme de "Bubble" (`MunoIABubble`) mais avec du contenu statique hardcodé.
    *   **Synchronisation** : Actuellement 100% Supabase. La "synchronisation" demandée avec Firebase sera implémentée via le module Notifications (absent) et potentiellement une redondance de données si nécessaire, mais je privilégierai l'usage de Firebase pour les **Notifications** pour éviter les conflits de "Vérité" des données.

## 🚀 Plan d'Action

### Phase 1 : Infrastructure & Connexions (Priorité Absolue)
1.  **Correction des Dépendances** :
    *   Ajout de `firebase_messaging` (manquant pour les notifications).
    *   Ajout de `google_generative_ai` (pour l'IA générative).
    *   Ajout de `connectivity_plus` (pour la validation de connexion active).
2.  **Activation de Firebase** :
    *   Implémentation réelle du `NotificationService` (actuellement vide).
    *   Configuration de la réception des tokens FCM et enregistrement dans la table `users` de Supabase (pour faire le lien entre les deux backends).

### Phase 2 : Module IA "Muno Spirit" (Effet "Wow")
1.  **Création du `AIService`** :
    *   Intégration de Gemini (via `google_generative_ai`) pour générer du contenu spirituel.
2.  **Upgrade de `MunoIABubble`** :
    *   Remplacement des phrases statiques par une génération contextuelle (ex: "Donne-moi un verset pour un musicien fatigué").
    *   Ajout d'une "analyse d'humeur" simple pour suggérer des chants (mockés ou basés sur les événements).

### Phase 3 : Fiabilisation des Modules Lieux & Événements
1.  **Validation de Connexion** :
    *   Injection d'une vérification `Connectivity().checkConnectivity()` avant tout `insert` dans `PlacesPage` et `EventsPage` pour éviter les crashs silencieux ou pertes de données.
2.  **Synchronisation Notifications** :
    *   Déclenchement d'une notification Firebase locale ou distante lors de la création d'un événement ("Nouvel événement ajouté !").

### Phase 4 : Vérification Finale
*   Test du flux : Auth Supabase -> Profil -> Notification Firebase -> IA Suggestion.

**Note** : Je ne toucherai pas aux fichiers de configuration (`.env`, `supabaseClient.js`, etc.) et je conserverai le design actuel (UI sombre/violette) intact.

Confirmez-vous ce plan pour que je lance les modifications ?