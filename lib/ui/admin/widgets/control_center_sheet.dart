import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../services/admin_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/image_upload_service.dart';
import '../../../models/user_profile.dart';

class ControlCenterSheet extends ConsumerStatefulWidget {
  const ControlCenterSheet({super.key});

  @override
  ConsumerState<ControlCenterSheet> createState() => _ControlCenterSheetState();
}

class _ControlCenterSheetState extends ConsumerState<ControlCenterSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _discretMode = false;
  bool _dndMode = false;
  bool _loadingBar = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isAdmin(UserProfile user) {
    if (user.email == 'munokolive@gmail.com') return true;
    final adminKeywords = ['Admin', 'Pasteur', 'Leader', 'Staff'];
    return adminKeywords.any((k) => user.category.contains(k)) ||
        user.status == 'validated_admin' ||
        user.status == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Builder(
        builder: (context) {
          // Extraction sûre des données ou utilisation d'un profil par défaut
          final user = userAsync.valueOrNull;

          // Si chargement ou erreur, on affiche quand même l'interface en mode "Invité"
          // pour ne pas bloquer l'accès aux paramètres
          final safeUser =
              user ??
              UserProfile(
                uid: 'guest',
                firstName: 'Invité',
                lastName: '',
                email: '',
                dateOfBirth: DateTime.now(),
                category: 'Visiteur',
                status: 'guest',
                phone: '',
                photoUrl: null,
              );

          final isAdmin = _isAdmin(safeUser);

          return Stack(
            children: [
              // Backdrop
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(color: Colors.black54),
              ),
              // Content
              GlassmorphicContainer(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 0,
                blur: 20,
                alignment: Alignment.center,
                border: 0,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2B124C).withValues(alpha: 0.95),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
                borderGradient: const LinearGradient(
                  colors: [Colors.white24, Colors.white10],
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 30),
                        if (userAsync.isLoading)
                          const Center(
                            child: LinearProgressIndicator(
                              color: Color(0xFFDF00FF),
                            ),
                          )
                        else
                          _buildProfileSection(safeUser, isAdmin),

                        const SizedBox(height: 30),
                        _buildGamificationSection(),
                        if (isAdmin) ...[
                          const SizedBox(height: 30),
                          _buildAdminSection(context),
                        ],
                        const SizedBox(height: 30),
                        _buildSecuritySection(),
                        const SizedBox(height: 30),
                        _buildDNDSection(),
                        const SizedBox(height: 40),
                        _buildFooter(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'CENTRE DE CONTRÔLE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildGamificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('GAMIFICATION', Colors.blueAccent),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(
            borderColor: Colors.blueAccent.withValues(alpha: 0.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBadge('Fidèle', Icons.favorite, Colors.redAccent),
              _buildBadge('Explorateur', Icons.explore, Colors.blueAccent),
              _buildBadge('Social', Icons.people, Colors.greenAccent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection(UserProfile user, bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('MON PROFIL NUMÉRIQUE', const Color(0xFFDF00FF)),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: user.photoUrl != null
                        ? CachedNetworkImageProvider(user.photoUrl!)
                        : null,
                    backgroundColor: const Color(0xFF800080),
                    child: user.photoUrl == null
                        ? Text(
                            user.firstName[0],
                            style: const TextStyle(
                              fontSize: 24,
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
                          user.category.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFDF00FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white70),
                    onPressed: () =>
                        _showEditProfileDialog(context, user, isAdmin),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSwitchRow(
                'Barre de chargement',
                'Afficher une légère barre pendant les attentes',
                Icons.incomplete_circle,
                _loadingBar,
                (v) => setState(() => _loadingBar = v),
              ),
              const SizedBox(height: 24),
              if (user.phone != null && user.phone!.isNotEmpty)
                _buildInfoRow(Icons.phone, user.phone!),
              if (user.city != null && user.city!.isNotEmpty)
                _buildInfoRow(Icons.location_on, user.city!),
              if (user.category.isNotEmpty)
                _buildInfoRow(Icons.category, user.category),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('PORTAIL ADMINISTRATIF', Colors.orangeAccent),
        Container(
          decoration: _cardDecoration(
            borderColor: Colors.orangeAccent.withValues(alpha: 0.3),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.orangeAccent,
                  ),
                ),
                title: const Text(
                  'Tableau de Bord Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Gestion utilisateurs, rôles, validations',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 16,
                ),
                onTap: () => _showValidationDialog(context),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield, color: Colors.amber),
                ),
                title: const Text(
                  'Désigner un Administrateur',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 16,
                ),
                onTap: () => _showAdminAssignmentDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'SÉCURITÉ & CONFIDENTIALITÉ',
          const Color(0xFFDF00FF),
        ),
        Container(
          decoration: _cardDecoration(),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: const Icon(Icons.lock_outline, color: Colors.white70),
                title: const Text(
                  'Changer mon mot de passe',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 16,
                ),
                onTap: () {},
              ),
              Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _buildSwitchRow(
                  'Mode Discret',
                  'Masquer ma position sur la carte',
                  Icons.visibility_off_outlined,
                  _discretMode,
                  (v) => setState(() => _discretMode = v),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDNDSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('NE PAS DÉRANGER', Colors.white70),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSwitchRow(
                'Ne pas déranger',
                'Couper les alertes locales dans une plage horaire',
                Icons.do_not_disturb_on_outlined,
                _dndMode,
                (v) => setState(() => _dndMode = v),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ce mode s\'active automatiquement pendant les cultes si vous êtes dans le périmètre.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_outlined, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Mentions Légales (CI)',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: () {
            ref.read(authServiceProvider).signOut();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          label: const Text(
            'Se déconnecter',
            style: TextStyle(color: Colors.redAccent, fontSize: 16),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Munokolive Music v1.0.0 (Bêta)',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged, {
    EdgeInsetsGeometry? padding,
  }) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFDF00FF),
            activeTrackColor: const Color(0xFFDF00FF).withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: const Color(0xFF150A25).withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.05),
        width: 1,
      ),
    );
  }

  void _showValidationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AdminValidationDialog(),
    );
  }

  void _showAdminAssignmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AdminAssignmentDialog(),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    UserProfile user,
    bool isAdmin,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => EditProfileDialog(user: user, isAdmin: isAdmin),
    );
  }
}

