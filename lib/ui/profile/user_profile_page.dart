import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:munokolive_music/models/user_profile.dart';
import 'package:munokolive_music/services/auth_service.dart';
import 'package:munokolive_music/services/image_upload_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:munokolive_music/models/place_model.dart';
import 'package:munokolive_music/services/place_service.dart';
import 'package:munokolive_music/ui/places/place_details_page.dart';
import 'package:munokolive_music/ui/settings/settings_page.dart';
import '../theme/app_theme.dart';

import 'package:munokolive_music/providers/user_provider.dart';

final myPlacesProvider = StreamProvider.family<List<PlaceModel>, String>((
  ref,
  userId,
) {
  return ref.watch(placeServiceProvider).getMyPlaces(userId);
});

class UserProfilePage extends ConsumerStatefulWidget {
  final String? userId;
  final bool startEditing; // New parameter to trigger edit mode immediately

  const UserProfilePage({super.key, this.userId, this.startEditing = false});

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isInit = true; // To track initial load

  // Controllers
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _communeCtrl;
  late TextEditingController _neighborhoodCtrl;

  // State variables
  File? _newImageFile;
  String? _availabilityStatus;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.startEditing; // Initialize from widget param
    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _whatsappCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _communeCtrl = TextEditingController();
    _neighborhoodCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _cityCtrl.dispose();
    _communeCtrl.dispose();
    _neighborhoodCtrl.dispose();
    super.dispose();
  }

  void _initControllers(UserProfile user) {
    // Initialize if it's the first load OR if we are not editing (to sync with updates)
    // We also want to ensure we don't overwrite user's typing if they are editing,
    // unless it's the very first time we enter edit mode (handled by _isInit).
    if (_isInit || !_isEditing) {
      _firstNameCtrl.text = user.firstName;
      _lastNameCtrl.text = user.lastName;
      _phoneCtrl.text = user.phone ?? '';
      _whatsappCtrl.text = user.whatsappNumber ?? '';
      _cityCtrl.text = user.city ?? '';
      _communeCtrl.text = user.commune ?? '';
      _neighborhoodCtrl.text = user.neighborhood ?? '';
      _availabilityStatus = user.availabilityStatus;

      if (_isInit) {
        _isInit = false;
      }
    } else if (_isEditing &&
        _firstNameCtrl.text.isEmpty &&
        user.firstName.isNotEmpty) {
      // Safety fallback: if editing but controllers are empty (e.g. missed sync), populate them
      _firstNameCtrl.text = user.firstName;
      _lastNameCtrl.text = user.lastName;
      _phoneCtrl.text = user.phone ?? '';
      _whatsappCtrl.text = user.whatsappNumber ?? '';
      _cityCtrl.text = user.city ?? '';
      _communeCtrl.text = user.commune ?? '';
      _neighborhoodCtrl.text = user.neighborhood ?? '';
      _availabilityStatus = user.availabilityStatus;
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Compress to avoid huge files
      maxWidth: 1024, // Resize for profile optimization
    );

    if (image != null) {
      setState(() {
        _newImageFile = File(image.path);
      });
    }
  }

  Future<void> _saveProfile(UserProfile currentUser) async {
    setState(() => _isLoading = true);

    try {
      String? photoUrl = currentUser.photoUrl;
      bool imageUploadFailed = false;

      if (_newImageFile != null) {
        try {
          photoUrl = await ref
              .read(imageUploadServiceProvider)
              .uploadProfileImage(currentUser.uid, _newImageFile!);
        } catch (e) {
          // Consider using a logging framework like 'dart:developer' or a third-party package
          // For example:
          // import 'dart:developer';
          // log('Error uploading image: $e', name: 'UserProfilePage');
          // Or use a package like 'logger' or 'logging' for more control
          imageUploadFailed = true;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Erreur upload photo (vérifiez votre connexion). Les autres infos seront sauvegardées.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      }

      final updatedProfile = currentUser.copyWith(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        whatsappNumber: _whatsappCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        commune: _communeCtrl.text.trim(),
        neighborhood: _neighborhoodCtrl.text.trim(),
        availabilityStatus: _availabilityStatus,
        photoUrl: photoUrl,
      );

      await ref.read(authServiceProvider).updateUserProfile(updatedProfile);

      setState(() {
        _isEditing = false;
        _newImageFile = null;
      });

      if (mounted && !imageUploadFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _launchWhatsApp(String? number) async {
    if (number == null || number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun numéro WhatsApp renseigné')),
      );
      return;
    }
    // Clean number
    final cleanNumber = number.replaceAll(RegExp(r'\D'), '');
    final url = Uri.parse(
      "https://wa.me/$cleanNumber?text=Bonjour, je vous contacte via MunokoLive pour une prestation...",
    );

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture de WhatsApp: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine which provider to use based on whether userId is passed
    final userAsync = widget.userId != null
        ? ref.watch(userProfileByIdProvider(widget.userId!))
        : ref.watch(currentUserProfileProvider);

    // Check if the current user is viewing their own profile
    final currentUser = ref.watch(authServiceProvider).currentUser;
    final isOwnProfile =
        widget.userId == null ||
        (currentUser != null && widget.userId == currentUser.uid);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(isOwnProfile ? 'Mon Profil' : 'Profil Utilisateur'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        ),
        actions: [
          if (isOwnProfile && !_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              tooltip: 'Paramètres',
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
              onPressed: () => setState(() => _isEditing = true),
            ),
          ] else if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => setState(() {
                _isEditing = false;
                _newImageFile = null;
                // Reset will happen in build via _initControllers if we force rebuild or manage state carefully.
                // Actually _initControllers is called in build, so just triggering rebuild is enough?
                // No, we need to reset controllers.
                // For simplicity, we just set state and let build re-init.
              }),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: userAsync.when(
          data: (user) {
            if (user == null) {
              return const Center(child: Text('Utilisateur non trouvé'));
            }
            _initControllers(user);

            final bool isPasteur =
                user.category == 'Homme de Dieu' || user.category == 'Pasteur';

            return SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 100,
                left: 24,
                right: 24,
                bottom: 24,
              ),
              child: Column(
                children: [
                  // Header Profile
                  _buildProfileHeader(user),
                  const SizedBox(height: 32),

                  // Availability Status
                  _buildAvailabilitySection(user, isPasteur),
                  const SizedBox(height: 32),

                  // Mes Lieux (Ecosystem Integration)
                  _buildMyPlacesSection(user),
                  const SizedBox(height: 32),

                  // Read-Only Info
                  _buildSectionTitle("Informations Personnelles"),

                  if (isOwnProfile && _isEditing) ...[
                    _buildInfoField(
                      'Prénom',
                      user.firstName,
                      isEditable: true,
                      controller: _firstNameCtrl,
                      icon: Icons.person_outline,
                    ),
                    _buildInfoField(
                      'Nom',
                      user.lastName,
                      isEditable: true,
                      controller: _lastNameCtrl,
                      icon: Icons.person,
                    ),
                  ] else
                    _buildInfoField(
                      'Nom Complet',
                      '${user.firstName} ${user.lastName}',
                      isEditable: false,
                      icon: Icons.person,
                    ),

                  // Hide private info for other users unless friends/admin?
                  // For now, only show email/dob if it's own profile
                  if (isOwnProfile) ...[
                    _buildInfoField(
                      'Email',
                      user.email ?? 'Non renseigné',
                      isEditable: false,
                    ),
                    _buildInfoField(
                      'Date de naissance',
                      user.dateOfBirth != null
                          ? '${user.dateOfBirth!.day}/${user.dateOfBirth!.month}/${user.dateOfBirth!.year}'
                          : 'Non renseigné',
                      isEditable: false,
                    ),
                  ],
                  if (user.sponsorName != null)
                    _buildInfoField(
                      'Parrain',
                      user.sponsorName!,
                      isEditable: false,
                    ),

                  const SizedBox(height: 24),

                  // Editable Info
                  _buildSectionTitle("Coordonnées & Localisation"),
                  _buildInfoField(
                    'Téléphone',
                    user.phone ?? '',
                    isEditable: isOwnProfile && _isEditing,
                    controller: _phoneCtrl,
                    icon: Icons.phone,
                  ),
                  _buildInfoField(
                    'WhatsApp',
                    user.whatsappNumber ?? '',
                    isEditable: isOwnProfile && _isEditing,
                    controller: _whatsappCtrl,
                    icon: Icons.chat,
                  ),
                  _buildInfoField(
                    'Ville',
                    user.city ?? '',
                    isEditable: isOwnProfile && _isEditing,
                    controller: _cityCtrl,
                    icon: Icons.location_city,
                  ),
                  _buildInfoField(
                    'Commune',
                    user.commune ?? '',
                    isEditable: isOwnProfile && _isEditing,
                    controller: _communeCtrl,
                    icon: Icons.map,
                  ),
                  _buildInfoField(
                    'Quartier',
                    user.neighborhood ?? '',
                    isEditable: isOwnProfile && _isEditing,
                    controller: _neighborhoodCtrl,
                    icon: Icons.home,
                  ),

                  const SizedBox(height: 32),

                  // Actions
                  if (isOwnProfile && _isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _saveProfile(user),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('ENREGISTRER LES MODIFICATIONS'),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _launchWhatsApp(user.whatsappNumber),
                        icon: const Icon(Icons.chat),
                        label: const Text('Contacter via WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),
                  if (isOwnProfile && !_isEditing)
                    TextButton.icon(
                      onPressed: () async {
                        await ref.read(authServiceProvider).signOut();
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Se déconnecter',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () {
            return const Center(child: CircularProgressIndicator());
          },
          error: (e, s) => Center(child: Text('Erreur: $e')),
        ),
      ),
    );
  }

  Widget _buildMyPlacesSection(UserProfile user) {
    final myPlacesAsync = ref.watch(myPlacesProvider(user.uid));

    return myPlacesAsync.when(
      data: (places) {
        if (places.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Mes Lieux (Espaces Gérés)"),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final place = places[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaceDetailsPage(place: place),
                        ),
                      );
                    },
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        image: place.images.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(place.images.first),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withValues(alpha: 0.4),
                                  BlendMode.darken,
                                ),
                              )
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              place.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                if (place.isVerified)
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.blueAccent,
                                    size: 14,
                                  ),
                                if (place.isVerified) const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    place.categoryLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildProfileHeader(UserProfile user) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                image: DecorationImage(
                  image: _newImageFile != null
                      ? FileImage(_newImageFile!)
                      : (user.photoUrl != null
                                ? NetworkImage(user.photoUrl!)
                                : const AssetImage(
                                    'assets/images/default_avatar.png',
                                  ))
                            as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black45, blurRadius: 5),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '${user.firstName} ${user.lastName}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        // Role & Category Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, Colors.purple],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '${user.category}${user.subCategory != null ? " • ${user.subCategory}" : ""}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Stats Card (Points, Stars, Church)
        GlassmorphicContainer(
          width: double.infinity,
          height: 100,
          borderRadius: 20,
          blur: 10,
          alignment: Alignment.center,
          border: 2,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
            ],
            stops: const [0.1, 1],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.5),
              Colors.white.withValues(alpha: 0.1),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                user.points.toString(),
                "Points",
                Icons.stars_rounded,
                Colors.amber,
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStatItem(
                (user.points ~/ 100).toString(), // Example logic for stars
                "Étoiles",
                Icons.star,
                Colors.orangeAccent,
              ),
              if (user.churchName != null) ...[
                Container(width: 1, height: 40, color: Colors.white24),
                _buildStatItem(
                  "Église",
                  user.churchName!,
                  Icons.church,
                  Colors.blueAccent,
                  isLabel: true,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Instruments
        if (user.instruments != null && user.instruments!.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: user.instruments!
                .map(
                  (inst) => Chip(
                    label: Text(inst),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(color: Colors.white70),
                    avatar: const Icon(
                      Icons.music_note,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    side: BorderSide.none,
                  ),
                )
                .toList(),
          ),

        const SizedBox(height: 8),
        if (user.createdAt != null)
          Text(
            'Membre depuis ${user.createdAt!.year}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon,
    Color color, {
    bool isLabel = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          isLabel && value.length > 10 ? "${value.substring(0, 8)}..." : value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection(UserProfile user, bool isPasteur) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statut Actuel',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_isEditing)
          Row(
            children: [
              Expanded(
                child: _buildStatusButton(
                  label: isPasteur ? 'Pas besoin' : 'Disponible',
                  color: Colors.green,
                  isSelected:
                      _availabilityStatus == 'available' ||
                      _availabilityStatus == 'no_need_help',
                  onTap: () => setState(
                    () => _availabilityStatus = isPasteur
                        ? 'no_need_help'
                        : 'available',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusButton(
                  label: isPasteur ? 'Dans le besoin' : 'Indisponible',
                  color: Colors.red,
                  isSelected:
                      _availabilityStatus == 'unavailable' ||
                      _availabilityStatus == 'need_help',
                  onTap: () => setState(
                    () => _availabilityStatus = isPasteur
                        ? 'need_help'
                        : 'unavailable',
                  ),
                ),
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(
                user.availabilityStatus,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(user.availabilityStatus),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  user.availabilityStatus == 'available' ||
                          user.availabilityStatus == 'no_need_help'
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: _getStatusColor(user.availabilityStatus),
                ),
                const SizedBox(width: 12),
                Text(
                  _getStatusLabel(user.availabilityStatus, isPasteur),
                  style: TextStyle(
                    color: _getStatusColor(user.availabilityStatus),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.secondaryColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    String value, {
    bool isEditable = false,
    TextEditingController? controller,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 6),
          if (isEditable)
            TextFormField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: icon != null
                    ? Icon(icon, color: AppTheme.textSecondary, size: 20)
                    : null,
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                value.isEmpty ? 'Non renseigné' : value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == 'available' || status == 'no_need_help') return Colors.green;
    return Colors.red;
  }

  String _getStatusLabel(String? status, bool isPasteur) {
    if (status == 'available') return 'Disponible';
    if (status == 'unavailable') return 'Pas disponible';
    if (status == 'need_help') return 'Dans le besoin';
    if (status == 'no_need_help') return 'Pas besoin';
    return 'Non défini';
  }
}
