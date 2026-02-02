/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Add this import
import '../settings/privacy_policy_page.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';
import '../theme/app_theme.dart';

import '../../models/user_profile.dart'; // Add this import
import 'package:munokolive_music/l10n/app_localizations.dart';

class CompleteProfilePage extends ConsumerStatefulWidget {
  final User user;
  const CompleteProfilePage({super.key, required this.user});

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _churchController = TextEditingController();
  final _dateController = TextEditingController();
  final _referralController = TextEditingController();

  bool _isLoading = false;
  String _loadingStatus = ''; // Added for feedback
  bool _acceptedPrivacy = false;
  bool _hasReferrer = false;
  String _category = 'Chantre & Instrumentiste';
  String? _subCategory;
  File? _imageFile;
  DateTime? _selectedDate;

  final List<String> _musicienRoles = [
    'Pianiste',
    'Batteur',
    'Bassiste',
    'Guitariste',
    'Saxophoniste',
    'Percussionniste',
    'Violoniste',
    'Synthétiseur',
    'Trompettiste',
    'Flûtiste',
    'Chantre',
    'Maître de chœur',
    'Formateur Musique',
    'Ingénieur son',
    'Beatmaker',
  ];
  final List<String> _ministreRoles = [
    'Pasteur',
    'Prophète',
    'Diacre',
    'Évangéliste',
    'Docteur',
    'Apôtre',
  ];

