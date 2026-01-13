import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:munokolive_music/models/user_profile.dart';
import 'package:munokolive_music/services/auth_service.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';

class PrivacySettingsPage extends ConsumerStatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  ConsumerState<PrivacySettingsPage> createState() =>
      _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends ConsumerState<PrivacySettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _shieldController;
  late Animation<double> _shieldAnimation;

  @override
  void initState() {
    super.initState();
    _shieldController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _shieldAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _shieldController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Confidentialité & Données'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: userAsync.when(
          data: (user) {
            if (user == null) return const SizedBox();
            return _buildContent(context, user);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Erreur: $e')),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserProfile user) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
      children: [
        // LE "PLUS" : Le Bouclier de Confidentialité Animé
        _buildPrivacyShield(user),
        const SizedBox(height: 32),

        _buildSectionTitle("Visibilité & Présence"),
        _buildGhostModeTile(user),
        const SizedBox(height: 16),

        _buildSectionTitle("Gestion des Données"),
        _buildDataTile(
          icon: Icons.security,
          title: "Permissions Système",
          subtitle: "Gérer les accès (Caméra, Location...)",
          onTap: () => openAppSettings(),
        ),
        _buildDataTile(
          icon: Icons.cleaning_services,
          title: "Vider le cache",
          subtitle: "Libérer de la mémoire sur votre téléphone",
          onTap: () => _clearCache(context),
        ),
        _buildDataTile(
          icon: Icons.download,
          title: "Télécharger mes données",
          subtitle: "Obtenir une copie de vos informations",
          onTap: () => _requestDataExport(context, user),
        ),
        const SizedBox(height: 32),

        _buildSectionTitle("Zone de Danger"),
        Container(
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              "Supprimer mon compte",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              "Cette action est irréversible",
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
            onTap: () => _confirmDeleteAccount(context),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyShield(UserProfile user) {
    final bool isSecure = user.isGhostMode;
    final Color statusColor = isSecure ? Colors.greenAccent : Colors.amber;
    final String statusText = isSecure
        ? "Protection Maximale"
        : "Protection Standard";

    return Center(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _shieldAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isSecure ? _shieldAnimation.value : 1.0,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: GlassmorphicContainer(
                    width: 120,
                    height: 120,
                    borderRadius: 60,
                    blur: 20,
                    alignment: Alignment.center,
                    border: 2,
                    linearGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        statusColor.withValues(alpha: 0.1),
                        statusColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        statusColor.withValues(alpha: 0.5),
                        statusColor.withValues(alpha: 0.1),
                      ],
                    ),
                    child: Icon(
                      isSecure ? Icons.shield : Icons.shield_outlined,
                      size: 60,
                      color: statusColor,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            statusText.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Votre confidentialité est notre priorité.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGhostModeTile(UserProfile user) {
    return Column(
      children: [
        _buildSwitchTile(
          icon: Icons.visibility_off,
          title: "Mode Fantôme",
          subtitle: "Devenir invisible sur la carte et pour les autres",
          value: user.isGhostMode,
          activeColor: Colors.purpleAccent,
          onChanged: (val) =>
              _updatePrivacySetting(context, user, 'isGhostMode', val),
        ),
        _buildSwitchTile(
          icon: Icons.blur_on,
          title: "Mode Discret",
          subtitle: "Localisation approximative (Zone 500m)",
          value: user.isDiscretMode,
          activeColor: Colors.blueAccent,
          onChanged: (val) =>
              _updatePrivacySetting(context, user, 'isDiscretMode', val),
        ),
        _buildSwitchTile(
          icon: Icons.do_not_disturb_on,
          title: "Ne Pas Déranger",
          subtitle: "Masquer mon statut en ligne",
          value: user.isDndMode,
          activeColor: Colors.redAccent,
          onChanged: (val) =>
              _updatePrivacySetting(context, user, 'isDndMode', val),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? activeColor.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: value ? activeColor : Colors.white70),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        value: value,
        activeThumbColor: activeColor,
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _updatePrivacySetting(
    BuildContext context,
    UserProfile user,
    String field,
    bool value,
  ) async {
    UserProfile updatedUser;
    String message;
    Color color;

    switch (field) {
      case 'isGhostMode':
        updatedUser = user.copyWith(isGhostMode: value);
        message = value ? 'Mode Fantôme activé 👻' : 'Mode Fantôme désactivé';
        color = Colors.purple;
        break;
      case 'isDiscretMode':
        updatedUser = user.copyWith(isDiscretMode: value);
        message = value ? 'Mode Discret activé 🌫️' : 'Mode Discret désactivé';
        color = Colors.blue;
        break;
      case 'isDndMode':
        updatedUser = user.copyWith(isDndMode: value);
        message = value
            ? 'Ne Pas Déranger activé 🌙'
            : 'Ne Pas Déranger désactivé';
        color = Colors.red;
        break;
      default:
        return;
    }

    await ref.read(authServiceProvider).updateUserProfile(updatedUser);

    if (mounted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: value ? color : Colors.grey,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Widget _buildDataTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white24,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
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

  void _clearCache(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Clear Image Cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    Future.delayed(const Duration(seconds: 1), () {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache mémoire vidé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _requestDataExport(BuildContext context, UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundLight,
        title: const Text(
          'Export des données',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Voulez-vous générer et partager une copie de vos données personnelles (format JSON) ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateAndShareData(user);
            },
            child: const Text('Générer & Partager'),
          ),
        ],
      ),
    );
  }

  void _generateAndShareData(UserProfile user) {
    try {
      final Map<String, dynamic> data = user.toJson();
      final StringBuffer buffer = StringBuffer();
      buffer.writeln("--- DONNÉES UTILISATEUR MUNOKOLIVE ---");
      buffer.writeln("Date: ${DateTime.now().toIso8601String()}");
      buffer.writeln("-------------------------------------");

      data.forEach((key, value) {
        String stringValue = value.toString();
        if (value is Timestamp) {
          stringValue = value.toDate().toIso8601String();
        }
        buffer.writeln("$key: $stringValue");
      });

      SharePlus.instance.share(
        ShareParams(text: buffer.toString(), subject: 'Mes Données MunokoLive'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur lors de l\'export: $e')));
      }
    }
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundLight,
        title: const Text(
          'Supprimer le compte ?',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Attention : Cette action supprimera définitivement toutes vos données, vos lieux et votre historique. Êtes-vous sûr ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                Navigator.pop(context); // Close dialog first

                // Show loading
                if (context.mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (c) =>
                        const Center(child: CircularProgressIndicator()),
                  );
                }

                // Delete user from Firebase Auth
                await ref.read(authServiceProvider).currentUser?.delete();
                // If successful, sign out locally to clean up state
                await ref.read(authServiceProvider).signOut();

                if (context.mounted) {
                  // Pop loading
                  Navigator.pop(context);
                  // Go to root/login
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                if (context.mounted) {
                  // Pop loading if it's there?
                  // Actually if delete fails, we might still be in loading dialog.
                  // Safe to pop once more if we are sure.
                  // But to be safe, let's just use simple logic without extra loading dialog complexity if possible,
                  // or manage it carefully.
                  Navigator.pop(context); // Pop loading

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Erreur: Connexion récente requise. Déconnectez-vous et réessayez.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Supprimer Définitivement'),
          ),
        ],
      ),
    );
  }
}