class AdminValidationDialog extends ConsumerWidget {
  const AdminValidationDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 500,
        borderRadius: 24,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2B124C).withValues(alpha: 0.95),
            Colors.black.withValues(alpha: 0.9),
          ],
        ),
        borderGradient: const LinearGradient(
          colors: [Colors.white24, Colors.white10],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Validation Comptes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: ref
                    .watch(adminServiceProvider)
                    .getPendingAdminRequests(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFDF00FF),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune demande en attente',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final profile = UserProfile.fromJson(data);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundImage: profile.photoUrl != null
                                ? NetworkImage(profile.photoUrl!)
                                : null,
                            child: profile.photoUrl == null
                                ? Text(profile.firstName[0])
                                : null,
                          ),
                          title: Text(
                            '${profile.firstName} ${profile.lastName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.category,
                                style: const TextStyle(
                                  color: Color(0xFFDF00FF),
                                  fontSize: 12,
                                ),
                              ),
                              if (data['email'] != null)
                                Text(
                                  data['email'] as String,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 32,
                                ),
                                onPressed: () {
                                  ref
                                      .read(adminServiceProvider)
                                      .validateAdmin(profile.uid);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.redAccent,
                                  size: 32,
                                ),
                                onPressed: () {
                                  ref
                                      .read(adminServiceProvider)
                                      .rejectUser(profile.uid);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminAssignmentDialog extends StatefulWidget {
  const AdminAssignmentDialog({super.key});

  @override
  State<AdminAssignmentDialog> createState() => _AdminAssignmentDialogState();
}

class _AdminAssignmentDialogState extends State<AdminAssignmentDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 600,
        borderRadius: 24,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2B124C).withValues(alpha: 0.95),
            Colors.black.withValues(alpha: 0.9),
          ],
        ),
        borderGradient: const LinearGradient(
          colors: [Colors.white24, Colors.white10],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Désigner Administrateur',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Rechercher un membre...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .limit(50)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFDF00FF),
                      ),
                    );
                  }

                  var docs = snapshot.data!.docs;
                  if (_searchQuery.isNotEmpty) {
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = '${data['firstName']} ${data['lastName']}'
                          .toLowerCase();
                      return name.contains(_searchQuery.toLowerCase());
                    }).toList();
                  }

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun utilisateur trouvé',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final profile = UserProfile.fromJson(data);
                      final isAdmin =
                          profile.status == 'admin' ||
                          profile.category.contains('Admin');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isAdmin
                                ? Colors.amber.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: profile.photoUrl != null
                                ? NetworkImage(profile.photoUrl!)
                                : null,
                            child: profile.photoUrl == null
                                ? Text(profile.firstName[0])
                                : null,
                          ),
                          title: Text(
                            '${profile.firstName} ${profile.lastName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            profile.category,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                          trailing: Switch(
                            value: isAdmin,
                            onChanged: (val) {
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(profile.uid)
                                  .update({
                                    'status': val ? 'admin' : 'member',
                                    'category': val ? 'Admin' : 'Membre',
                                  });
                            },
                            activeThumbColor: Colors.amber,
                            activeTrackColor: Colors.amber.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfileDialog extends StatefulWidget {
  final UserProfile user;
  final bool isAdmin;
  const EditProfileDialog({
    super.key,
    required this.user,
    required this.isAdmin,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _neighborhoodCtrl;
  late TextEditingController _sponsorshipCodeCtrl;
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.user.firstName);
    _lastNameCtrl = TextEditingController(text: widget.user.lastName);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _cityCtrl = TextEditingController(text: widget.user.city);
    _categoryCtrl = TextEditingController(text: widget.user.category);
    _neighborhoodCtrl = TextEditingController(text: widget.user.neighborhood);
    _sponsorshipCodeCtrl = TextEditingController(
      text: widget.user.sponsorshipCode,
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _categoryCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _sponsorshipCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      String? photoUrl = widget.user.photoUrl;

      // Upload image if changed
      if (_imageFile != null) {
        final uploadService = ImageUploadService();
        photoUrl = await uploadService.uploadProfileImage(
          widget.user.uid,
          _imageFile!,
        );
      }

      final firstName = _firstNameCtrl.text.trim();
      final lastName = _lastNameCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      final city = _cityCtrl.text.trim();
      final category = _categoryCtrl.text.trim();
      final neighborhood = _neighborhoodCtrl.text.trim();
      final sponsorshipCode = _sponsorshipCodeCtrl.text.trim();

      // Update User Profile
      final Map<String, dynamic> updateData = {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'city': city,
        'photoUrl': photoUrl,
        'neighborhood': neighborhood,
        'sponsorshipCode': sponsorshipCode,
      };

      if (widget.isAdmin) {
        updateData['category'] = category;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update(updateData);

      // Update Location Data (for Map sync)
      await FirebaseFirestore.instance
          .collection('locations')
          .doc(widget.user.uid)
          .set({
            'firstName': firstName,
            'lastName': lastName,
            'phone': phone,
            'photoUrl': photoUrl,
          }, SetOptions(merge: true));

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 600,
        borderRadius: 24,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2B124C).withValues(alpha: 0.95),
            Colors.black.withValues(alpha: 0.9),
          ],
        ),
        borderGradient: const LinearGradient(
          colors: [Colors.white24, Colors.white10],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Modifier mon profil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (widget.user.photoUrl != null
                                    ? CachedNetworkImageProvider(
                                        widget.user.photoUrl!,
                                      )
                                    : null)
                                as ImageProvider?,
                      backgroundColor: const Color(0xFF800080),
                      child:
                          (_imageFile == null && widget.user.photoUrl == null)
                          ? Text(
                              widget.user.firstName[0],
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDF00FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                'Prénom',
                _firstNameCtrl,
                Icons.person,
                readOnly: !widget.isAdmin,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Nom',
                _lastNameCtrl,
                Icons.person_outline,
                readOnly: !widget.isAdmin,
              ),
              const SizedBox(height: 16),
              _buildTextField('Téléphone', _phoneCtrl, Icons.phone),
              const SizedBox(height: 16),
              _buildTextField('Ville', _cityCtrl, Icons.location_city),
              const SizedBox(height: 16),
              _buildTextField('Quartier', _neighborhoodCtrl, Icons.home_work),
              const SizedBox(height: 16),
              _buildTextField(
                'Code Parrain',
                _sponsorshipCodeCtrl,
                Icons.card_membership,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Catégorie',
                _categoryCtrl,
                Icons.category,
                readOnly: !widget.isAdmin,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDF00FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Enregistrer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDF00FF)),
        ),
      ),
    );
  }
}
