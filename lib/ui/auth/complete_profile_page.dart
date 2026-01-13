import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/image_upload_service.dart';
import '../navigation/main_screen.dart';
import 'pending_approval_page.dart';
import '../theme/app_theme.dart';

// Provider simple pour le service d'upload
final imageUploadServiceProvider = Provider((ref) => ImageUploadService());

class CompleteProfilePage extends ConsumerStatefulWidget {
  final User user;
  const CompleteProfilePage({super.key, required this.user});

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Animation Controllers
  late AnimationController _backgroundController;
  late AnimationController _fadeController;

  // Controllers
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _neighborhoodCtrl;
  late TextEditingController _communeCtrl;
  late TextEditingController _churchNameCtrl;
  late TextEditingController _whatsappCtrl;

  // State
  String? _selectedCategory;
  String? _selectedSubCategory;
  DateTime _dob = DateTime(2000, 1, 1);
  File? _imageFile;
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;

  // Sponsor
  UserProfile? _selectedSponsor;

  // Data Lists
  final List<String> _musicienRoles = [
    'Pianiste',
    'Batteur',
    'Chantre',
    'Artiste',
    'Saxophoniste',
    'Bassiste',
    'Guitariste',
    'Choriste',
    'Chef de chœur',
  ];

  final List<String> _hommeDeDieuRoles = [
    'Pasteur',
    'Prophète',
    'Apôtre',
    'Évangéliste',
    'Ministère',
    'Évêque',
    'Docteur de la foi',
  ];

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController(text: widget.user.phoneNumber);
    _cityCtrl = TextEditingController();
    _neighborhoodCtrl = TextEditingController();
    _communeCtrl = TextEditingController();
    _churchNameCtrl = TextEditingController();
    _whatsappCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _communeCtrl.dispose();
    _churchNameCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permission de localisation refusée';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Permission de localisation refusée définitivement';
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Position récupérée avec succès!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de localisation: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
        ),
      );
      return;
    }

    if (_imageFile == null && widget.user.photoURL == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter une photo de profil')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? photoUrl = widget.user.photoURL;

      // Upload image if selected
      if (_imageFile != null) {
        try {
          photoUrl = await ref
              .read(imageUploadServiceProvider)
              .uploadProfileImage(widget.user.uid, _imageFile!);
        } catch (e) {
          debugPrint('Erreur upload image: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Attention: Impossible de télécharger la photo ($e). Le profil sera enregistré sans photo.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          // On continue sans la nouvelle photo (garde l'ancienne ou null)
        }
      }

      // Check for admin email or existing status
      String status = 'pending';
      if (widget.user.email == 'munokolive@gmail.com') {
        status = 'validated_admin'; // Force validated_admin for super admin
      } else {
        // Preserve existing status if valid
        final currentProfile = await ref
            .read(authServiceProvider)
            .getUserProfile(widget.user.uid);
        if (currentProfile != null &&
            (currentProfile.status == 'active' ||
                currentProfile.status == 'admin' ||
                currentProfile.status == 'validated_admin')) {
          status = currentProfile.status;
        }
      }

      final profile = UserProfile(
        uid: widget.user.uid,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: widget.user.email,
        dateOfBirth: _dob,
        category: _selectedCategory ?? 'Membre',
        subCategory: _selectedSubCategory,
        phone: _phoneCtrl.text.trim(),
        whatsappNumber: _whatsappCtrl.text.trim().isNotEmpty
            ? _whatsappCtrl.text.trim()
            : null,
        city: _cityCtrl.text.trim(),
        neighborhood: _neighborhoodCtrl.text.trim(),
        commune: _communeCtrl.text.trim(),
        churchName: _churchNameCtrl.text.trim(),
        availabilityStatus: 'available', // Default
        latitude: _latitude,
        longitude: _longitude,
        sponsorId: _selectedSponsor?.uid,
        sponsorName: _selectedSponsor != null
            ? '${_selectedSponsor!.firstName} ${_selectedSponsor!.lastName}'
            : null,
        status: status,
        photoUrl: photoUrl,
        createdAt: DateTime.now(), // Seniority timestamp
      );

      // Update profile
      await ref.read(authServiceProvider).updateUserProfile(profile);

      if (!mounted) return;

      // Navigate based on status
      if (status == 'active' ||
          status == 'admin' ||
          status == 'validated_admin') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PendingApprovalPage()),
          (route) => false,
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

  void _nextStep() {
    if (_currentStep == 0 && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
      );
      return;
    }
    if (_currentStep == 1 && _selectedSubCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner votre rôle')),
      );
      return;
    }
    setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textSecondary),
      prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppTheme.inputBorder.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.inputBorderActive),
      ),
      filled: true,
      fillColor: AppTheme.backgroundDark.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profil MunokoLive'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.backgroundGradientStart,
                      AppTheme.backgroundDark,
                      AppTheme.backgroundGradientStart.withValues(
                        alpha: 0.5 + 0.5 * _backgroundController.value,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Floating Orbs (Subtle)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  )
                : Column(
                    children: [
                      // Progress Indicator
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (_currentStep + 1) / 4,
                                backgroundColor: AppTheme.textPrimary
                                    .withValues(alpha: 0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor,
                                ),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Étape ${_currentStep + 1} sur 4',
                              style: TextStyle(
                                color: AppTheme.textSecondary.withValues(
                                  alpha: 0.8,
                                ),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: FadeTransition(
                                  opacity: _fadeController,
                                  child: Form(
                                    key: _formKey,
                                    child: _buildStepContent(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Navigation Buttons
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            if (_currentStep > 0)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _prevStep,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.textPrimary,
                                    side: BorderSide(
                                      color: AppTheme.textPrimary.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text('Retour'),
                                ),
                              ),
                            if (_currentStep > 0) const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AppTheme.buttonGradient,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _currentStep == 3
                                      ? _saveProfile
                                      : _nextStep,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    _currentStep == 3 ? 'TERMINER' : 'SUIVANT',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 1,
                                    ),
                                  ),
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
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildCategoryStep();
      case 1:
        return _buildSubCategoryStep();
      case 2:
        return _buildPersonalInfoStep();
      case 3:
        return _buildFinalStep();
      default:
        return Container();
    }
  }

  Widget _buildCategoryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Qui êtes-vous ?",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Sélectionnez votre catégorie principale pour continuer.",
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 32),
        _buildCategoryCard(
          title: "Musicien",
          icon: Icons.music_note,
          isSelected: _selectedCategory == 'Musicien',
          onTap: () => setState(() => _selectedCategory = 'Musicien'),
        ),
        const SizedBox(height: 16),
        _buildCategoryCard(
          title: "Homme de Dieu",
          icon: Icons.church,
          isSelected: _selectedCategory == 'Homme de Dieu',
          onTap: () => setState(() => _selectedCategory = 'Homme de Dieu'),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.2)
              : AppTheme.backgroundLight.withValues(alpha: 0.1),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.white.withValues(alpha: 0.1),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCategoryStep() {
    final List<String> roles = _selectedCategory == 'Musicien'
        ? _musicienRoles
        : _hommeDeDieuRoles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quel est votre rôle ?",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Sélectionnez votre spécialité en tant que $_selectedCategory.",
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: roles.map((role) {
            final isSelected = _selectedSubCategory == role;
            return ChoiceChip(
              label: Text(role),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedSubCategory = selected ? role : null);
              },
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.textPrimary : AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: AppTheme.backgroundLight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.secondaryColor.withValues(alpha: 0.5),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Informations Personnelles",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstNameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration(
                  'Prénom',
                  Icons.person_outline,
                ),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _lastNameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration('Nom', Icons.person),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _dob,
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: AppTheme.darkTheme.copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppTheme.primaryColor,
                      onPrimary: Colors.white,
                      surface: AppTheme.backgroundLight,
                      onSurface: AppTheme.textPrimary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (d != null) setState(() => _dob = d);
          },
          child: InputDecorator(
            decoration: _buildInputDecoration(
              'Date de naissance',
              Icons.calendar_today,
            ),
            child: Text(
              '${_dob.day}/${_dob.month}/${_dob.year}',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cityCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Ville', Icons.location_city),
          validator: (v) => v!.isEmpty ? 'Requis' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _communeCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Commune', Icons.map),
          validator: (v) => v!.isEmpty ? 'Requis' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _neighborhoodCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Quartier', Icons.home_work),
          validator: (v) => v!.isEmpty ? 'Requis' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _churchNameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration("Nom de l'église", Icons.church),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.inputBorder.withValues(alpha: 0.3),
            ),
          ),
          child: TextButton.icon(
            onPressed: _isGettingLocation ? null : _getCurrentLocation,
            icon: _isGettingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : const Icon(Icons.my_location),
            label: Text(
              _latitude != null
                  ? 'Position actuelle acquise'
                  : 'Utiliser ma position actuelle',
              style: TextStyle(
                color: _latitude != null ? Colors.green : AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Derniers détails",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.backgroundLight,
              backgroundImage: _imageFile != null
                  ? FileImage(_imageFile!)
                  : (widget.user.photoURL != null
                            ? NetworkImage(widget.user.photoURL!)
                            : null)
                        as ImageProvider?,
              child: (_imageFile == null && widget.user.photoURL == null)
                  ? const Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: AppTheme.textSecondary,
                    )
                  : null,
            ),
          ),
        ),
        const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Photo de profil',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _phoneCtrl,
          decoration: const InputDecoration(
            labelText: 'Téléphone (Appels)',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (v) => v!.isEmpty ? 'Requis' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _whatsappCtrl,
          decoration: const InputDecoration(
            labelText: 'Numéro WhatsApp (Optionnel)',
            prefixIcon: Icon(Icons.chat),
            helperText: "Pour recevoir des demandes directes",
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        const Text(
          "Parrainage (Qui vous a invité ?)",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return Autocomplete<UserProfile>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.length < 2) {
                  return const Iterable<UserProfile>.empty();
                }
                return await ref
                    .read(authServiceProvider)
                    .searchUsers(textEditingValue.text);
              },
              displayStringForOption: (UserProfile option) =>
                  '${option.firstName} ${option.lastName}',
              onSelected: (UserProfile selection) {
                setState(() => _selectedSponsor = selection);
              },
              fieldViewBuilder:
                  (
                    context,
                    textEditingController,
                    focusNode,
                    onFieldSubmitted,
                  ) {
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      style: const TextStyle(color: Colors.white),
                      decoration:
                          _buildInputDecoration(
                            'Rechercher un parrain',
                            Icons.person_search,
                          ).copyWith(
                            suffixIcon: _selectedSponsor != null
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: AppTheme.textSecondary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _selectedSponsor = null;
                                      });
                                      textEditingController.clear();
                                    },
                                  )
                                : null,
                          ),
                      onFieldSubmitted: (String value) {
                        onFieldSubmitted();
                      },
                    );
                  },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    color: AppTheme.backgroundDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppTheme.inputBorder.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Container(
                      width: constraints.maxWidth,
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final UserProfile option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${option.firstName} ${option.lastName}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    option.category,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
