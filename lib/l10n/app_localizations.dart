import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Titre de l'application
  ///
  /// In fr, this message translates to:
  /// **'MunokoLive Music'**
  String get appTitle;

  /// Message de bienvenue affiché à l'utilisateur
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur MunokoLive'**
  String get welcomeMessage;

  /// Bouton de connexion
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginButton;

  /// Bouton d'inscription
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get registerButton;

  /// Onglet bas: Accueil
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get homeTab;

  /// Onglet bas: Événements
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get eventsTab;

  /// Onglet bas: Lieux
  ///
  /// In fr, this message translates to:
  /// **'Lieux'**
  String get placesTab;

  /// Onglet bas: Profil
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profileTab;

  /// Titre de la page Paramètres
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// Option des paramètres: langue
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get languageOption;

  /// Option des paramètres: thème
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get themeOption;

  /// Option des paramètres: biométrie
  ///
  /// In fr, this message translates to:
  /// **'Biométrie'**
  String get biometricsOption;

  /// Option des paramètres: notifications
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsOption;

  /// Libellé du champ email
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Libellé du champ mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get passwordLabel;

  /// Libellé de confirmation du mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPasswordLabel;

  /// Libellé du champ code de parrainage
  ///
  /// In fr, this message translates to:
  /// **'Code de parrainage'**
  String get referralCodeLabel;

  /// Lien de réinitialisation du mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// Invite l'utilisateur s'il n'a pas de compte
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get noAccount;

  /// Invite pour utilisateurs qui ont déjà un compte
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get alreadyAccount;

  /// Erreur indiquant que l'email est invalide
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get invalidEmail;

  /// Avertissement quand le mot de passe est trop court
  ///
  /// In fr, this message translates to:
  /// **'Min 6 caractères'**
  String get passwordMinLength;

  /// Erreur quand les mots de passe ne correspondent pas
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordsMismatch;

  /// Erreur quand le code parrain est requis/manquant
  ///
  /// In fr, this message translates to:
  /// **'Le code parrain est obligatoire'**
  String get referralCodeRequired;

  /// Statut : authentification en cours
  ///
  /// In fr, this message translates to:
  /// **'Authentification...'**
  String get authenticating;

  /// Statut : opération réussie
  ///
  /// In fr, this message translates to:
  /// **'Succès !'**
  String get success;

  /// Statut : vérification des données/processus
  ///
  /// In fr, this message translates to:
  /// **'Vérification...'**
  String get verifying;

  /// Statut : initialisation de l'application
  ///
  /// In fr, this message translates to:
  /// **'Initialisation...'**
  String get initializing;

  /// Statut : redirection en cours
  ///
  /// In fr, this message translates to:
  /// **'Redirection...'**
  String get redirecting;

  /// Statut : création du compte en cours
  ///
  /// In fr, this message translates to:
  /// **'Création du compte...'**
  String get creatingAccount;

  /// Message de bienvenue générique
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue !'**
  String get welcome;

  /// Invite l'utilisateur à corriger le formulaire
  ///
  /// In fr, this message translates to:
  /// **'Veuillez corriger les erreurs dans le formulaire'**
  String get fixFormErrors;

  /// Erreur quand le code parrain est invalide ou manquant
  ///
  /// In fr, this message translates to:
  /// **'Code parrain invalide ou introuvable'**
  String get invalidReferralCode;

  /// Erreur de connectivité réseau
  ///
  /// In fr, this message translates to:
  /// **'Problème de connexion internet.'**
  String get networkError;

  /// Avertissement si le mot de passe est trop faible
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est trop faible (6 caractères min).'**
  String get weakPassword;

  /// Erreur quand l'email est déjà enregistré
  ///
  /// In fr, this message translates to:
  /// **'Cet email est déjà utilisé par un autre compte.'**
  String get emailInUse;

  /// Erreur quand l'adresse email est invalide
  ///
  /// In fr, this message translates to:
  /// **'L\'adresse email est invalide.'**
  String get invalidEmailMessage;

  /// Message d'erreur générique
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get genericError;

  /// Affiché quand l'utilisateur atteint les limites d'opérations
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Veuillez patienter un moment.'**
  String get rateLimitError;

  /// Erreur quand les identifiants sont incorrects
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect. Si vous n\'avez pas encore de compte, veuillez vous inscrire.'**
  String get invalidCredentials;

  /// Indique d'attendre à cause de la limitation de sécurité
  ///
  /// In fr, this message translates to:
  /// **'Pour des raisons de sécurité, veuillez patienter avant de réessayer.'**
  String get securityDelay;

  /// Message amical quand l'utilisateur revient
  ///
  /// In fr, this message translates to:
  /// **'Heureux de vous revoir !'**
  String get welcomeBack;

  /// CTA pour rejoindre la communauté/famille
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre la Famille'**
  String get joinFamily;

  /// Invite l'utilisateur à se connecter pour continuer
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour continuer'**
  String get loginToContinue;

  /// Sous-titre incitant à une inscription rapide
  ///
  /// In fr, this message translates to:
  /// **'Créez votre compte en quelques secondes'**
  String get createAccountSubtitle;

  /// Validation quand l'email est requis
  ///
  /// In fr, this message translates to:
  /// **'Email requis'**
  String get emailRequired;

  /// Titre de la page Lieux
  ///
  /// In fr, this message translates to:
  /// **'Nos Lieux'**
  String get placesTitle;

  /// Action pour ajouter un nouveau lieu
  ///
  /// In fr, this message translates to:
  /// **'AJOUTER'**
  String get addPlace;

  /// Placeholder du champ de recherche pour les Lieux
  ///
  /// In fr, this message translates to:
  /// **'Rechercher (ex: Yopougon, Studio...)'**
  String get searchPlaceholder;

  /// Filtre de catégorie: tous les lieux
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get allCategories;

  /// Catégorie de lieu : église
  ///
  /// In fr, this message translates to:
  /// **'Église'**
  String get church;

  /// Catégorie de lieu : salle de répétition
  ///
  /// In fr, this message translates to:
  /// **'Salle de répétition'**
  String get rehearsalRoom;

  /// Catégorie de lieu : studio d'enregistrement
  ///
  /// In fr, this message translates to:
  /// **'Studio d\'enregistrement'**
  String get recordingStudio;

  /// Catégorie de lieu : espace événementiel
  ///
  /// In fr, this message translates to:
  /// **'Espace événementiel'**
  String get eventSpace;

  /// Toast affiché quand la liste est mise à jour
  ///
  /// In fr, this message translates to:
  /// **'Liste mise à jour !'**
  String get listUpdated;

  /// Préfixe utilisé avant les descriptions d'erreur
  ///
  /// In fr, this message translates to:
  /// **'Erreur : '**
  String get errorPrefix;

  /// Affiché quand la recherche ne trouve aucun lieu
  ///
  /// In fr, this message translates to:
  /// **'Aucun lieu trouvé.'**
  String get noPlacesFound;

  /// Indique le lieu le plus proche
  ///
  /// In fr, this message translates to:
  /// **'Le plus proche'**
  String get closestPlace;

  /// Affiché quand l'adresse du lieu est manquante
  ///
  /// In fr, this message translates to:
  /// **'Adresse non spécifiée'**
  String get addressUnspecified;

  /// Erreur quand l'application carte ne s'ouvre pas
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir la carte'**
  String get mapOpenError;

  /// CTA pour proposer un lieu sacré
  ///
  /// In fr, this message translates to:
  /// **'Proposer un lieu sacré'**
  String get proposeSacredPlace;

  /// Libellé pour la photo de façade extérieure
  ///
  /// In fr, this message translates to:
  /// **'Extérieur (Façade)'**
  String get exteriorFacade;

  /// Libellé pour la photo intérieure optionnelle
  ///
  /// In fr, this message translates to:
  /// **'Intérieur (Optionnel)'**
  String get interiorOptional;

  /// Libellé du champ nom du lieu
  ///
  /// In fr, this message translates to:
  /// **'Nom du lieu'**
  String get placeNameLabel;

  /// Libellé du champ catégorie
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get categoryLabel;

  /// Libellé du champ nom du responsable
  ///
  /// In fr, this message translates to:
  /// **'Nom du responsable'**
  String get managerNameLabel;

  /// Libellé du champ contact téléphone
  ///
  /// In fr, this message translates to:
  /// **'Contact (Téléphone)'**
  String get contactPhoneLabel;

  /// CTA pour marquer la position GPS actuelle comme celle du lieu
  ///
  /// In fr, this message translates to:
  /// **'MARQUER CE LIEU (GPS ICI)'**
  String get markThisPlaceGps;

  /// Toast indiquant que la position est enregistrée avec suggestion de modification
  ///
  /// In fr, this message translates to:
  /// **'Position Enregistrée ! (Modifier)'**
  String get positionSavedEdit;

  /// CTA pour soumettre le lieu à la validation de l'administrateur
  ///
  /// In fr, this message translates to:
  /// **'SOUMETTRE À VALIDATION'**
  String get submitForValidation;

  /// No description provided for @statusPreparing.
  ///
  /// In fr, this message translates to:
  /// **'Préparation...'**
  String get statusPreparing;

  /// Statut lors de l'envoi de la photo principale du lieu
  ///
  /// In fr, this message translates to:
  /// **'Envoi de la photo principale...'**
  String get statusUploadingMainPhoto;

  /// Statut lors de l'envoi de la photo intérieure optionnelle
  ///
  /// In fr, this message translates to:
  /// **'Envoi de la photo intérieure...'**
  String get statusUploadingInteriorPhoto;

  /// Statut lors de l'enregistrement des informations du lieu
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement du lieu...'**
  String get statusSavingPlace;

  /// Toast affichant les coordonnées GPS capturées
  ///
  /// In fr, this message translates to:
  /// **'📍 Position capturée : {lat}, {lng}'**
  String positionCaptured(double lat, double lng);

  /// Erreur quand la capture de position GPS échoue
  ///
  /// In fr, this message translates to:
  /// **'Impossible de capturer la position. Vérifiez votre GPS.'**
  String get gpsCaptureError;

  /// Invite à ajouter une image
  ///
  /// In fr, this message translates to:
  /// **'Veuillez ajouter une image'**
  String get pleaseAddImage;

  /// Invite à capturer la position GPS
  ///
  /// In fr, this message translates to:
  /// **'Veuillez capturer la position du lieu'**
  String get pleaseCapturePosition;

  /// Erreur quand une authentification est requise
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur non connecté'**
  String get userNotLoggedIn;

  /// No description provided for @placeSubmittedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lieu soumis avec succès'**
  String get placeSubmittedTitle;

  /// No description provided for @placePublishedImmediately.
  ///
  /// In fr, this message translates to:
  /// **'Lieu validé et publié immédiatement.'**
  String get placePublishedImmediately;

  /// No description provided for @placeProposalSent.
  ///
  /// In fr, this message translates to:
  /// **'Votre proposition pour {name} a été envoyée.'**
  String placeProposalSent(String name);

  /// No description provided for @placeAddedAndValidated.
  ///
  /// In fr, this message translates to:
  /// **'✅ Lieu ajouté et validé !'**
  String get placeAddedAndValidated;

  /// No description provided for @placeSubmittedPending.
  ///
  /// In fr, this message translates to:
  /// **'Lieu soumis avec succès ! En attente de validation.'**
  String get placeSubmittedPending;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre email'**
  String get pleaseEnterEmail;

  /// No description provided for @resetEmailSent.
  ///
  /// In fr, this message translates to:
  /// **'Email de réinitialisation envoyé'**
  String get resetEmailSent;

  /// No description provided for @completeProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Complétez votre profil'**
  String get completeProfileTitle;

  /// No description provided for @completeProfileSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Une photo et vos informations sont requises pour la validation.'**
  String get completeProfileSubtitle;

  /// No description provided for @firstNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get lastNameLabel;

  /// No description provided for @firstNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Prénom requis'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom requis'**
  String get lastNameRequired;

  /// No description provided for @birthDateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Date de naissance'**
  String get birthDateLabel;

  /// No description provided for @birthDateRequired.
  ///
  /// In fr, this message translates to:
  /// **'Date requise'**
  String get birthDateRequired;

  /// No description provided for @churchLabel.
  ///
  /// In fr, this message translates to:
  /// **'Église / Paroisse'**
  String get churchLabel;

  /// No description provided for @churchRequired.
  ///
  /// In fr, this message translates to:
  /// **'Église requise'**
  String get churchRequired;

  /// No description provided for @referralCodeActive.
  ///
  /// In fr, this message translates to:
  /// **'Parrainage activé'**
  String get referralCodeActive;

  /// No description provided for @referralCodeMandatory.
  ///
  /// In fr, this message translates to:
  /// **'Code Parrain (Obligatoire)'**
  String get referralCodeMandatory;

  /// No description provided for @privacyPolicyAccept.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez accepter la Politique de Confidentialité'**
  String get privacyPolicyAccept;

  /// No description provided for @photoRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez ajouter une photo de profil (Obligatoire)'**
  String get photoRequired;

  /// No description provided for @optimizingPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Optimisation de votre photo en cours...'**
  String get optimizingPhoto;

  /// No description provided for @optimizingNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Optimisation et vérification réseau...'**
  String get optimizingNetwork;

  /// No description provided for @slowConnectionMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cela prend un peu plus de temps que prévu...\nVérification de la connexion et optimisation de la photo en cours.'**
  String get slowConnectionMessage;

  /// No description provided for @uploadingPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Envoi de la photo (cela peut prendre un moment)...'**
  String get uploadingPhoto;

  /// No description provided for @savingProfile.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement du profil...'**
  String get savingProfile;

  /// No description provided for @finished.
  ///
  /// In fr, this message translates to:
  /// **'Terminé !'**
  String get finished;

  /// No description provided for @musician.
  ///
  /// In fr, this message translates to:
  /// **'Musicien'**
  String get musician;

  /// No description provided for @singerAndInstrumentalist.
  ///
  /// In fr, this message translates to:
  /// **'Chantre & Instrumentiste'**
  String get singerAndInstrumentalist;

  /// No description provided for @minister.
  ///
  /// In fr, this message translates to:
  /// **'Ministre'**
  String get minister;

  /// No description provided for @servantOfGod.
  ///
  /// In fr, this message translates to:
  /// **'Serviteur de Dieu'**
  String get servantOfGod;

  /// No description provided for @media.
  ///
  /// In fr, this message translates to:
  /// **'Média'**
  String get media;

  /// No description provided for @photoVideoSound.
  ///
  /// In fr, this message translates to:
  /// **'Photo, Vidéo, Son'**
  String get photoVideoSound;

  /// No description provided for @labelManager.
  ///
  /// In fr, this message translates to:
  /// **'Label / Manager'**
  String get labelManager;

  /// No description provided for @producer.
  ///
  /// In fr, this message translates to:
  /// **'Producteur'**
  String get producer;

  /// No description provided for @organizer.
  ///
  /// In fr, this message translates to:
  /// **'Organisateur'**
  String get organizer;

  /// No description provided for @eventsAndConcerts.
  ///
  /// In fr, this message translates to:
  /// **'Événements & Concerts'**
  String get eventsAndConcerts;

  /// No description provided for @particular.
  ///
  /// In fr, this message translates to:
  /// **'Particulier'**
  String get particular;

  /// No description provided for @musicLover.
  ///
  /// In fr, this message translates to:
  /// **'Mélomane / Adorateur'**
  String get musicLover;

  /// No description provided for @role.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get role;

  /// No description provided for @selectRole.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez votre rôle'**
  String get selectRole;

  /// No description provided for @instrument.
  ///
  /// In fr, this message translates to:
  /// **'Instrument'**
  String get instrument;

  /// No description provided for @selectInstrument.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez votre instrument'**
  String get selectInstrument;

  /// No description provided for @privacyPolicyText.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte la Politique de Confidentialité et les Conditions d\'Utilisation'**
  String get privacyPolicyText;

  /// No description provided for @readAndAccept.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai lu et j\'accepte la '**
  String get readAndAccept;

  /// No description provided for @privacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de Confidentialité'**
  String get privacyPolicy;

  /// No description provided for @ofAppByAuthor.
  ///
  /// In fr, this message translates to:
  /// **' de Munokolive Music rédigée par Christian Anisonok.'**
  String get ofAppByAuthor;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'ENREGISTRER'**
  String get save;

  /// No description provided for @instrumentOrRole.
  ///
  /// In fr, this message translates to:
  /// **'Instrument / Rôle'**
  String get instrumentOrRole;

  /// No description provided for @ministry.
  ///
  /// In fr, this message translates to:
  /// **'Ministère'**
  String get ministry;

  /// No description provided for @selectionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Sélection requise'**
  String get selectionRequired;

  /// No description provided for @rolePianist.
  ///
  /// In fr, this message translates to:
  /// **'Pianiste'**
  String get rolePianist;

  /// No description provided for @roleDrummer.
  ///
  /// In fr, this message translates to:
  /// **'Batteur'**
  String get roleDrummer;

  /// No description provided for @roleBassist.
  ///
  /// In fr, this message translates to:
  /// **'Bassiste'**
  String get roleBassist;

  /// No description provided for @roleGuitarist.
  ///
  /// In fr, this message translates to:
  /// **'Guitariste'**
  String get roleGuitarist;

  /// No description provided for @roleSaxophonist.
  ///
  /// In fr, this message translates to:
  /// **'Saxophoniste'**
  String get roleSaxophonist;

  /// No description provided for @rolePercussionist.
  ///
  /// In fr, this message translates to:
  /// **'Percussionniste'**
  String get rolePercussionist;

  /// No description provided for @roleViolinist.
  ///
  /// In fr, this message translates to:
  /// **'Violoniste'**
  String get roleViolinist;

  /// No description provided for @roleSynthesizer.
  ///
  /// In fr, this message translates to:
  /// **'Synthétiseur'**
  String get roleSynthesizer;

  /// No description provided for @roleTrumpeter.
  ///
  /// In fr, this message translates to:
  /// **'Trompettiste'**
  String get roleTrumpeter;

  /// No description provided for @roleFlutist.
  ///
  /// In fr, this message translates to:
  /// **'Flûtiste'**
  String get roleFlutist;

  /// No description provided for @roleSinger.
  ///
  /// In fr, this message translates to:
  /// **'Chantre'**
  String get roleSinger;

  /// No description provided for @roleChoirMaster.
  ///
  /// In fr, this message translates to:
  /// **'Maître de chœur'**
  String get roleChoirMaster;

  /// No description provided for @roleMusicTrainer.
  ///
  /// In fr, this message translates to:
  /// **'Formateur Musique'**
  String get roleMusicTrainer;

  /// No description provided for @roleSoundEngineer.
  ///
  /// In fr, this message translates to:
  /// **'Ingénieur son'**
  String get roleSoundEngineer;

  /// No description provided for @roleBeatmaker.
  ///
  /// In fr, this message translates to:
  /// **'Beatmaker'**
  String get roleBeatmaker;

  /// No description provided for @rolePastor.
  ///
  /// In fr, this message translates to:
  /// **'Pasteur'**
  String get rolePastor;

  /// No description provided for @roleProphet.
  ///
  /// In fr, this message translates to:
  /// **'Prophète'**
  String get roleProphet;

  /// No description provided for @roleDeacon.
  ///
  /// In fr, this message translates to:
  /// **'Diacre'**
  String get roleDeacon;

  /// No description provided for @roleEvangelist.
  ///
  /// In fr, this message translates to:
  /// **'Évangéliste'**
  String get roleEvangelist;

  /// No description provided for @roleDoctor.
  ///
  /// In fr, this message translates to:
  /// **'Docteur'**
  String get roleDoctor;

  /// No description provided for @roleApostle.
  ///
  /// In fr, this message translates to:
  /// **'Apôtre'**
  String get roleApostle;

  /// No description provided for @requiredField.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est requis'**
  String get requiredField;

  /// No description provided for @passwordUpdatedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe mis à jour avec succès !'**
  String get passwordUpdatedSuccess;

  /// No description provided for @updatePasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour du mot de passe'**
  String get updatePasswordTitle;

  /// No description provided for @newPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPasswordLabel;

  /// No description provided for @updateButton.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get updateButton;

  /// Erreur quand WhatsApp ne peut pas s'ouvrir
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir WhatsApp'**
  String get cannotOpenWhatsApp;

  /// Titre de célébration après validation réussie
  ///
  /// In fr, this message translates to:
  /// **'FÉLICITATIONS !'**
  String get congratulations;

  /// Indique que le compte a été validé
  ///
  /// In fr, this message translates to:
  /// **'Compte validé'**
  String get accountValidated;

  /// Message affiché lors de la redirection après validation
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur Munoko Live Music.\nRedirection en cours...'**
  String get redirectionInProgress;

  /// Message affiché pendant la vérification du profil/processus
  ///
  /// In fr, this message translates to:
  /// **'VÉRIFICATION EN COURS'**
  String get verificationInProgress;

  /// Explique la phase d'analyse du profil durant la validation
  ///
  /// In fr, this message translates to:
  /// **'Votre profil est en cours d\'analyse.\nMerci de patienter pendant que nous validons vos informations.'**
  String get profileAnalysisMessage;

  /// Texte de statut lors de l'actualisation de l'état utilisateur
  ///
  /// In fr, this message translates to:
  /// **'Actualisation du statut...'**
  String get refreshingStatus;

  /// CTA pour actualiser la validation/le statut
  ///
  /// In fr, this message translates to:
  /// **'ACTUALISER MON STATUT'**
  String get refreshStatusButton;

  /// CTA pour accéder au support
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get supportButton;

  /// CTA pour quitter la session ou la page
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get quitButton;

  /// Titre pour la page ou modale de choix de langue
  ///
  /// In fr, this message translates to:
  /// **'Choisir la langue'**
  String get chooseLanguageTitle;

  /// Indique que la biométrie n'est pas supportée
  ///
  /// In fr, this message translates to:
  /// **'⚠️ Biométrie non disponible sur cet appareil'**
  String get biometricNotAvailable;

  /// Toast indiquant que la biométrie est activée
  ///
  /// In fr, this message translates to:
  /// **'🛡️ Protection biométrique activée !'**
  String get biometricEnabledMsg;

  /// Toast indiquant que la biométrie est désactivée
  ///
  /// In fr, this message translates to:
  /// **'🔓 Protection désactivée'**
  String get biometricDisabledMsg;

  /// Toast indiquant que les notifications sont activées
  ///
  /// In fr, this message translates to:
  /// **'Notifications activées'**
  String get notificationsEnabledMsg;

  /// Toast indiquant que les notifications sont désactivées
  ///
  /// In fr, this message translates to:
  /// **'Notifications désactivées'**
  String get notificationsDisabledMsg;

  /// Titre de la page Aide & Support
  ///
  /// In fr, this message translates to:
  /// **'AIDE & SUPPORT'**
  String get helpSupportTitle;

  /// Titre d'en-tête dans la page Support
  ///
  /// In fr, this message translates to:
  /// **'MUNOKOLIVE SUPPORT'**
  String get supportHeaderTitle;

  /// Slogan affiché dans la page Support
  ///
  /// In fr, this message translates to:
  /// **'À votre service pour que le service de Dieu ne s\'arrête jamais.'**
  String get supportHeaderSlogan;

  /// Titre de la section Assistance IA
  ///
  /// In fr, this message translates to:
  /// **'1. ASSISTANCE IA (MUNO-IA)'**
  String get sectionAiTitle;

  /// Titre de la section FAQ
  ///
  /// In fr, this message translates to:
  /// **'2. FOIRE AUX QUESTIONS (FAQ)'**
  String get sectionFaqTitle;

  /// Titre de la section Contact Bureau
  ///
  /// In fr, this message translates to:
  /// **'3. CONTACTER LE BUREAU'**
  String get sectionContactTitle;

  /// Titre de la section Centre de Diagnostic
  ///
  /// In fr, this message translates to:
  /// **'4. CENTRE DE DIAGNOSTIC'**
  String get sectionDiagnosticTitle;

  /// CTA pour contacter le support via WhatsApp
  ///
  /// In fr, this message translates to:
  /// **'SUPPORT WHATSAPP'**
  String get supportWhatsappButton;

  /// CTA pour appeler un administrateur
  ///
  /// In fr, this message translates to:
  /// **'Appeler l\'Administrateur'**
  String get callAdminButton;

  /// Indication de validation urgente
  ///
  /// In fr, this message translates to:
  /// **'Recommandé pour les validations urgentes'**
  String get urgentValidationsHint;

  /// Libellé pour l'email de support
  ///
  /// In fr, this message translates to:
  /// **'Support Email'**
  String get supportEmailLabel;

  /// Libellé pour le signalement d'urgence
  ///
  /// In fr, this message translates to:
  /// **'Signalement d\'Urgence'**
  String get emergencyReportLabel;

  /// Sous-titre pour l'élément de signalement d'urgence
  ///
  /// In fr, this message translates to:
  /// **'Signaler un abus ou piratage'**
  String get emergencyReportSubtitle;

  /// No description provided for @cacheCleared.
  ///
  /// In fr, this message translates to:
  /// **'Cache vidé avec succès !'**
  String get cacheCleared;

  /// Libellé indiquant la version de l'application
  ///
  /// In fr, this message translates to:
  /// **'Version de l\'App'**
  String get appVersionLabel;

  /// Libellé indiquant le statut du serveur
  ///
  /// In fr, this message translates to:
  /// **'Statut Serveur'**
  String get serverStatusLabel;

  /// Texte indiquant que le serveur est opérationnel
  ///
  /// In fr, this message translates to:
  /// **'Opérationnel'**
  String get serverOperational;

  /// Texte d'aide pour l'utilité du nettoyage du cache
  ///
  /// In fr, this message translates to:
  /// **'Utile si les images ne s\'affichent plus correctement.'**
  String get usefulIfImagesMessage;

  /// Titre de la page À Propos
  ///
  /// In fr, this message translates to:
  /// **'À PROPOS'**
  String get aboutTitle;

  /// Nom de l'application affiché dans À Propos
  ///
  /// In fr, this message translates to:
  /// **'MUNOKOLIVE MUSIC'**
  String get appNameTitle;

  /// Slogan de l'application dans À Propos
  ///
  /// In fr, this message translates to:
  /// **'Connecter le Talent à l’Onction,\nBâtir l’Horizon de Demain'**
  String get appSlogan;

  /// Titre de la section Essence
  ///
  /// In fr, this message translates to:
  /// **'L\'ESSENCE DU PROJET'**
  String get sectionEssenceTitle;

  /// Titre de la section Vision
  ///
  /// In fr, this message translates to:
  /// **'LA VISION DE L’HORIZON'**
  String get sectionVisionTitle;

  /// Sous-titre de la section Vision
  ///
  /// In fr, this message translates to:
  /// **'(Pourquoi Munokolive ?)'**
  String get sectionVisionSubtitle;

  /// Titre de la section Organisation
  ///
  /// In fr, this message translates to:
  /// **'NOTRE ORGANISATION'**
  String get sectionOrganizationTitle;

  /// Sous-titre de la section Organisation
  ///
  /// In fr, this message translates to:
  /// **'LE CORPS DU CHRIST'**
  String get sectionOrganizationSubtitle;

  /// Titre de la section Technologie
  ///
  /// In fr, this message translates to:
  /// **'RÉVOLUTION TECHNOLOGIQUE'**
  String get sectionTechTitle;

  /// Sous-titre de la section Technologie
  ///
  /// In fr, this message translates to:
  /// **'AU SERVICE DU SPIRITUEL'**
  String get sectionTechSubtitle;

  /// Titre de la section Règle d'or
  ///
  /// In fr, this message translates to:
  /// **'NOTRE RÈGLE D’OR'**
  String get sectionGoldenRuleTitle;

  /// Sous-titre de la section Règle d'or
  ///
  /// In fr, this message translates to:
  /// **'LE RESPECT MUTUEL'**
  String get sectionGoldenRuleSubtitle;

  /// Contenu de la citation du fondateur
  ///
  /// In fr, this message translates to:
  /// **'Nous sommes à la cuisine de Gospel Family. Ici, tout le monde travaille. Cette plateforme est le socle de ce que nous bâtirons dans les années à venir par la grâce de Dieu. Restons vigilants, restons unis, et gardons les yeux fixés sur l\'horizon.'**
  String get founderQuoteText;

  /// Signature du fondateur
  ///
  /// In fr, this message translates to:
  /// **'— Christian ANISONOK'**
  String get founderSignature;

  /// Titre d'en-tête de la page CGU
  ///
  /// In fr, this message translates to:
  /// **'CONDITIONS GÉNÉRALES D\'UTILISATION (CGU)\nMUNOKOLIVE MUSIC'**
  String get cguHeaderTitle;

  /// Sous-titre de version sur la page CGU
  ///
  /// In fr, this message translates to:
  /// **'Version 1.0 – \"La Vision du Futur à Long Terme\"'**
  String get cguVersionLine;

  /// Titre du dialogue lors de l'acceptation des CGU
  ///
  /// In fr, this message translates to:
  /// **'BIENVENUE DANS LA FAMILLE'**
  String get welcomeFamilyDialogTitle;

  /// Sous-titre du dialogue lors de l'acceptation des CGU
  ///
  /// In fr, this message translates to:
  /// **'La Vision du Futur commence maintenant.'**
  String get welcomeFamilyDialogSubtitle;

  /// Titre de l'AppBar de la page Confidentialité
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get privacyTitleAppBar;

  /// Titre d'en-tête de la page de confidentialité
  ///
  /// In fr, this message translates to:
  /// **'POLITIQUE DE CONFIDENTIALITÉ\nMUNOKOLIVE MUSIC'**
  String get privacyHeaderTitle;

  /// Libellé précédant la date de dernière mise à jour
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour :'**
  String get lastUpdateLabel;

  /// Ligne indiquant la propriété sur la page de confidentialité
  ///
  /// In fr, this message translates to:
  /// **'Propriété exclusive de : M. Christian ANISONOK'**
  String get exclusivePropertyLine;

  /// Titre de la mention légale de protection
  ///
  /// In fr, this message translates to:
  /// **'MENTION LÉGALE DE PROTECTION'**
  String get legalProtectionMentionTitle;

  /// No description provided for @pleaseAuthenticate.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez vous authentifier'**
  String get pleaseAuthenticate;

  /// No description provided for @biometricReason.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouillez MunokoLive pour accéder à votre compte'**
  String get biometricReason;

  /// No description provided for @authenticationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'authentification. Réessayez.'**
  String get authenticationFailed;

  /// No description provided for @secureAppTitle.
  ///
  /// In fr, this message translates to:
  /// **'MunokoLive Sécurisé'**
  String get secureAppTitle;

  /// No description provided for @retryButton.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retryButton;

  /// No description provided for @errorTitle.
  ///
  /// In fr, this message translates to:
  /// **'ERREUR :'**
  String get errorTitle;

  /// No description provided for @errorDetails.
  ///
  /// In fr, this message translates to:
  /// **'\nDÉTAILS :'**
  String get errorDetails;

  /// No description provided for @errorContext.
  ///
  /// In fr, this message translates to:
  /// **'\nCONTEXTE :'**
  String get errorContext;

  /// No description provided for @errorTrace.
  ///
  /// In fr, this message translates to:
  /// **'\nTRACE (Top 5) :'**
  String get errorTrace;

  /// No description provided for @unknownTechnicalError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur Technique Non Identifiée :\n'**
  String get unknownTechnicalError;

  /// No description provided for @unknownError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur inconnue'**
  String get unknownError;

  /// No description provided for @errorDisplayError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur d\'affichage de l\'erreur : '**
  String get errorDisplayError;

  /// No description provided for @systemDiagnostic.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostic Système'**
  String get systemDiagnostic;

  /// No description provided for @restartApp.
  ///
  /// In fr, this message translates to:
  /// **'Relancer l\'application'**
  String get restartApp;

  /// No description provided for @pleaseRestartApp.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez redémarrer l\'application'**
  String get pleaseRestartApp;

  /// No description provided for @welcomeSuperAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue, Super Admin ! Vous avez tous les pouvoirs.'**
  String get welcomeSuperAdmin;

  /// No description provided for @debateTopicTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sujet de Débat'**
  String get debateTopicTitle;

  /// No description provided for @topicTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre du sujet'**
  String get topicTitleLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description (Optionnel)'**
  String get descriptionLabel;

  /// No description provided for @cancelButton.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancelButton;

  /// No description provided for @publishButton.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get publishButton;

  /// No description provided for @activeDebateTopic.
  ///
  /// In fr, this message translates to:
  /// **'SUJET DE DÉBAT EN COURS'**
  String get activeDebateTopic;

  /// No description provided for @membersInCommunion.
  ///
  /// In fr, this message translates to:
  /// **'membres en communion actuellement'**
  String get membersInCommunion;

  /// No description provided for @typingIndicator.
  ///
  /// In fr, this message translates to:
  /// **'écrit...'**
  String get typingIndicator;

  /// No description provided for @replyTo.
  ///
  /// In fr, this message translates to:
  /// **'Réponse à'**
  String get replyTo;

  /// No description provided for @defineDebateTopicTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Définir un sujet de débat'**
  String get defineDebateTopicTooltip;

  /// No description provided for @inCommunion.
  ///
  /// In fr, this message translates to:
  /// **'en communion'**
  String get inCommunion;

  /// No description provided for @welcomeVisionMunokolive.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans la Vision Munokolive.'**
  String get welcomeVisionMunokolive;

  /// No description provided for @musiciansSalon.
  ///
  /// In fr, this message translates to:
  /// **'Salon des Musiciens'**
  String get musiciansSalon;

  /// No description provided for @pastorsSalon.
  ///
  /// In fr, this message translates to:
  /// **'Salon des Pasteurs'**
  String get pastorsSalon;

  /// No description provided for @cannotMessageSelf.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pouvez pas vous écrire à vous-même.'**
  String get cannotMessageSelf;

  /// No description provided for @sendError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur d\'envoi : '**
  String get sendError;

  /// No description provided for @viewProfile.
  ///
  /// In fr, this message translates to:
  /// **'Voir Profil'**
  String get viewProfile;

  /// No description provided for @privateMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message Privé'**
  String get privateMessage;

  /// No description provided for @createAccountLink.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccountLink;

  /// No description provided for @impossibleOpenWhatsApp.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir WhatsApp'**
  String get impossibleOpenWhatsApp;

  /// No description provided for @errorOpeningWhatsApp.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'ouverture de WhatsApp'**
  String get errorOpeningWhatsApp;

  /// No description provided for @numberNotAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Numéro non disponible'**
  String get numberNotAvailable;

  /// No description provided for @impossibleLaunchCall.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lancer l\'appel'**
  String get impossibleLaunchCall;

  /// No description provided for @promoteAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Promouvoir administrateur ?'**
  String get promoteAdmin;

  /// No description provided for @demoteAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Rétrograder administrateur ?'**
  String get demoteAdmin;

  /// No description provided for @confirmAdminRoleChange.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir {action} ce membre au rang d\'Administrateur ?'**
  String confirmAdminRoleChange(String action);

  /// No description provided for @promoteAction.
  ///
  /// In fr, this message translates to:
  /// **'Promouvoir'**
  String get promoteAction;

  /// No description provided for @demoteAction.
  ///
  /// In fr, this message translates to:
  /// **'Rétrograder'**
  String get demoteAction;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @roleUpdatedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Rôle mis à jour avec succès !'**
  String get roleUpdatedSuccess;

  /// No description provided for @errorUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la mise à jour : {error}'**
  String errorUpdate(String error);

  /// No description provided for @churchNotSpecified.
  ///
  /// In fr, this message translates to:
  /// **'Église non spécifiée'**
  String get churchNotSpecified;

  /// No description provided for @memberDistance.
  ///
  /// In fr, this message translates to:
  /// **'Frère {name} est à {distance}'**
  String memberDistance(String name, String distance);

  /// No description provided for @writePrivate.
  ///
  /// In fr, this message translates to:
  /// **'Écrire en Privé'**
  String get writePrivate;

  /// No description provided for @call.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get call;

  /// No description provided for @numberCopied.
  ///
  /// In fr, this message translates to:
  /// **'Numéro copié !'**
  String get numberCopied;

  /// No description provided for @whatsapp.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @sms.
  ///
  /// In fr, this message translates to:
  /// **'SMS'**
  String get sms;

  /// No description provided for @map.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get map;

  /// No description provided for @locationNotAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Localisation non disponible'**
  String get locationNotAvailable;

  /// No description provided for @mission.
  ///
  /// In fr, this message translates to:
  /// **'Mission'**
  String get mission;

  /// No description provided for @contactCaps.
  ///
  /// In fr, this message translates to:
  /// **'CONTACTER'**
  String get contactCaps;

  /// No description provided for @informations.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get informations;

  /// No description provided for @nearbyUserTitle.
  ///
  /// In fr, this message translates to:
  /// **'👋 {category} à proximité !'**
  String nearbyUserTitle(String category);

  /// No description provided for @nearbyUserBody.
  ///
  /// In fr, this message translates to:
  /// **'{name} est connecté près de vous. Connectez-vous !'**
  String nearbyUserBody(String name);

  /// No description provided for @memberNearbyDiscreet.
  ///
  /// In fr, this message translates to:
  /// **'Membre à proximité (Mode Discret)'**
  String get memberNearbyDiscreet;

  /// No description provided for @archiveMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode Archives'**
  String get archiveMode;

  /// No description provided for @archiveModeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour synchroniser le radar.'**
  String get archiveModeSubtitle;

  /// No description provided for @radarSynced.
  ///
  /// In fr, this message translates to:
  /// **'Radar synchronisé avec succès ! 📡'**
  String get radarSynced;

  /// No description provided for @gpsDisabled.
  ///
  /// In fr, this message translates to:
  /// **'GPS Désactivé'**
  String get gpsDisabled;

  /// No description provided for @permissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Permission Refusée'**
  String get permissionDenied;

  /// No description provided for @radarError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur Radar'**
  String get radarError;

  /// No description provided for @enableLocationMessage.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez activer la localisation pour voir le radar.'**
  String get enableLocationMessage;

  /// No description provided for @enableGPS.
  ///
  /// In fr, this message translates to:
  /// **'Activer le GPS'**
  String get enableGPS;

  /// No description provided for @openSettings.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir Paramètres'**
  String get openSettings;

  /// No description provided for @filterMusicians.
  ///
  /// In fr, this message translates to:
  /// **'Musiciens'**
  String get filterMusicians;

  /// No description provided for @filterMenOfGod.
  ///
  /// In fr, this message translates to:
  /// **'Hommes de Dieu'**
  String get filterMenOfGod;

  /// No description provided for @filterPlaces.
  ///
  /// In fr, this message translates to:
  /// **'Lieux'**
  String get filterPlaces;

  /// No description provided for @categoryMember.
  ///
  /// In fr, this message translates to:
  /// **'Membre'**
  String get categoryMember;

  /// No description provided for @categoryPlace.
  ///
  /// In fr, this message translates to:
  /// **'Lieu'**
  String get categoryPlace;

  /// No description provided for @categoryChurch.
  ///
  /// In fr, this message translates to:
  /// **'Église'**
  String get categoryChurch;

  /// No description provided for @categoryStudio.
  ///
  /// In fr, this message translates to:
  /// **'Studio d\'enregistrement'**
  String get categoryStudio;

  /// No description provided for @categoryRehearsal.
  ///
  /// In fr, this message translates to:
  /// **'Salle de répétition'**
  String get categoryRehearsal;

  /// No description provided for @categoryEventSpace.
  ///
  /// In fr, this message translates to:
  /// **'Espace événementiel'**
  String get categoryEventSpace;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
