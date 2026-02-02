/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:munokolive_music/models/user_profile.dart';
import 'package:munokolive_music/providers/user_provider.dart';
import 'package:munokolive_music/services/auth_service.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';
import 'package:munokolive_music/ui/widgets/cached_circle_avatar.dart';
import 'package:munokolive_music/ui/profile/referral_tree_page.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  final UserProfile user;
  const EditProfilePage({super.key, required this.user});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _churchController;
  late TextEditingController _countryController;
  late TextEditingController _cityController;
  late TextEditingController _communeController;
  late TextEditingController _neighborhoodController;

  File? _imageFile;
  bool _isLoading = false;
  String _loadingStatus = ''; // Added for progress feedback
  late bool _isAvailable;
  bool _isEditing = false; // Mode édition vs Mode lecture

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _churchController = TextEditingController(text: widget.user.churchName);
    _countryController = TextEditingController(text: widget.user.country);
    _cityController = TextEditingController(text: widget.user.city);
    _communeController = TextEditingController(text: widget.user.commune);
    _neighborhoodController = TextEditingController(
      text: widget.user.neighborhood,
    );
    _isAvailable = widget.user.isAvailable;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _churchController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _communeController.dispose();
    _neighborhoodController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Uniquement en mode édition
    if (!_isEditing) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _loadingStatus = 'Préparation...';
    });

    try {
      final auth = ref.read(authServiceProvider);
      String? photoUrl = widget.user.photoUrl;

      if (_imageFile != null) {
        setState(
          () => _loadingStatus =
              'Envoi de la photo (cela peut prendre un moment)...',
        );
        photoUrl = await auth.uploadProfileImage(widget.user.id, _imageFile!);
      }

      setState(() => _loadingStatus = 'Enregistrement des informations...');

      await auth.updateUserProfile(
        userId: widget.user.id,
        firstName: widget.user.firstName,
        lastName: widget.user.lastName,
        category: widget.user.category,
        subCategory: widget.user.subCategory,
        birthDate: widget.user.birthDate,
        // Updated Fields
        churchName: _churchController.text.trim(),
        photoUrl: photoUrl,
        phoneNumber: _phoneController.text.trim(),
        country: _countryController.text.trim(),
        city: _cityController.text.trim(),
        commune: _communeController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        isAvailable: _isAvailable,
      );

      setState(() => _loadingStatus = 'Terminé !');
      ref.invalidate(currentUserProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Retour automatique après sauvegarde
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
          _loadingStatus = '';
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Supprimer mon compte ?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Êtes-vous sûr de vouloir supprimer définitivement votre compte ? Cette action est irréversible et toutes vos données seront perdues.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "SUPPRIMER",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final auth = ref.read(authServiceProvider);
        await auth.deleteAccount(widget.user.id);

        if (mounted) {
          // Navigate to login or splash
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEditing ? 'Modifier mon profil' : 'Mon Profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Photo Section
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _imageFile != null
                          ? CircleAvatar(
                              radius: 60,
                              backgroundImage: FileImage(_imageFile!),
                            )
                          : CachedCircleAvatar(
                              imageUrl: widget.user.photoUrl,
                              radius: 60,
                            ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Availability Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isAvailable
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isAvailable ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isAvailable
                          ? Icons.check_circle
                          : Icons.do_not_disturb_on,
                      color: _isAvailable ? Colors.green : Colors.red,
                      size: 30,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isAvailable ? 'DISPONIBLE' : 'INDISPONIBLE',
                            style: TextStyle(
                              color: _isAvailable ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _isAvailable
                                ? 'Active pour avoir des offres et services.'
                                : 'Rendre masqué pour ne pas avoir des opportunités.',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isEditing)
                      Switch(
                        value: _isAvailable,
                        activeThumbColor: Colors.green,
                        inactiveTrackColor: Colors.red.withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.red,
                        onChanged: (val) => setState(() => _isAvailable = val),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Read-Only Fields (Identity)
              _buildSectionTitle('Identité & Parrainage'),
              _buildReadOnlyField(
                'Nom & Prénom',
                '${widget.user.firstName} ${widget.user.lastName}',
                Icons.person,
              ),
              _buildReadOnlyField(
                'Date de naissance',
                widget.user.birthDate != null
                    ? '${widget.user.birthDate!.day}/${widget.user.birthDate!.month}/${widget.user.birthDate!.year}'
                    : 'Non renseignée',
                Icons.cake,
              ),
              // Referral Code in same section
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Code Parrain",
                            style: TextStyle(color: Colors.amber, fontSize: 12),
                          ),
                          Text(
                            widget.user.referralCode ?? '...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.amber),
                      onPressed: () {
                        if (widget.user.referralCode != null) {
                          Clipboard.setData(
                            ClipboardData(text: widget.user.referralCode!),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copié !')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              // --- BOUTON ARBRE DE PARRAINAGE ---
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReferralTreePage(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.account_tree_rounded,
                    color: Colors.cyanAccent,
                  ),
                  label: const Text(
                    "VISUALISER MA GÉNÉALOGIE",
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.cyanAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // ----------------------------------
              const SizedBox(height: 10),

              // Editable Fields Grouped
              _buildSectionTitle('Informations Complémentaires'),

              // Church
              _buildEditableCard(
                label: 'Église / Paroisse',
                controller: _churchController,
                icon: Icons.church,
                placeholder: 'Ajouter votre église',
              ),

              // Phone
              _buildEditableCard(
                label: 'Téléphone',
                controller: _phoneController,
                icon: Icons.phone,
                placeholder: 'Ajouter un numéro',
                keyboardType: TextInputType.phone,
              ),

              // Location Group
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: AppTheme.secondaryColor),
                        SizedBox(width: 10),
                        Text(
                          "Localisation",
                          style: TextStyle(
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildLocationField(
                            'Pays',
                            _countryController,
                            Icons.public,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildLocationField(
                            'Ville',
                            _cityController,
                            Icons.location_city,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildLocationField(
                            'Commune',
                            _communeController,
                            Icons.map,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildLocationField(
                            'Quartier',
                            _neighborhoodController,
                            Icons.home_work,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              if (_isEditing)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _loadingStatus,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'ENREGISTRER LES MODIFICATIONS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

              const SizedBox(height: 40),

              // Delete Account Button (Zone de danger) - Visible uniquement pour le Super Admin
              if (widget.user.role == 'super_admin')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : _deleteAccount,
                    icon: const Icon(
                      Icons.delete_forever,
                      color: Colors.redAccent,
                    ),
                    label: const Text(
                      "Supprimer mon compte",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock, color: Colors.grey, size: 16),
        ],
      ),
    );
  }

  // Affiche soit le texte (Lecture) soit le champ (Edition)
  Widget _buildEditableCard({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
  }) {
    // Si mode lecture
    if (!_isEditing) {
      final value = controller.text.trim();
      final isEmpty = value.isEmpty;

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    isEmpty ? placeholder : value,
                    style: TextStyle(
                      color: isEmpty ? Colors.white30 : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Si mode édition
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    if (!_isEditing) {
      final value = controller.text.trim();
      final isEmpty = value.isEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isEmpty ? '---' : value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        filled: true,
        fillColor: Colors.black,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
    );
  }
}
