// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../admin/admin_dashboard_page.dart';
import '../profile/user_profile_page.dart';
import 'privacy_settings_page.dart';
import 'help_support_page.dart';
import 'about_page.dart';
import '../../services/auth_service.dart';

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
    setState(() {
      _notificationsEnabled = _prefs.getBool('notifications_enabled') ?? true;
      _biometricsEnabled = _prefs.getBool('biometrics_enabled') ?? false;
      _darkModeEnabled = _prefs.getBool('dark_mode_enabled') ?? true;
      _selectedLanguage = _prefs.getString('language') ?? 'Français';
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
              content: Text('Biométrie non disponible sur cet appareil'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      try {
        final bool didAuthenticate = await auth.authenticate(
          localizedReason:
              'Veuillez vous authentifier pour activer la biométrie',
        );

        if (!didAuthenticate) return;
      } catch (e) {
        // Fallback or Error handling
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
          content: Text(
            value ? 'Biométrie activée et sécurisée' : 'Biométrie désactivée',
          ),
          backgroundColor: value ? Colors.green : Colors.grey,
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
    await _prefs.setBool('dark_mode_enabled', value);
    // Note: Actual theme switching logic would go here (e.g. updating a ThemeProvider)
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Choisir la langue',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Français', 'English', 'Español', 'Lingala'].map((lang) {
            return RadioListTile<String>(
              title: Text(lang, style: const TextStyle(color: Colors.white)),
              value: lang,
              groupValue: _selectedLanguage,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) async {
                if (value != null) {
                  setState(() => _selectedLanguage = value);
                  await _prefs.setString('language', value);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A1A), Colors.black],
          ),
        ),
        child: userAsync.when(
          data: (user) {
            if (user == null) {
              return const Center(
                child: Text(
                  'Utilisateur non connecté',
                  style: TextStyle(color: Colors.white),
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.email ?? 'Email non renseigné',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
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
                                  Text(
                                    '${user.points} pts',
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
                              builder: (context) => UserProfilePage(
                                userId: user.uid,
                                startEditing: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                _buildSectionHeader('Préférences'),
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
                ),
                _buildSettingsTile(
                  icon: Icons.language,
                  title: 'Langue',
                  subtitle: '$_selectedLanguage (Défaut)',
                  onTap: _showLanguageDialog,
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Sécurité'),
                _buildSettingsTile(
                  icon: Icons.fingerprint,
                  title: 'Biométrie',
                  subtitle: 'Verrouillage par empreinte',
                  trailing: Switch(
                    value: _biometricsEnabled,
                    activeThumbColor: AppTheme.primaryColor,
                    onChanged: (val) => _toggleBiometrics(val),
                  ),
                  onTap: () => _toggleBiometrics(!_biometricsEnabled),
                ),
                _buildSettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Confidentialité',
                  subtitle: 'Gérer vos données & Sécurité',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacySettingsPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Aide & À propos'),
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
                ),
                const SizedBox(height: 24),

                _buildSectionHeader('Administration & Outils'),

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
                        builder: (context) => const AdminDashboardPage(),
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
                ),

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
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, stack) => Center(child: Text('Erreur: $e')),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textSecondary,
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
    Color color = Colors.white,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        trailing:
            trailing ??
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white24,
              size: 16,
            ),
      ),
    );
  }
}
