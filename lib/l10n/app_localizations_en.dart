// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MunokoLive Music';

  @override
  String get welcomeMessage => 'Welcome to MunokoLive';

  @override
  String get loginButton => 'Log In';

  @override
  String get registerButton => 'Sign Up';

  @override
  String get homeTab => 'Home';

  @override
  String get eventsTab => 'Events';

  @override
  String get placesTab => 'Places';

  @override
  String get profileTab => 'Profile';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageOption => 'Language';

  @override
  String get themeOption => 'Theme';

  @override
  String get biometricsOption => 'Biometrics';

  @override
  String get notificationsOption => 'Notifications';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get referralCodeLabel => 'Referral Code';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get noAccount => 'No account yet?';

  @override
  String get alreadyAccount => 'Already have an account?';

  @override
  String get invalidEmail => 'Invalid Email';

  @override
  String get passwordMinLength => 'Min 6 characters';

  @override
  String get passwordsMismatch => 'Passwords do not match';

  @override
  String get referralCodeRequired => 'Referral code is required';

  @override
  String get authenticating => 'Authenticating...';

  @override
  String get success => 'Success!';

  @override
  String get verifying => 'Verifying...';

  @override
  String get initializing => 'Initializing...';

  @override
  String get redirecting => 'Redirecting...';

  @override
  String get creatingAccount => 'Creating account...';

  @override
  String get welcome => 'Welcome!';

  @override
  String get fixFormErrors => 'Please fix the errors in the form';

  @override
  String get invalidReferralCode => 'Invalid or missing referral code';

  @override
  String get networkError => 'Network connection issue.';

  @override
  String get weakPassword => 'Password is too weak (min 6 chars).';

  @override
  String get emailInUse => 'This email is already in use by another account.';

  @override
  String get invalidEmailMessage => 'The email address is invalid.';

  @override
  String get genericError => 'An error occurred';

  @override
  String get rateLimitError => 'Too many attempts. Please wait a moment.';

  @override
  String get invalidCredentials =>
      'Incorrect email or password. If you don\'t have an account yet, please sign up.';

  @override
  String get securityDelay =>
      'For security reasons, please wait before trying again.';

  @override
  String get welcomeBack => 'Welcome back!';

  @override
  String get joinFamily => 'Join the Family';

  @override
  String get loginToContinue => 'Log in to continue';

  @override
  String get createAccountSubtitle => 'Create your account in seconds';

  @override
  String get emailRequired => 'Email required';

  @override
  String get placesTitle => 'Our Places';

  @override
  String get addPlace => 'ADD';

  @override
  String get searchPlaceholder => 'Search (e.g. Yopougon, Studio...)';

  @override
  String get allCategories => 'All';

  @override
  String get church => 'Church';

  @override
  String get rehearsalRoom => 'Rehearsal Room';

  @override
  String get recordingStudio => 'Recording Studio';

  @override
  String get eventSpace => 'Event Space';

  @override
  String get listUpdated => 'List updated!';

  @override
  String get errorPrefix => 'Error: ';

  @override
  String get noPlacesFound => 'No places found.';

  @override
  String get closestPlace => 'Closest';

  @override
  String get addressUnspecified => 'Address unspecified';

  @override
  String get mapOpenError => 'Unable to open map';

  @override
  String get proposeSacredPlace => 'Propose a Sacred Place';

  @override
  String get exteriorFacade => 'Exterior (Facade)';

  @override
  String get interiorOptional => 'Interior (Optional)';

  @override
  String get placeNameLabel => 'Place Name';

  @override
  String get categoryLabel => 'Category';

  @override
  String get managerNameLabel => 'Manager Name';

  @override
  String get contactPhoneLabel => 'Contact (Phone)';

  @override
  String get markThisPlaceGps => 'MARK THIS PLACE (GPS HERE)';

  @override
  String get positionSavedEdit => 'Position Saved! (Edit)';

  @override
  String get submitForValidation => 'SUBMIT FOR VALIDATION';

  @override
  String get statusPreparing => 'Preparing...';

  @override
  String get statusUploadingMainPhoto => 'Uploading main photo...';

  @override
  String get statusUploadingInteriorPhoto => 'Uploading interior photo...';

  @override
  String get statusSavingPlace => 'Saving place...';

  @override
  String positionCaptured(double lat, double lng) {
    return '📍 Position captured: $lat, $lng';
  }

  @override
  String get gpsCaptureError => 'Unable to capture position. Check your GPS.';

  @override
  String get pleaseAddImage => 'Please add an image';

  @override
  String get pleaseCapturePosition => 'Please capture the place position';

  @override
  String get userNotLoggedIn => 'User not logged in';

  @override
  String get placeSubmittedTitle => 'Place submitted successfully';

  @override
  String get placePublishedImmediately =>
      'Place validated and published immediately.';

  @override
  String placeProposalSent(String name) {
    return 'Your proposal for $name has been sent.';
  }

  @override
  String get placeAddedAndValidated => '✅ Place added and validated!';

  @override
  String get placeSubmittedPending =>
      'Place submitted successfully! Awaiting validation.';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get resetEmailSent => 'Reset email sent';

  @override
  String get completeProfileTitle => 'Complete your profile';

  @override
  String get completeProfileSubtitle =>
      'A photo and your information are required for validation.';

  @override
  String get firstNameLabel => 'First Name';

  @override
  String get lastNameLabel => 'Last Name';

  @override
  String get firstNameRequired => 'First Name required';

  @override
  String get lastNameRequired => 'Last Name required';

  @override
  String get birthDateLabel => 'Date of Birth';

  @override
  String get birthDateRequired => 'Date required';

  @override
  String get churchLabel => 'Church / Parish';

  @override
  String get churchRequired => 'Church required';

  @override
  String get referralCodeActive => 'Referral Active';

  @override
  String get referralCodeMandatory => 'Referral Code (Mandatory)';

  @override
  String get privacyPolicyAccept => 'Please accept the Privacy Policy';

  @override
  String get photoRequired => 'Please add a profile photo (Mandatory)';

  @override
  String get optimizingPhoto => 'Optimizing your photo...';

  @override
  String get optimizingNetwork => 'Optimizing and checking network...';

  @override
  String get slowConnectionMessage =>
      'This is taking a bit longer than expected...\nChecking connection and optimizing photo.';

  @override
  String get uploadingPhoto => 'Uploading photo (this may take a moment)...';

  @override
  String get savingProfile => 'Saving profile...';

  @override
  String get finished => 'Finished!';

  @override
  String get musician => 'Musician';

  @override
  String get singerAndInstrumentalist => 'Singer & Instrumentalist';

  @override
  String get minister => 'Minister';

  @override
  String get servantOfGod => 'Servant of God';

  @override
  String get media => 'Media';

  @override
  String get photoVideoSound => 'Photo, Video, Sound';

  @override
  String get labelManager => 'Label / Manager';

  @override
  String get producer => 'Producer';

  @override
  String get organizer => 'Organizer';

  @override
  String get eventsAndConcerts => 'Events & Concerts';

  @override
  String get particular => 'Individual';

  @override
  String get musicLover => 'Music Lover / Worshipper';

  @override
  String get role => 'Role';

  @override
  String get selectRole => 'Select your role';

  @override
  String get instrument => 'Instrument';

  @override
  String get selectInstrument => 'Select your instrument';

  @override
  String get privacyPolicyText =>
      'I accept the Privacy Policy and Terms of Use';

  @override
  String get readAndAccept => 'I have read and accept the ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get ofAppByAuthor =>
      ' of Munokolive Music written by Christian Anisonok.';

  @override
  String get save => 'SAVE';

  @override
  String get instrumentOrRole => 'Instrument / Role';

  @override
  String get ministry => 'Ministry';

  @override
  String get selectionRequired => 'Selection required';

  @override
  String get rolePianist => 'Pianist';

  @override
  String get roleDrummer => 'Drummer';

  @override
  String get roleBassist => 'Bassist';

  @override
  String get roleGuitarist => 'Guitarist';

  @override
  String get roleSaxophonist => 'Saxophonist';

  @override
  String get rolePercussionist => 'Percussionist';

  @override
  String get roleViolinist => 'Violinist';

  @override
  String get roleSynthesizer => 'Synthesizer';

  @override
  String get roleTrumpeter => 'Trumpeter';

  @override
  String get roleFlutist => 'Flutist';

  @override
  String get roleSinger => 'Singer';

  @override
  String get roleChoirMaster => 'Choir Master';

  @override
  String get roleMusicTrainer => 'Music Trainer';

  @override
  String get roleSoundEngineer => 'Sound Engineer';

  @override
  String get roleBeatmaker => 'Beatmaker';

  @override
  String get rolePastor => 'Pastor';

  @override
  String get roleProphet => 'Prophet';

  @override
  String get roleDeacon => 'Deacon';

  @override
  String get roleEvangelist => 'Evangelist';

  @override
  String get roleDoctor => 'Doctor';

  @override
  String get roleApostle => 'Apostle';

  @override
  String get requiredField => 'This field is required';

  @override
  String get passwordUpdatedSuccess => 'Password updated successfully!';

  @override
  String get updatePasswordTitle => 'Update Password';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get updateButton => 'Update';

  @override
  String get cannotOpenWhatsApp => 'Cannot open WhatsApp';

  @override
  String get congratulations => 'CONGRATULATIONS!';

  @override
  String get accountValidated => 'Account Validated';

  @override
  String get redirectionInProgress =>
      'Welcome to Munoko Live Music.\nRedirecting...';

  @override
  String get verificationInProgress => 'VERIFICATION IN PROGRESS';

  @override
  String get profileAnalysisMessage =>
      'Your profile is being analyzed.\nPlease wait while we validate your information.';

  @override
  String get refreshingStatus => 'Refreshing status...';

  @override
  String get refreshStatusButton => 'REFRESH MY STATUS';

  @override
  String get supportButton => 'Support';

  @override
  String get quitButton => 'Quit';

  @override
  String get chooseLanguageTitle => 'Choose Language';

  @override
  String get biometricNotAvailable =>
      '⚠️ Biometrics not available on this device';

  @override
  String get biometricEnabledMsg => '🛡️ Biometric protection enabled!';

  @override
  String get biometricDisabledMsg => '🔓 Protection disabled';

  @override
  String get notificationsEnabledMsg => 'Notifications enabled';

  @override
  String get notificationsDisabledMsg => 'Notifications disabled';

  @override
  String get helpSupportTitle => 'HELP & SUPPORT';

  @override
  String get supportHeaderTitle => 'MUNOKOLIVE SUPPORT';

  @override
  String get supportHeaderSlogan =>
      'At your service so that God\'s service never stops.';

  @override
  String get sectionAiTitle => '1. AI ASSISTANCE (MUNO-IA)';

  @override
  String get sectionFaqTitle => '2. FREQUENTLY ASKED QUESTIONS (FAQ)';

  @override
  String get sectionContactTitle => '3. CONTACT THE OFFICE';

  @override
  String get sectionDiagnosticTitle => '4. DIAGNOSTIC CENTER';

  @override
  String get supportWhatsappButton => 'WHATSAPP SUPPORT';

  @override
  String get callAdminButton => 'Call Administrator';

  @override
  String get urgentValidationsHint => 'Recommended for urgent validations';

  @override
  String get supportEmailLabel => 'Support Email';

  @override
  String get emergencyReportLabel => 'Emergency Report';

  @override
  String get emergencyReportSubtitle => 'Report abuse or hacking';

  @override
  String get cacheCleared => 'Cache cleared successfully!';

  @override
  String get appVersionLabel => 'App Version';

  @override
  String get serverStatusLabel => 'Server Status';

  @override
  String get serverOperational => 'Operational';

  @override
  String get usefulIfImagesMessage =>
      'Useful if images no longer display correctly.';

  @override
  String get aboutTitle => 'ABOUT';

  @override
  String get appNameTitle => 'MUNOKOLIVE MUSIC';

  @override
  String get appSlogan =>
      'Connect Talent to Anointing,\nBuild Tomorrow\'s Horizon';

  @override
  String get sectionEssenceTitle => 'PROJECT ESSENCE';

  @override
  String get sectionVisionTitle => 'VISION OF THE HORIZON';

  @override
  String get sectionVisionSubtitle => '(Why Munokolive?)';

  @override
  String get sectionOrganizationTitle => 'OUR ORGANIZATION';

  @override
  String get sectionOrganizationSubtitle => 'THE BODY OF CHRIST';

  @override
  String get sectionTechTitle => 'TECHNOLOGICAL REVOLUTION';

  @override
  String get sectionTechSubtitle => 'AT THE SERVICE OF THE SPIRITUAL';

  @override
  String get sectionGoldenRuleTitle => 'OUR GOLDEN RULE';

  @override
  String get sectionGoldenRuleSubtitle => 'MUTUAL RESPECT';

  @override
  String get founderQuoteText =>
      'We are in Gospel Family\'s kitchen. Here, everyone works. This platform is the foundation of what we will build in the years to come by God\'s grace. Let us remain vigilant, united, and keep our eyes fixed on the horizon.';

  @override
  String get founderSignature => '— Christian ANISONOK';

  @override
  String get cguHeaderTitle => 'TERMS OF USE (CGU)\nMUNOKOLIVE MUSIC';

  @override
  String get cguVersionLine => 'Version 1.0 – \"Long-Term Future Vision\"';

  @override
  String get welcomeFamilyDialogTitle => 'WELCOME TO THE FAMILY';

  @override
  String get welcomeFamilyDialogSubtitle => 'The Future Vision starts now.';

  @override
  String get privacyTitleAppBar => 'Privacy';

  @override
  String get privacyHeaderTitle => 'PRIVACY POLICY\nMUNOKOLIVE MUSIC';

  @override
  String get lastUpdateLabel => 'Last update:';

  @override
  String get exclusivePropertyLine =>
      'Exclusive property of: Mr. Christian ANISONOK';

  @override
  String get legalProtectionMentionTitle => 'LEGAL PROTECTION NOTICE';

  @override
  String get pleaseAuthenticate => 'Please authenticate';

  @override
  String get biometricReason => 'Unlock MunokoLive to access your account';

  @override
  String get authenticationFailed => 'Authentication failed. Please try again.';

  @override
  String get secureAppTitle => 'MunokoLive Secure';

  @override
  String get retryButton => 'Retry';

  @override
  String get errorTitle => 'ERROR:';

  @override
  String get errorDetails => '\nDETAILS:';

  @override
  String get errorContext => '\nCONTEXT:';

  @override
  String get errorTrace => '\nTRACE (Top 5):';

  @override
  String get unknownTechnicalError => 'Unidentified Technical Error:\n';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get errorDisplayError => 'Error displaying error: ';

  @override
  String get systemDiagnostic => 'System Diagnostic';

  @override
  String get restartApp => 'Restart Application';

  @override
  String get pleaseRestartApp => 'Please restart the application';

  @override
  String get welcomeSuperAdmin => 'Welcome, Super Admin! You have all powers.';

  @override
  String get debateTopicTitle => 'Debate Topic';

  @override
  String get topicTitleLabel => 'Topic Title';

  @override
  String get descriptionLabel => 'Description (Optional)';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get publishButton => 'Publish';

  @override
  String get activeDebateTopic => 'CURRENT DEBATE TOPIC';

  @override
  String get membersInCommunion => 'members currently in communion';

  @override
  String get typingIndicator => 'is writing...';

  @override
  String get replyTo => 'Replying to';

  @override
  String get defineDebateTopicTooltip => 'Define a debate topic';

  @override
  String get inCommunion => 'in communion';

  @override
  String get welcomeVisionMunokolive => 'Welcome to the Munokolive Vision.';

  @override
  String get musiciansSalon => 'Musicians\' Lounge';

  @override
  String get pastorsSalon => 'Pastors\' Lounge';

  @override
  String get cannotMessageSelf => 'You cannot message yourself.';

  @override
  String get sendError => 'Send error: ';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get privateMessage => 'Private Message';

  @override
  String get createAccountLink => 'Create an account';

  @override
  String get impossibleOpenWhatsApp => 'Cannot open WhatsApp';

  @override
  String get errorOpeningWhatsApp => 'Error opening WhatsApp';

  @override
  String get numberNotAvailable => 'Number not available';

  @override
  String get impossibleLaunchCall => 'Cannot launch call';

  @override
  String get promoteAdmin => 'Promote to Admin?';

  @override
  String get demoteAdmin => 'Demote from Admin?';

  @override
  String confirmAdminRoleChange(String action) {
    return 'Are you sure you want to $action this member to Administrator rank?';
  }

  @override
  String get promoteAction => 'Promote';

  @override
  String get demoteAction => 'Demote';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get roleUpdatedSuccess => 'Role updated successfully!';

  @override
  String errorUpdate(String error) {
    return 'Error updating: $error';
  }

  @override
  String get churchNotSpecified => 'Church not specified';

  @override
  String memberDistance(String name, String distance) {
    return 'Brother $name is at $distance';
  }

  @override
  String get writePrivate => 'Private Message';

  @override
  String get call => 'Call';

  @override
  String get numberCopied => 'Number copied!';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get sms => 'SMS';

  @override
  String get map => 'Map';

  @override
  String get locationNotAvailable => 'Location not available';

  @override
  String get mission => 'Mission';

  @override
  String get contactCaps => 'CONTACT';

  @override
  String get informations => 'Information';

  @override
  String nearbyUserTitle(String category) {
    return '👋 $category nearby!';
  }

  @override
  String nearbyUserBody(String name) {
    return '$name is online near you. Connect!';
  }

  @override
  String get memberNearbyDiscreet => 'Member nearby (Discreet Mode)';

  @override
  String get archiveMode => 'Archive Mode';

  @override
  String get archiveModeSubtitle => 'Log in to sync radar.';

  @override
  String get radarSynced => 'Radar synced successfully! 📡';

  @override
  String get gpsDisabled => 'GPS Disabled';

  @override
  String get permissionDenied => 'Permission Denied';

  @override
  String get radarError => 'Radar Error';

  @override
  String get enableLocationMessage => 'Please enable location to see radar.';

  @override
  String get enableGPS => 'Enable GPS';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get filterMusicians => 'Musicians';

  @override
  String get filterMenOfGod => 'Men of God';

  @override
  String get filterPlaces => 'Places';

  @override
  String get categoryMember => 'Member';

  @override
  String get categoryPlace => 'Place';

  @override
  String get categoryChurch => 'Church';

  @override
  String get categoryStudio => 'Recording Studio';

  @override
  String get categoryRehearsal => 'Rehearsal Room';

  @override
  String get categoryEventSpace => 'Event Space';
}
