/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'package:munokolive_music/ui/admin/super_admin_dashboard.dart';
import '../profile/edit_profile_page.dart';
import 'help_support_page.dart';
import 'about_page.dart';
import 'cgu_page.dart';
import 'privacy_policy_page.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';
import 'package:munokolive_music/providers/theme_provider.dart';
import 'package:munokolive_music/providers/locale_provider.dart';
import 'package:munokolive_music/ui/settings/change_password_page.dart';
import 'package:munokolive_music/ui/profile/my_services_page.dart';
import 'package:munokolive_music/ui/booking/bookings_list_page.dart';
import 'package:munokolive_music/ui/onboarding/onboarding_screen.dart'; // Added
import 'package:munokolive_music/ui/widgets/animated_counter.dart'; // Added
import 'package:munokolive_music/l10n/app_localizations.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _biometricsEnabled = false;
  bool _darkModeEnabled = true;
  String _selectedLanguage = 'Français';
  final LocalAuthentication auth = LocalAuthentication();
  late SharedPreferences _prefs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    // Sync local state with ThemeProvider
    final isDark = ref.read(themeProvider.notifier).isDarkMode;
    // Sync local state with LocaleProvider
    final languageName = ref.read(localeProvider.notifier).getDisplayName();

    setState(() {
      _notificationsEnabled = _prefs.getBool('notifications_enabled') ?? true;
      _biometricsEnabled = _prefs.getBool('biometrics_enabled') ?? false;
      _darkModeEnabled = isDark;
      _selectedLanguage = languageName;
      _isLoading = false;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      if (!canAuthenticateWithBiometrics) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Biométrie non disponible sur cet appareil'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      try {
        final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Veuillez confirmer votre identité',
          // options: const AuthenticationOptions(
          //   stickyAuth: true,
          //   biometricOnly: true,
          // ),
        );

        if (!didAuthenticate) return;
      } catch (e) {
        // Suppress user canceled errors
        if (e.toString().contains('userCanceled')) return;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur d\'authentification: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _biometricsEnabled = value;
    });
    await _prefs.setBool('biometrics_enabled', value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                value ? Icons.lock_outline : Icons.lock_open,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value
                      ? '🛡️ Protection biométrique activée !'
                      : '🔓 Protection désactivée',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: value ? Colors.green.shade700 : Colors.grey.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    await _prefs.setBool('notifications_enabled', value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Notifications activées' : 'Notifications désactivées',
          ),
          backgroundColor: value ? Colors.green : Colors.grey,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    setState(() {
      _darkModeEnabled = value;
    });
    ref.read(themeProvider.notifier).toggleTheme(value);
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Builder(
          builder: (context) => Text(
            AppLocalizations.of(context)!.chooseLanguageTitle,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        content: DropdownButtonFormField<String>(
          initialValue: _selectedLanguage,
          dropdownColor: const Color(0xFF2A2A2A),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
            ),
          ),
          items: ['Français', 'English']
              .map((lang) => DropdownMenuItem(
                    value: lang,
                    child: Text(lang, style: const TextStyle(color: Colors.white)),
                  ))
              .toList(),
          onChanged: (value) async {
            if (value != null) {
              setState(() => _selectedLanguage = value);
              final code = LocaleState.getCodeFromDisplayName(value);
              await ref.read(localeProvider.notifier).setLocale(code);
              if (context.mounted) Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    final userAsync = ref.watch(currentUserProfileProvider);
    final isDark =
        ref.watch(themeProvider) == ThemeMode.dark ||
        (ref.watch(themeProvider) == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.grey.withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Paramètres',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: Theme.of(
          context,
        ).scaffoldBackgroundColor.withValues(alpha: 0.7),
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1A1A), Colors.black],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF5F5F5), Colors.white],
                ),
        ),
        child: userAsync.when(
          data: (user) {
            if (user == null) {
              return Center(
                child: Text(
                  'Utilisateur non connecté',
                  style: TextStyle(color: textColor),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.2),
                        AppTheme.secondaryColor.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.primaryColor,
                        backgroundImage: (user.photoUrl?.isNotEmpty ?? false)
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: (user.photoUrl?.isEmpty ?? true)
                            ? Text(
                                user.firstName.isNotEmpty
                                    ? user.firstName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.firstName} ${user.lastName}',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.email ?? 'Email non renseigné',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Gamification Points Display
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.stars,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  AnimatedCounter(
                                    value: user.points,
                                    suffix: ' pts',
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: AppTheme.primaryColor,
                        ),
                        onPressed: () {
                          // Navigate to Profile Page in Edit Mode
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfilePage(user: user),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                _buildSectionHeader('Services & Missions', isDark),
                _buildSettingsTile(
                  icon: Icons.calendar_today,
                  title: 'Mes Réservations',
                  subtitle: 'Suivre mes commandes et missions',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookingsListPage()),
                  ),
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  cardColor: cardColor,
                ),
                _buildSettingsTile(
                  icon: Icons.work_outline,
                  title: 'Espace Prestataire',
                  subtitle: 'Gérer mes services et tarifs',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyServicesPage()),
                  ),
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  cardColor: cardColor,
                ),
                const SizedBox(height: 24),

                _buildSectionHeader('Préférences', isDark),
                _buildSettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Alertes push et messages',
                  trailing: Switch(
                    value: _notificationsEnabled,
                    activeThumbColor: AppTheme.primaryColor,
                    onChanged: (val) => _toggleNotifications(val),
                  ),
                  onTap: () => _toggleNotifications(!_notificationsEnabled),
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  cardColor: cardColor,
                ),
                _buildSettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Mode Sombre',
                  subtitle: 'Thème de l\'application',
                  trailing: Switch(
                    value: _darkModeEnabled,
                    activeThumbColor: AppTheme.primaryColor,
                    onChanged: (val) => _toggleDarkMode(val),
                  ),
                  onTap: () => _toggleDarkMode(!_darkModeEnabled),
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  cardColor: cardColor,
                ),
                _buildSettingsTile(
                  icon: Icons.language,
                  title: 'Langue',
                  subtitle: _selectedLanguage,
                  onTap: _showLanguageDialog,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  cardColor: cardColor,
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Sécurité', isDark),
                _buildSettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Changer le mot de passe',
                  subtitle: 'Mettre à jour vos accès',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordPage(),
                      ),
                    );
                  },
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  cardColor: cardColor,
                ),
                _buildSettingsTile(
                  icon: Icons.fingerprint,
                  title: 'Verrouillage App',
                  subtitle: _biometricsEnabled
                      ? '🔒 Protection active'
                      : 'Non sécurisé',
                  trailing: Switch(
                    value: _biometricsEnabled,
                    activeThumbColor: AppTheme.primaryColor,
                    onChanged: (val) => _toggleBiometrics(val),
                  ),
                  onTap: () => _toggleBiometrics(!_biometricsEnabled),
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  cardColor: cardColor,
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Aide & À propos', isDark),
                _buildSettingsTile(
                  icon: Icons.gavel,
                  title: 'CGU / Vision',
                  subtitle: 'Conditions Générales d\'Utilisation',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CguPage()),
                    );
                  },
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  cardColor: cardColor,
                ),
                _buildSettingsTile(
                  icon: Icons.rocket_launch,
                  title: 'Revoir l\'introduction',
                  subtitle: 'Redécouvrir les fonctionnalités',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OnboardingScreen(),
                      ),
                    );
                  },
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  cardColor: cardColor,
                ),
                _buildSettingsTile(
                  icon: Icons.policy,
                  title: 'Légal & Confidentialité',
                  subtitle: 'Politique de protection des données',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyPage(),
                      ),
                    );
                  },
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  cardColor: cardColor,
                ),
                _buildSettingsTile(
                  icon: Icons.help_outline,
                  title: 'Aide & Support',
                  subtitle: 'FAQ et Contact',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportPage(),
                      ),
                    );
                  },
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  cardColor: cardColor,
                ),
                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: 'À Propos',
                  subtitle: 'Version, Licences & Surprise',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutPage(),
                      ),
                    );
                  },
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  cardColor: cardColor,
                ),
                const SizedBox(height: 24),

                if (user.role == 'admin' || user.role == 'super_admin') ...[
                  _buildSectionHeader('Administration & Outils', isDark),

                  // Le bouton demandé explicitement pour l'admin
                  _buildSettingsTile(
                    icon: Icons.admin_panel_settings,
                    title: 'Centre de Contrôle',
                    subtitle: 'Gestion utilisateurs et événements',
                    color: AppTheme.primaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SuperAdminDashboard(),
                        ),
                      );
                    },
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Admin',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    cardColor: cardColor,
                  ),
                ],

                const SizedBox(height: 32),

                // Logout Button
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      side: BorderSide(
                        color: Colors.red.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, size: 20),
                        SizedBox(width: 8),
                        Text('Se déconnecter'),
                      ],
                    ),
                  ),
                ),

                // IP Signature
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'Propriété exclusive de Christian Anisonok',
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, stack) => Center(child: Text('Erreur: $e')),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark ? AppTheme.textSecondary : Colors.black54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color =
        Colors.grey, // Default icon color for light mode if not overridden
    Widget? trailing,
    required Color textColor,
    required Color subtitleColor,
    required Color cardColor,
  }) {
    // If color is default grey, adapt it to current text color logic unless overridden
    final iconColor = color == Colors.grey ? textColor : color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: subtitleColor, fontSize: 12),
        ),
        trailing:
            trailing ??
            Icon(
              Icons.arrow_forward_ios,
              color: subtitleColor.withValues(alpha: 0.5),
              size: 16,
            ),
      ),
    );
  }
}
