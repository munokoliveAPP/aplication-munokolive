import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:munokolive_music/models/location_model.dart';
import 'package:munokolive_music/services/notification_service.dart';
import 'package:munokolive_music/ui/widgets/smart_snackbar.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditPlacePage extends ConsumerStatefulWidget {
  final LocationModel location;

  const EditPlacePage({super.key, required this.location});

  @override
  ConsumerState<EditPlacePage> createState() => _EditPlacePageState();
}

class _EditPlacePageState extends ConsumerState<EditPlacePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _responsibleController;
  late TextEditingController _phoneController;
  late String _category;

  File? _newImageFile;
  File? _newInteriorImageFile;

  bool _isSubmitting = false;
  String _loadingStatus = ''; // Added for feedback
  late double? _latitude;
  late double? _longitude;
  bool _isCapturingLocation = false;

  final List<String> _categories = [
    "Église",
    "Salle de répétition",
    "Studio d'enregistrement",
    "Espace événementiel",
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location.name);
    _responsibleController = TextEditingController(
      text: widget.location.responsibleName,
    );
    _phoneController = TextEditingController(
      text: widget.location.contactPhone,
    );
    _category = widget.location.category;
    if (!_categories.contains(_category)) {
      _category = _categories.first;
    }
    _latitude = widget.location.latitude;
    _longitude = widget.location.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _responsibleController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({bool isInterior = false}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked != null) {
      setState(() {
        if (isInterior) {
          _newInteriorImageFile = File(picked.path);
        } else {
          _newImageFile = File(picked.path);
        }
      });
    }
  }

  Future<void> _captureLocation() async {
    setState(() => _isCapturingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        SmartSnackBar.show(
          context,
          message:
              "📍 Position mise à jour : ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}",
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        SmartSnackBar.show(
          context,
          message: "Impossible de capturer la position. Vérifiez votre GPS.",
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Connectivity Check
    final connectivity = await Connectivity().checkConnectivity();
    if (!mounted) return;
    if (connectivity.contains(ConnectivityResult.none)) {
      SmartSnackBar.show(
        context,
        message: "Pas de connexion Internet",
        isError: true,
      );
      return;
    }

    if (_newImageFile == null && widget.location.imageUrl == null) {
      SmartSnackBar.show(
        context,
        message: "Veuillez ajouter une image",
        isError: true,
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      SmartSnackBar.show(
        context,
        message: "Veuillez capturer la position du lieu",
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _loadingStatus = 'Préparation...';
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw "Utilisateur non connecté";

      String? imageUrl = widget.location.imageUrl;

      // 1. Upload New Exterior Image if picked
      if (_newImageFile != null) {
        setState(() => _loadingStatus = 'Envoi de l\'image extérieure...');
        final imageExtension = _newImageFile!.path.split('.').last;
        final imagePath =
            'places/${DateTime.now().millisecondsSinceEpoch}_ext.$imageExtension';

        await Supabase.instance.client.storage
            .from('files')
            .upload(imagePath, _newImageFile!);

        imageUrl = Supabase.instance.client.storage
            .from('files')
            .getPublicUrl(imagePath);
      }

      // 1b. Upload New Interior Image if picked
      String? interiorImageUrl = widget.location.interiorImageUrl;
      if (_newInteriorImageFile != null) {
        setState(() => _loadingStatus = 'Envoi de l\'image intérieure...');
        final intImageExtension = _newInteriorImageFile!.path.split('.').last;
        final intImagePath =
            'places/${DateTime.now().millisecondsSinceEpoch}_int.$intImageExtension';
        await Supabase.instance.client.storage
            .from('files')
            .upload(intImagePath, _newInteriorImageFile!);

        interiorImageUrl = Supabase.instance.client.storage
            .from('files')
            .getPublicUrl(intImagePath);
      }

      // 2. Update Database
      setState(() => _loadingStatus = 'Mise à jour des données...');
      await Supabase.instance.client
          .from('locations')
          .update({
            'name': _nameController.text.trim(),
            'category': _category,
            'image_url': imageUrl,
            'interior_image_url': interiorImageUrl,
            'responsible_name': _responsibleController.text.trim(),
            'contact_phone': _phoneController.text.trim(),
            'latitude': _latitude,
            'longitude': _longitude,
            'address':
                "Lieu mis à jour via GPS", // Simple update, could be geocoded
            // Don't update submitted_by or is_validated unless needed logic changes
          })
          .eq('id', widget.location.id);

      // Trigger Notification
      ref
          .read(notificationServiceProvider)
          .showNotification(
            id: widget.location.id.hashCode,
            title: "Lieu modifié avec succès",
            body:
                "Les modifications pour ${_nameController.text} ont été enregistrées.",
          );

      setState(() => _loadingStatus = 'Terminé !');

      if (mounted) {
        Navigator.pop(
          context,
          true,
        ); // Return true to indicate success/refresh needed
        SmartSnackBar.show(
          context,
          message: "✅ Lieu modifié avec succès !",
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        SmartSnackBar.show(context, message: "Erreur: $e", isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _loadingStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E0024),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E0024),
        title: const Text("Modifier le lieu"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Images Pickers Row
                Row(
                  children: [
                    // Exterior
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickImage(isInterior: false),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              style: BorderStyle.solid,
                            ),
                            image: _newImageFile != null
                                ? DecorationImage(
                                    image: FileImage(_newImageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : (widget.location.imageUrl != null
                                      ? DecorationImage(
                                          image: CachedNetworkImageProvider(
                                            widget.location.imageUrl!,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null),
                          ),
                          child:
                              (_newImageFile == null &&
                                  widget.location.imageUrl == null)
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      color: Colors.white54,
                                      size: 30,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Extérieur (Façade)",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Interior
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickImage(isInterior: true),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.purpleAccent.withValues(alpha: 0.5),
                              style: BorderStyle.solid,
                            ),
                            image: _newInteriorImageFile != null
                                ? DecorationImage(
                                    image: FileImage(_newInteriorImageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : (widget.location.interiorImageUrl != null
                                      ? DecorationImage(
                                          image: CachedNetworkImageProvider(
                                            widget.location.interiorImageUrl!,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null),
                          ),
                          child:
                              (_newInteriorImageFile == null &&
                                  widget.location.interiorImageUrl == null)
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      color: Colors.white54,
                                      size: 30,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Intérieur (Optionnel)",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Nom du Lieu",
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.place, color: AppTheme.primaryColor),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryColor),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Nom requis" : null,
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  dropdownColor: const Color(0xFF2D0036),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Catégorie",
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(
                      Icons.category,
                      color: AppTheme.primaryColor,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryColor),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setState(() => _category = val!),
                ),
                const SizedBox(height: 16),

                // Responsible Name
                TextFormField(
                  controller: _responsibleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Nom du Responsable",
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(
                      Icons.person,
                      color: AppTheme.primaryColor,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryColor),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Contact Téléphonique",
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.phone, color: AppTheme.primaryColor),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryColor),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // GPS Capture
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.my_location,
                        color: _latitude != null ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _latitude != null
                                  ? "Position enregistrée"
                                  : "Position non définie",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_latitude != null)
                              Text(
                                "${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _isCapturingLocation
                            ? null
                            : _captureLocation,
                        icon: _isCapturingLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.gps_fixed),
                        label: Text(
                          _latitude != null ? "Mettre à jour" : "Capturer",
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
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
                          "ENREGISTRER LES MODIFICATIONS",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                // Keyboard padding
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