  @override
  void initState() {
    super.initState();
    // Attempt to pre-fill form if profile data exists (even partially)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileState = ref.read(currentUserProfileProvider);
      if (profileState.hasValue && profileState.value != null) {
        _populateForm(profileState.value!);
      }
    });
  }

  void _populateForm(UserProfile profile) {
    setState(() {
      _firstNameController.text = profile.firstName;
      _lastNameController.text = profile.lastName;
      _churchController.text = profile.churchName ?? '';
      _category = profile.category.isNotEmpty ? profile.category : _category;
      _subCategory = profile.subCategory;
      _hasReferrer = profile.referredBy != null;
      if (profile.birthDate != null) {
        _selectedDate = profile.birthDate;
        _dateController.text = DateFormat(
          'dd/MM/yyyy',
        ).format(profile.birthDate!);
      }
      // Note: We don't pre-fill photo file from URL, but we could show the URL if we wanted.
      // For now, if they have a photoUrl, we assume they might want to keep it or change it.
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _churchController.dispose();
    _dateController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // Resize large images to reasonable width
      maxHeight: 800,
      imageQuality: 70, // Compress quality to reduce size
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 365 * 18),
      ), // ~18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceDark,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppTheme.backgroundDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.privacyPolicyAccept),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final profileState = ref.read(currentUserProfileProvider);
    final existingPhotoUrl = profileState.value?.photoUrl;

    if (_imageFile == null &&
        (existingPhotoUrl == null || existingPhotoUrl.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.photoRequired),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check file size if it's too big (even after compression, though unlikely)
    int fileSizeInBytes = await _imageFile!.length();
    double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

    if (fileSizeInMB > 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.optimizingPhoto),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Validate Referral Code if entered manually
    if (!_hasReferrer && _referralController.text.trim().isNotEmpty) {
      final code = _referralController.text.trim();
      final auth = ref.read(authServiceProvider);
      final referrerId = await auth.validateReferralCode(code);

      if (referrerId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.invalidReferralCode),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      // Note: We pass the code to updateUserProfile, which handles the logic.
      // Ideally we should pass the UUID if updateUserProfile supported it,
      // but currently it takes the code string for RPC.
      // We'll trust the validation here.
    }

    setState(() {
      _isLoading = true;
      _loadingStatus = AppLocalizations.of(context)!.statusPreparing;
    });

    // Timer to warn user if connection is slow
    Timer? slowConnectionTimer;
    slowConnectionTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isLoading) {
        setState(() {
          _loadingStatus = AppLocalizations.of(context)!.optimizingNetwork;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.slowConnectionMessage),
            duration: const Duration(seconds: 4),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    try {
      final auth = ref.read(authServiceProvider);
      String? photoUrl;

      // Upload Photo concurrently if possible, or just sequential for safety
      if (_imageFile != null) {
        setState(
          () => _loadingStatus = AppLocalizations.of(context)!.uploadingPhoto,
        );
        photoUrl = await auth.uploadProfileImage(widget.user.id, _imageFile!);
      }

      // If photo upload failed but we have a file, we might want to warn user,
      // but user asked to enter home directly.
      // We proceed even if photoUrl is null (upload failed or timed out).

      setState(
        () => _loadingStatus = AppLocalizations.of(context)!.savingProfile,
      );

      await auth.updateUserProfile(
        userId: widget.user.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        category: _category,
        subCategory: _subCategory,
        churchName: _churchController.text.trim(),
        photoUrl: photoUrl,
        birthDate: _selectedDate,
        referredBy: _referralController.text.trim().isNotEmpty
            ? _referralController.text.trim()
            : null,
      );

      setState(() => _loadingStatus = AppLocalizations.of(context)!.finished);

      // Refresh profile to trigger navigation in main.dart
      ref.invalidate(currentUserProfileProvider);

      // Small delay to allow state propagation
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorPrefix}$e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
          _loadingStatus = '';
        });
      }
    } finally {
      slowConnectionTimer.cancel();
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _loadingStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Simple Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.backgroundGradientStart,
                  AppTheme.backgroundDark,
                ],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.textPrimary.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Photo Upload
                              GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.surfaceDark,
                                        border: Border.all(
                                          color: AppTheme.primaryColor,
                                          width: 2,
                                        ),
                                        image: _imageFile != null
                                            ? DecorationImage(
                                                image: FileImage(_imageFile!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: _imageFile == null
                                          ? const Icon(
                                              Icons.add_a_photo,
                                              size: 40,
                                              color: Colors.white70,
                                            )
                                          : null,
                                    ),
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
                                          Icons.edit,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.completeProfileTitle,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.completeProfileSubtitle,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),

                              // First Name
                              TextFormField(
                                controller: _firstNameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _buildInputDecoration(
                                  AppLocalizations.of(context)!.firstNameLabel,
                                  const Icon(
                                    Icons.person,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                validator: (v) => v?.isEmpty ?? true
                                    ? AppLocalizations.of(
                                        context,
                                      )!.firstNameRequired
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // Last Name
                              TextFormField(
                                controller: _lastNameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _buildInputDecoration(
                                  AppLocalizations.of(context)!.lastNameLabel,
                                  const Icon(
                                    Icons.person_outline,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                validator: (v) => v?.isEmpty ?? true
                                    ? AppLocalizations.of(
                                        context,
                                      )!.lastNameRequired
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // Date of Birth
                              GestureDetector(
                                onTap: () => _selectDate(context),
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    controller: _dateController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _buildInputDecoration(
                                      AppLocalizations.of(
                                        context,
                                      )!.birthDateLabel,
                                      const Icon(
                                        Icons.calendar_today,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    validator: (v) => v?.isEmpty ?? true
                                        ? AppLocalizations.of(
                                            context,
                                          )!.birthDateRequired
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Church
                              TextFormField(
                                controller: _churchController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _buildInputDecoration(
                                  AppLocalizations.of(context)!.churchLabel,
                                  const Icon(
                                    Icons.church,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                validator: (v) => v?.isEmpty ?? true
                                    ? AppLocalizations.of(
                                        context,
                                      )!.churchRequired
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // Referral Code (Obligatoire si pas de parrain)
                              TextFormField(
                                controller: _referralController,
                                readOnly: _hasReferrer,
                                style: TextStyle(
                                  color: _hasReferrer
                                      ? Colors.greenAccent
                                      : Colors.white,
                                ),
                                decoration: _buildInputDecoration(
                                  _hasReferrer
                                      ? AppLocalizations.of(
                                          context,
                                        )!.referralCodeActive
                                      : AppLocalizations.of(
                                          context,
                                        )!.referralCodeMandatory,
                                  Icon(
                                    Icons.star,
                                    color: _hasReferrer
                                        ? Colors.green
                                        : AppTheme.primaryColor,
                                  ),
                                ),
                                validator: (v) {
                                  if (_hasReferrer) return null;
                                  return v?.trim().isEmpty ?? true
                                      ? AppLocalizations.of(
                                          context,
                                        )!.referralCodeRequired
                                      : null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Category
                              _buildCategoryCard(
                                title: AppLocalizations.of(context)!.musician,
                                iconWidget: Image.asset(
                                  'assets/Logo.png',
                                  width: 28,
                                  height: 28,
                                  color: _category == 'Chantre & Instrumentiste'
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                                isSelected:
                                    _category == 'Chantre & Instrumentiste',
                                onTap: () => setState(() {
                                  _category = 'Chantre & Instrumentiste';
                                  _subCategory = null;
                                }),
                              ),
                              const SizedBox(height: 16),
                              _buildCategoryCard(
                                title: AppLocalizations.of(
                                  context,
                                )!.servantOfGod,
                                iconWidget: Icon(
                                  Icons.church,
                                  color: _category == 'Homme de Dieu'
                                      ? Colors.white
                                      : Colors.white70,
                                  size: 28,
                                ),
                                isSelected: _category == 'Homme de Dieu',
                                onTap: () => setState(() {
                                  _category = 'Homme de Dieu';
                                  _subCategory = null;
                                }),
                              ),

                              if (_category == 'Chantre & Instrumentiste' ||
                                  _category == 'Homme de Dieu') ...[
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  key: ValueKey(_category),
                                  initialValue: _subCategory,
                                  dropdownColor: AppTheme.surfaceDark,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _buildInputDecoration(
                                    _category == 'Chantre & Instrumentiste'
                                        ? AppLocalizations.of(
                                            context,
                                          )!.instrumentOrRole
                                        : AppLocalizations.of(
                                            context,
                                          )!.ministry,
                                    _category == 'Chantre & Instrumentiste'
                                        ? Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Image.asset(
                                              'assets/Logo.png',
                                              width: 24,
                                              height: 24,
                                              fit: BoxFit.contain,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.star,
                                            color: AppTheme.primaryColor,
                                          ),
                                  ),
                                  items:
                                      (_category == 'Chantre & Instrumentiste'
                                              ? _musicienRoles
                                              : _ministreRoles)
                                          .map(
                                            (c) => DropdownMenuItem(
                                              value: c,
                                              child: Text(
                                                _getLocalizedRole(context, c),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (val) =>
                                      setState(() => _subCategory = val),
                                  validator: (val) => val == null
                                      ? AppLocalizations.of(
                                          context,
                                        )!.selectionRequired
                                      : null,
                                ),
                              ],

                              const SizedBox(height: 16),

                              const SizedBox(height: 24),

                              // Privacy Checkbox
                              CheckboxListTile(
                                value: _acceptedPrivacy,
                                onChanged: (val) {
                                  setState(() {
                                    _acceptedPrivacy = val ?? false;
                                  });
                                },
                                title: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PrivacyPolicyPage(),
                                      ),
                                    );
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: AppLocalizations.of(
                                            context,
                                          )!.readAndAccept,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                        TextSpan(
                                          text: AppLocalizations.of(
                                            context,
                                          )!.privacyPolicy,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline,
                                            fontSize: 12,
                                          ),
                                        ),
                                        TextSpan(
                                          text: AppLocalizations.of(
                                            context,
                                          )!.ofAppByAuthor,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                activeColor: AppTheme.primaryColor,
                                checkColor: Colors.white,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),

                              const SizedBox(height: 16),

                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                      : Text(
                                          AppLocalizations.of(context)!.save,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedRole(BuildContext context, String role) {
    final loc = AppLocalizations.of(context)!;
    switch (role) {
      case 'Pianiste':
        return loc.rolePianist;
      case 'Batteur':
        return loc.roleDrummer;
      case 'Bassiste':
        return loc.roleBassist;
      case 'Guitariste':
        return loc.roleGuitarist;
      case 'Saxophoniste':
        return loc.roleSaxophonist;
      case 'Percussionniste':
        return loc.rolePercussionist;
      case 'Violoniste':
        return loc.roleViolinist;
      case 'Synthétiseur':
        return loc.roleSynthesizer;
      case 'Trompettiste':
        return loc.roleTrumpeter;
      case 'Flûtiste':
        return loc.roleFlutist;
      case 'Chantre':
        return loc.roleSinger;
      case 'Maître de chœur':
        return loc.roleChoirMaster;
      case 'Formateur Musique':
        return loc.roleMusicTrainer;
      case 'Ingénieur son':
        return loc.roleSoundEngineer;
      case 'Beatmaker':
        return loc.roleBeatmaker;
      case 'Pasteur':
        return loc.rolePastor;
      case 'Prophète':
        return loc.roleProphet;
      case 'Diacre':
        return loc.roleDeacon;
      case 'Évangéliste':
        return loc.roleEvangelist;
      case 'Docteur':
        return loc.roleDoctor;
      case 'Apôtre':
        return loc.roleApostle;
      default:
        return role;
    }
  }

  InputDecoration _buildInputDecoration(String label, Widget prefixIcon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: prefixIcon,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required Widget iconWidget,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
}
