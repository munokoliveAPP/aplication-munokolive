/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:munokolive_music/models/user_profile.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';
import 'package:munokolive_music/ui/widgets/cached_circle_avatar.dart';
import 'package:munokolive_music/ui/profile/referral_tree_page.dart';
import 'package:munokolive_music/ui/profile/edit_profile_page.dart';
import 'package:munokolive_music/ui/widgets/animated_counter.dart';

class ViewProfilePage extends ConsumerStatefulWidget {
  final String userId;

  const ViewProfilePage({super.key, required this.userId});

  @override
  ConsumerState<ViewProfilePage> createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends ConsumerState<ViewProfilePage> {
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    // No initial load needed, StreamBuilder will handle it
  }

  void _showOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text(
                'Signaler ce profil',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signalement envoyé')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.white),
              title: const Text(
                'Bloquer cet utilisateur',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Utilisateur bloqué')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isOwnProfile = currentUser != null && currentUser.id == widget.userId;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                if (_userProfile != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditProfilePage(user: _userProfile!),
                    ),
                  );
                }
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: _showOptionsModal,
            ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('users')
            .stream(primaryKey: ['id'])
            .eq('id', widget.userId)
            .limit(1),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          if (data.isEmpty) {
            return const Center(
              child: Text(
                'Profil non trouvé',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final userProfile = UserProfile.fromJson(data.first);
          _userProfile =
              userProfile; // Update local state for other widgets if needed

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                CachedCircleAvatar(imageUrl: userProfile.photoUrl, radius: 60),
                const SizedBox(height: 16),
                Text(
                  '${userProfile.firstName} ${userProfile.lastName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (userProfile.category.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    userProfile.category,
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  ),
                ],

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      AnimatedCounter(
                        value: userProfile.points,
                        suffix: ' pts',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // AVAILABILITY SWITCH (UBER GOSPEL FEATURE)
                _buildAvailabilitySwitch(),

                // REFERRAL TREE BUTTON
                _buildReferralTreeButton(),

                const SizedBox(height: 10),
                _buildInfoCard(
                  'Église',
                  (userProfile.churchName?.isNotEmpty ?? false)
                      ? userProfile.churchName!
                      : 'Non renseigné',
                  Icons.church,
                ),
                if ((userProfile.city?.isNotEmpty ?? false))
                  _buildInfoCard(
                    'Ville',
                    userProfile.city!,
                    Icons.location_city,
                  ),
                if ((userProfile.phoneNumber?.isNotEmpty ?? false))
                  _buildInfoCard(
                    'Téléphone',
                    userProfile.phoneNumber!,
                    Icons.phone,
                    onTap: () => _launchCall(userProfile.phoneNumber!),
                    isLink: true,
                  ),
                if ((userProfile.email?.isNotEmpty ?? false))
                  _buildInfoCard(
                    'Email',
                    userProfile.email!,
                    Icons.email,
                    onTap: () => _launchEmail(userProfile.email!),
                    isLink: true,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvailabilitySwitch() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.event_available, color: AppTheme.primaryColor),
              SizedBox(width: 16),
              Text(
                'Disponibilité',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
          Switch(
            value: _userProfile!.isAvailable,
            onChanged: null, // Read-only in View Mode
            activeThumbColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildReferralTreeButton() {
    // Only show for current user
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null ||
        _userProfile == null ||
        currentUser.id != _userProfile!.id) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReferralTreePage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          foregroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          elevation: 0,
        ),
        icon: const Icon(Icons.account_tree_rounded),
        label: const Text(
          "Mon Arbre de Parrainage",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon, {
    VoidCallback? onTap,
    bool isLink = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLink
                ? AppTheme.primaryColor.withValues(alpha: 0.5)
                : Colors.grey[800]!,
          ),
          boxShadow: isLink
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
            if (isLink)
              Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }
}
