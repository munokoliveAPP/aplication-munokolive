// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'MunokoLive Music';

  @override
  String get welcomeMessage => 'Bienvenue sur MunokoLive';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get registerButton => 'S\'inscrire';

  @override
  String get homeTab => 'Accueil';

  @override
  String get eventsTab => 'Événements';

  @override
  String get placesTab => 'Lieux';

  @override
  String get profileTab => 'Profil';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get languageOption => 'Langue';

  @override
  String get themeOption => 'Thème';

  @override
  String get biometricsOption => 'Biométrie';

  @override
  String get notificationsOption => 'Notifications';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get confirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get referralCodeLabel => 'Code de parrainage';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get noAccount => 'Pas encore de compte ?';

  @override
  String get alreadyAccount => 'Déjà un compte ?';

  @override
  String get invalidEmail => 'Email invalide';

  @override
  String get passwordMinLength => 'Min 6 caractères';

  @override
  String get passwordsMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get referralCodeRequired => 'Le code parrain est obligatoire';

  @override
  String get authenticating => 'Authentification...';

  @override
  String get success => 'Succès !';

  @override
  String get verifying => 'Vérification...';

  @override
  String get initializing => 'Initialisation...';

  @override
  String get redirecting => 'Redirection...';

  @override
  String get creatingAccount => 'Création du compte...';

  @override
  String get welcome => 'Bienvenue !';

  @override
  String get fixFormErrors =>
      'Veuillez corriger les erreurs dans le formulaire';

  @override
  String get invalidReferralCode => 'Code parrain invalide ou introuvable';

  @override
  String get networkError => 'Problème de connexion internet.';

  @override
  String get weakPassword =>
      'Le mot de passe est trop faible (6 caractères min).';

  @override
  String get emailInUse => 'Cet email est déjà utilisé par un autre compte.';

  @override
  String get invalidEmailMessage => 'L\'adresse email est invalide.';

  @override
  String get genericError => 'Une erreur est survenue';

  @override
  String get rateLimitError =>
      'Trop de tentatives. Veuillez patienter un moment.';

  @override
  String get invalidCredentials =>
      'Email ou mot de passe incorrect. Si vous n\'avez pas encore de compte, veuillez vous inscrire.';

  @override
  String get securityDelay =>
      'Pour des raisons de sécurité, veuillez patienter avant de réessayer.';

  @override
  String get welcomeBack => 'Heureux de vous revoir !';

  @override
  String get joinFamily => 'Rejoindre la Famille';

  @override
  String get loginToContinue => 'Connectez-vous pour continuer';

  @override
  String get createAccountSubtitle => 'Créez votre compte en quelques secondes';

  @override
  String get emailRequired => 'Email requis';

  @override
  String get placesTitle => 'Nos Lieux';

  @override
  String get addPlace => 'AJOUTER';

  @override
  String get searchPlaceholder => 'Rechercher (ex: Yopougon, Studio...)';

  @override
  String get allCategories => 'Tous';

  @override
  String get church => 'Église';

  @override
  String get rehearsalRoom => 'Salle de répétition';

  @override
  String get recordingStudio => 'Studio d\'enregistrement';

  @override
  String get eventSpace => 'Espace événementiel';

  @override
  String get listUpdated => 'Liste mise à jour !';

  @override
  String get errorPrefix => 'Erreur : ';

  @override
  String get noPlacesFound => 'Aucun lieu trouvé.';

  @override
  String get closestPlace => 'Le plus proche';

  @override
  String get addressUnspecified => 'Adresse non spécifiée';

  @override
  String get mapOpenError => 'Impossible d\'ouvrir la carte';

  @override
  String get proposeSacredPlace => 'Proposer un lieu sacré';

  @override
  String get exteriorFacade => 'Extérieur (Façade)';

  @override
  String get interiorOptional => 'Intérieur (Optionnel)';

  @override
  String get placeNameLabel => 'Nom du lieu';

  @override
  String get categoryLabel => 'Catégorie';

  @override
  String get managerNameLabel => 'Nom du responsable';

  @override
  String get contactPhoneLabel => 'Contact (Téléphone)';

  @override
  String get markThisPlaceGps => 'MARQUER CE LIEU (GPS ICI)';

  @override
  String get positionSavedEdit => 'Position Enregistrée ! (Modifier)';

  @override
  String get submitForValidation => 'SOUMETTRE À VALIDATION';

  @override
  String get statusPreparing => 'Préparation...';

  @override
  String get statusUploadingMainPhoto => 'Envoi de la photo principale...';

  @override
  String get statusUploadingInteriorPhoto => 'Envoi de la photo intérieure...';

  @override
  String get statusSavingPlace => 'Enregistrement du lieu...';

  @override
  String positionCaptured(double lat, double lng) {
    return '📍 Position capturée : $lat, $lng';
  }

  @override
  String get gpsCaptureError =>
      'Impossible de capturer la position. Vérifiez votre GPS.';

  @override
  String get pleaseAddImage => 'Veuillez ajouter une image';

  @override
  String get pleaseCapturePosition => 'Veuillez capturer la position du lieu';

  @override
  String get userNotLoggedIn => 'Utilisateur non connecté';

  @override
  String get placeSubmittedTitle => 'Lieu soumis avec succès';

  @override
  String get placePublishedImmediately =>
      'Lieu validé et publié immédiatement.';

  @override
  String placeProposalSent(String name) {
    return 'Votre proposition pour $name a été envoyée.';
  }

  @override
  String get placeAddedAndValidated => '✅ Lieu ajouté et validé !';

  @override
  String get placeSubmittedPending =>
      'Lieu soumis avec succès ! En attente de validation.';

  @override
  String get pleaseEnterEmail => 'Veuillez entrer votre email';

  @override
  String get resetEmailSent => 'Email de réinitialisation envoyé';

  @override
  String get completeProfileTitle => 'Complétez votre profil';

  @override
  String get completeProfileSubtitle =>
      'Une photo et vos informations sont requises pour la validation.';

  @override
  String get firstNameLabel => 'Prénom';

  @override
  String get lastNameLabel => 'Nom';

  @override
  String get firstNameRequired => 'Prénom requis';

  @override
  String get lastNameRequired => 'Nom requis';

  @override
  String get birthDateLabel => 'Date de naissance';

  @override
  String get birthDateRequired => 'Date requise';

  @override
  String get churchLabel => 'Église / Paroisse';

  @override
  String get churchRequired => 'Église requise';

  @override
  String get referralCodeActive => 'Parrainage activé';

  @override
  String get referralCodeMandatory => 'Code Parrain (Obligatoire)';

  @override
  String get privacyPolicyAccept =>
      'Veuillez accepter la Politique de Confidentialité';

  @override
  String get photoRequired =>
      'Veuillez ajouter une photo de profil (Obligatoire)';

  @override
  String get optimizingPhoto => 'Optimisation de votre photo en cours...';

  @override
  String get optimizingNetwork => 'Optimisation et vérification réseau...';

  @override
  String get slowConnectionMessage =>
      'Cela prend un peu plus de temps que prévu...\nVérification de la connexion et optimisation de la photo en cours.';

  @override
  String get uploadingPhoto =>
      'Envoi de la photo (cela peut prendre un moment)...';

  @override
  String get savingProfile => 'Enregistrement du profil...';

  @override
  String get finished => 'Terminé !';

  @override
  String get musician => 'Musicien';

  @override
  String get singerAndInstrumentalist => 'Chantre & Instrumentiste';

  @override
  String get minister => 'Ministre';

  @override
  String get servantOfGod => 'Serviteur de Dieu';

  @override
  String get media => 'Média';

  @override
  String get photoVideoSound => 'Photo, Vidéo, Son';

  @override
  String get labelManager => 'Label / Manager';

  @override
  String get producer => 'Producteur';

  @override
  String get organizer => 'Organisateur';

  @override
  String get eventsAndConcerts => 'Événements & Concerts';

  @override
  String get particular => 'Particulier';

  @override
  String get musicLover => 'Mélomane / Adorateur';

  @override
  String get role => 'Rôle';

  @override
  String get selectRole => 'Sélectionnez votre rôle';

  @override
  String get instrument => 'Instrument';

  @override
  String get selectInstrument => 'Sélectionnez votre instrument';

  @override
  String get privacyPolicyText =>
      'J\'accepte la Politique de Confidentialité et les Conditions d\'Utilisation';

  @override
  String get readAndAccept => 'J\'ai lu et j\'accepte la ';

  @override
  String get privacyPolicy => 'Politique de Confidentialité';

  @override
  String get ofAppByAuthor =>
      ' de Munokolive Music rédigée par Christian Anisonok.';

  @override
  String get save => 'ENREGISTRER';

  @override
  String get instrumentOrRole => 'Instrument / Rôle';

  @override
  String get ministry => 'Ministère';

  @override
  String get selectionRequired => 'Sélection requise';

  @override
  String get rolePianist => 'Pianiste';

  @override
  String get roleDrummer => 'Batteur';

  @override
  String get roleBassist => 'Bassiste';

  @override
  String get roleGuitarist => 'Guitariste';

  @override
  String get roleSaxophonist => 'Saxophoniste';

  @override
  String get rolePercussionist => 'Percussionniste';

  @override
  String get roleViolinist => 'Violoniste';

  @override
  String get roleSynthesizer => 'Synthétiseur';

  @override
  String get roleTrumpeter => 'Trompettiste';

  @override
  String get roleFlutist => 'Flûtiste';

  @override
  String get roleSinger => 'Chantre';

  @override
  String get roleChoirMaster => 'Maître de chœur';

  @override
  String get roleMusicTrainer => 'Formateur Musique';

  @override
  String get roleSoundEngineer => 'Ingénieur son';

  @override
  String get roleBeatmaker => 'Beatmaker';

  @override
  String get rolePastor => 'Pasteur';

  @override
  String get roleProphet => 'Prophète';

  @override
  String get roleDeacon => 'Diacre';

  @override
  String get roleEvangelist => 'Évangéliste';

  @override
  String get roleDoctor => 'Docteur';

  @override
  String get roleApostle => 'Apôtre';

  @override
  String get requiredField => 'Ce champ est requis';

  @override
  String get passwordUpdatedSuccess => 'Mot de passe mis à jour avec succès !';

  @override
  String get updatePasswordTitle => 'Mise à jour du mot de passe';

  @override
  String get newPasswordLabel => 'Nouveau mot de passe';

  @override
  String get updateButton => 'Mettre à jour';

  @override
  String get cannotOpenWhatsApp => 'Impossible d\'ouvrir WhatsApp';

  @override
  String get congratulations => 'FÉLICITATIONS !';

  @override
  String get accountValidated => 'Compte validé';

  @override
  String get redirectionInProgress =>
      'Bienvenue sur Munoko Live Music.\nRedirection en cours...';

  @override
  String get verificationInProgress => 'VÉRIFICATION EN COURS';

  @override
  String get profileAnalysisMessage =>
      'Votre profil est en cours d\'analyse.\nMerci de patienter pendant que nous validons vos informations.';

  @override
  String get refreshingStatus => 'Actualisation du statut...';

  @override
  String get refreshStatusButton => 'ACTUALISER MON STATUT';

  @override
  String get supportButton => 'Support';

  @override
  String get quitButton => 'Quitter';

  @override
  String get chooseLanguageTitle => 'Choisir la langue';

  @override
  String get biometricNotAvailable =>
      '⚠️ Biométrie non disponible sur cet appareil';

  @override
  String get biometricEnabledMsg => '🛡️ Protection biométrique activée !';

  @override
  String get biometricDisabledMsg => '🔓 Protection désactivée';

  @override
  String get notificationsEnabledMsg => 'Notifications activées';

  @override
  String get notificationsDisabledMsg => 'Notifications désactivées';

  @override
  String get helpSupportTitle => 'AIDE & SUPPORT';

  @override
  String get supportHeaderTitle => 'MUNOKOLIVE SUPPORT';

  @override
  String get supportHeaderSlogan =>
      'À votre service pour que le service de Dieu ne s\'arrête jamais.';

  @override
  String get sectionAiTitle => '1. ASSISTANCE IA (MUNO-IA)';

  @override
  String get sectionFaqTitle => '2. FOIRE AUX QUESTIONS (FAQ)';

  @override
  String get sectionContactTitle => '3. CONTACTER LE BUREAU';

  @override
  String get sectionDiagnosticTitle => '4. CENTRE DE DIAGNOSTIC';

  @override
  String get supportWhatsappButton => 'SUPPORT WHATSAPP';

  @override
  String get callAdminButton => 'Appeler l\'Administrateur';

  @override
  String get urgentValidationsHint =>
      'Recommandé pour les validations urgentes';

  @override
  String get supportEmailLabel => 'Support Email';

  @override
  String get emergencyReportLabel => 'Signalement d\'Urgence';

  @override
  String get emergencyReportSubtitle => 'Signaler un abus ou piratage';

  @override
  String get cacheCleared => 'Cache vidé avec succès !';

  @override
  String get appVersionLabel => 'Version de l\'App';

  @override
  String get serverStatusLabel => 'Statut Serveur';

  @override
  String get serverOperational => 'Opérationnel';

  @override
  String get usefulIfImagesMessage =>
      'Utile si les images ne s\'affichent plus correctement.';

  @override
  String get aboutTitle => 'À PROPOS';

  @override
  String get appNameTitle => 'MUNOKOLIVE MUSIC';

  @override
  String get appSlogan =>
      'Connecter le Talent à l’Onction,\nBâtir l’Horizon de Demain';

  @override
  String get sectionEssenceTitle => 'L\'ESSENCE DU PROJET';

  @override
  String get sectionVisionTitle => 'LA VISION DE L’HORIZON';

  @override
  String get sectionVisionSubtitle => '(Pourquoi Munokolive ?)';

  @override
  String get sectionOrganizationTitle => 'NOTRE ORGANISATION';

  @override
  String get sectionOrganizationSubtitle => 'LE CORPS DU CHRIST';

  @override
  String get sectionTechTitle => 'RÉVOLUTION TECHNOLOGIQUE';

  @override
  String get sectionTechSubtitle => 'AU SERVICE DU SPIRITUEL';

  @override
  String get sectionGoldenRuleTitle => 'NOTRE RÈGLE D’OR';

  @override
  String get sectionGoldenRuleSubtitle => 'LE RESPECT MUTUEL';

  @override
  String get founderQuoteText =>
      'Nous sommes à la cuisine de Gospel Family. Ici, tout le monde travaille. Cette plateforme est le socle de ce que nous bâtirons dans les années à venir par la grâce de Dieu. Restons vigilants, restons unis, et gardons les yeux fixés sur l\'horizon.';

  @override
  String get founderSignature => '— Christian ANISONOK';

  @override
  String get cguHeaderTitle =>
      'CONDITIONS GÉNÉRALES D\'UTILISATION (CGU)\nMUNOKOLIVE MUSIC';

  @override
  String get cguVersionLine =>
      'Version 1.0 – \"La Vision du Futur à Long Terme\"';

  @override
  String get welcomeFamilyDialogTitle => 'BIENVENUE DANS LA FAMILLE';

  @override
  String get welcomeFamilyDialogSubtitle =>
      'La Vision du Futur commence maintenant.';

  @override
  String get privacyTitleAppBar => 'Confidentialité';

  @override
  String get privacyHeaderTitle =>
      'POLITIQUE DE CONFIDENTIALITÉ\nMUNOKOLIVE MUSIC';

  @override
  String get lastUpdateLabel => 'Dernière mise à jour :';

  @override
  String get exclusivePropertyLine =>
      'Propriété exclusive de : M. Christian ANISONOK';

  @override
  String get legalProtectionMentionTitle => 'MENTION LÉGALE DE PROTECTION';

  @override
  String get pleaseAuthenticate => 'Veuillez vous authentifier';

  @override
  String get biometricReason =>
      'Déverrouillez MunokoLive pour accéder à votre compte';

  @override
  String get authenticationFailed => 'Échec de l\'authentification. Réessayez.';

  @override
  String get secureAppTitle => 'MunokoLive Sécurisé';

  @override
  String get retryButton => 'Réessayer';

  @override
  String get errorTitle => 'ERREUR :';

  @override
  String get errorDetails => '\nDÉTAILS :';

  @override
  String get errorContext => '\nCONTEXTE :';

  @override
  String get errorTrace => '\nTRACE (Top 5) :';

  @override
  String get unknownTechnicalError => 'Erreur Technique Non Identifiée :\n';

  @override
  String get unknownError => 'Erreur inconnue';

  @override
  String get errorDisplayError => 'Erreur d\'affichage de l\'erreur : ';

  @override
  String get systemDiagnostic => 'Diagnostic Système';

  @override
  String get restartApp => 'Relancer l\'application';

  @override
  String get pleaseRestartApp => 'Veuillez redémarrer l\'application';

  @override
  String get welcomeSuperAdmin =>
      'Bienvenue, Super Admin ! Vous avez tous les pouvoirs.';

  @override
  String get debateTopicTitle => 'Sujet de Débat';

  @override
  String get topicTitleLabel => 'Titre du sujet';

  @override
  String get descriptionLabel => 'Description (Optionnel)';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get publishButton => 'Publier';

  @override
  String get activeDebateTopic => 'SUJET DE DÉBAT EN COURS';

  @override
  String get membersInCommunion => 'membres en communion actuellement';

  @override
  String get typingIndicator => 'écrit...';

  @override
  String get replyTo => 'Réponse à';

  @override
  String get defineDebateTopicTooltip => 'Définir un sujet de débat';

  @override
  String get inCommunion => 'en communion';

  @override
  String get welcomeVisionMunokolive => 'Bienvenue dans la Vision Munokolive.';

  @override
  String get musiciansSalon => 'Salon des Musiciens';

  @override
  String get pastorsSalon => 'Salon des Pasteurs';

  @override
  String get cannotMessageSelf => 'Vous ne pouvez pas vous écrire à vous-même.';

  @override
  String get sendError => 'Erreur d\'envoi : ';

  @override
  String get viewProfile => 'Voir Profil';

  @override
  String get privateMessage => 'Message Privé';

  @override
  String get createAccountLink => 'Créer un compte';

  @override
  String get impossibleOpenWhatsApp => 'Impossible d\'ouvrir WhatsApp';

  @override
  String get errorOpeningWhatsApp => 'Erreur lors de l\'ouverture de WhatsApp';

  @override
  String get numberNotAvailable => 'Numéro non disponible';

  @override
  String get impossibleLaunchCall => 'Impossible de lancer l\'appel';

  @override
  String get promoteAdmin => 'Promouvoir administrateur ?';

  @override
  String get demoteAdmin => 'Rétrograder administrateur ?';

  @override
  String confirmAdminRoleChange(String action) {
    return 'Êtes-vous sûr de vouloir $action ce membre au rang d\'Administrateur ?';
  }

  @override
  String get promoteAction => 'Promouvoir';

  @override
  String get demoteAction => 'Rétrograder';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get roleUpdatedSuccess => 'Rôle mis à jour avec succès !';

  @override
  String errorUpdate(String error) {
    return 'Erreur lors de la mise à jour : $error';
  }

  @override
  String get churchNotSpecified => 'Église non spécifiée';

  @override
  String memberDistance(String name, String distance) {
    return 'Frère $name est à $distance';
  }

  @override
  String get writePrivate => 'Écrire en Privé';

  @override
  String get call => 'Appeler';

  @override
  String get numberCopied => 'Numéro copié !';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get sms => 'SMS';

  @override
  String get map => 'Carte';

  @override
  String get locationNotAvailable => 'Localisation non disponible';

  @override
  String get mission => 'Mission';

  @override
  String get contactCaps => 'CONTACTER';

  @override
  String get informations => 'Informations';

  @override
  String nearbyUserTitle(String category) {
    return '👋 $category à proximité !';
  }

  @override
  String nearbyUserBody(String name) {
    return '$name est connecté près de vous. Connectez-vous !';
  }

  @override
  String get memberNearbyDiscreet => 'Membre à proximité (Mode Discret)';

  @override
  String get archiveMode => 'Mode Archives';

  @override
  String get archiveModeSubtitle =>
      'Connectez-vous pour synchroniser le radar.';

  @override
  String get radarSynced => 'Radar synchronisé avec succès ! 📡';

  @override
  String get gpsDisabled => 'GPS Désactivé';

  @override
  String get permissionDenied => 'Permission Refusée';

  @override
  String get radarError => 'Erreur Radar';

  @override
  String get enableLocationMessage =>
      'Veuillez activer la localisation pour voir le radar.';

  @override
  String get enableGPS => 'Activer le GPS';

  @override
  String get openSettings => 'Ouvrir Paramètres';

  @override
  String get filterMusicians => 'Musiciens';

  @override
  String get filterMenOfGod => 'Hommes de Dieu';

  @override
  String get filterPlaces => 'Lieux';

  @override
  String get categoryMember => 'Membre';

  @override
  String get categoryPlace => 'Lieu';

  @override
  String get categoryChurch => 'Église';

  @override
  String get categoryStudio => 'Studio d\'enregistrement';

  @override
  String get categoryRehearsal => 'Salle de répétition';

  @override
  String get categoryEventSpace => 'Espace événementiel';
}
