/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Added
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:munokolive_music/models/location_model.dart';
import 'package:munokolive_music/services/notification_service.dart'; // Added
import 'package:munokolive_music/ui/places/place_details_page.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';
import 'package:munokolive_music/ui/widgets/smart_snackbar.dart';
import 'package:munokolive_music/ui/widgets/glass_container.dart';
import 'package:munokolive_music/ui/widgets/skeleton_loader.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:munokolive_music/l10n/app_localizations.dart';

import 'package:munokolive_music/providers/locations_repository.dart';
import 'package:munokolive_music/ui/places/controllers/places_controller.dart';
import 'package:munokolive_music/providers/user_location_provider.dart';

class PlacesPage extends ConsumerStatefulWidget {
  const PlacesPage({super.key});

  @override
  ConsumerState<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends ConsumerState<PlacesPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Sync controller with current provider state if needed
    _searchController.text = ref.read(placesSearchQueryProvider);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openMap(double lat, double lng) async {
    final googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        SmartSnackBar.show(
          context,
          message: AppLocalizations.of(context)!.mapOpenError,
          isError: true,
        );
      }
    }
  }

  void _showAddPlaceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddPlaceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final categoriesMap = {
      "Tous": localizations.allCategories,
      "Église": localizations.church,
      "Salle de répétition": localizations.rehearsalRoom,
      "Studio d'enregistrement": localizations.recordingStudio,
      "Espace événementiel": localizations.eventSpace,
    };

    final selectedCategory = ref.watch(placesCategoryProvider);
    final placesAsync = ref.watch(filteredPlacesProvider);
    final userLocationAsync = ref.watch(userLocationProvider);
    final currentPosition = userLocationAsync.valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF2D0036),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.placesTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  InkWell(
                    onTap: () => _showAddPlaceDialog(context),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, Colors.purpleAccent],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add_location_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            localizations.addPlace,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: GlassContainer(
                borderRadius: 15,
                blur: 10,
                opacity: 0.05,
                color: Colors.white,
                padding: EdgeInsets.zero,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(placesSearchQueryProvider.notifier).state = val;
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: localizations.searchPlaceholder,
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: categoriesMap.entries.map((entry) {
                  final categoryKey = entry.key;
                  final categoryLabel = entry.value;
                  final isSelected = selectedCategory == categoryKey;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: FilterChip(
                      label: Text(categoryLabel),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        ref.read(placesCategoryProvider.notifier).state =
                            categoryKey;
                      },
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      selectedColor: AppTheme.primaryColor,
                      checkmarkColor: Colors.white,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.white10,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(locationsStreamProvider);
                  await Future.delayed(const Duration(milliseconds: 500));
                  if (!mounted) return;
                  if (!context.mounted) return;
                  SmartSnackBar.show(
                    context,
                    message: localizations.listUpdated,
                    isSuccess: true,
                  );
                },
                color: AppTheme.primaryColor,
                backgroundColor: const Color(0xFF2D0036),
                child: placesAsync.when(
                  loading: () => const SkeletonListLoader(itemCount: 8),
                  error: (err, stack) => Center(
                    child: Text(
                      "${localizations.errorPrefix}$err",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  data: (filtered) {
                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 60,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              localizations.noPlacesFound,
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final place = filtered[index];
                        return _buildPlaceCard(place, currentPosition);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(
    LocationModel location,
    Position? currentPosition, {
    bool isClosest = false,
  }) {
    // Calculate distance for display
    String? distanceDisplay;
    if (currentPosition != null &&
        location.latitude != null &&
        location.longitude != null) {
      final dist = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        location.latitude!,
        location.longitude!,
      );
      distanceDisplay = dist < 1000
          ? "${dist.toStringAsFixed(0)} m"
          : "${(dist / 1000).toStringAsFixed(1)} km";
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceDetailsPage(
              location: location,
              userPosition: currentPosition,
            ),
          ),
        );
      },
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isClosest
                  ? Colors.orange.withValues(alpha: 0.3)
                  : AppTheme.primaryColor.withValues(alpha: 0.2),
              blurRadius: isClosest ? 20 : 10,
              spreadRadius: isClosest ? 2 : 1,
            ),
          ],
          border: isClosest
              ? Border.all(color: Colors.orange, width: 2)
              : Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  width: 1,
                ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              location.imageUrl != null
                  ? Hero(
                      tag: 'place-img-${location.id}',
                      child: CachedNetworkImage(
                        imageUrl: location.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[900]),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.error),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[900],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.white24,
                      ),
                    ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black,
                    ],
                    stops: const [0.5, 0.8, 1.0],
                  ),
                ),
              ),

              // "Closest" Badge
              if (isClosest)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Builder(
                          builder: (context) => Text(
                            AppLocalizations.of(context)!.closestPlace,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Distance Badge
              if (!isClosest && distanceDisplay != null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distanceDisplay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Info Panel
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.black.withValues(alpha: 0.4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  location.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            location.category,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location.address ??
                                      AppLocalizations.of(
                                        context,
                                      )!.addressUnspecified,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (location.latitude != null &&
                                      location.longitude != null) {
                                    _openMap(
                                      location.latitude!,
                                      location.longitude!,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(12),
                                ),
                                child: const Icon(
                                  Icons.directions,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
}

class AddPlaceSheet extends ConsumerStatefulWidget {
  const AddPlaceSheet({super.key});

  @override
  ConsumerState<AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends ConsumerState<AddPlaceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _responsibleController = TextEditingController();
  final _phoneController = TextEditingController();
  String _category = "Église";
  File? _imageFile;
  File? _interiorImageFile;
  bool _isSubmitting = false;
  Position? _capturedPosition;
  bool _isCapturingLocation = false;
  String _loadingStatus = '';

  final List<String> _categories = [
    "Église",
    "Salle de répétition",
    "Studio d'enregistrement",
    "Espace événementiel",
  ];

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
          _interiorImageFile = File(picked.path);
        } else {
          _imageFile = File(picked.path);
        }
      });
    }
  }

  Future<void> _captureLocation() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isCapturingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _capturedPosition = position;
        });
        SmartSnackBar.show(
          context,
          message: l10n.positionCaptured(position.latitude, position.longitude),
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        SmartSnackBar.show(
          context,
          message: l10n.gpsCaptureError,
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    // Connectivity Check
    final connectivity = await Connectivity().checkConnectivity();
    if (!mounted) return;
    if (connectivity.contains(ConnectivityResult.none)) {
      SmartSnackBar.show(
        context,
        message: l10n.networkError,
        isError: true,
      );
      return;
    }

    if (_imageFile == null) {
      SmartSnackBar.show(
        context,
        message: AppLocalizations.of(context)!.pleaseAddImage,
        isError: true,
      );
      return;
    }
    if (_capturedPosition == null) {
      SmartSnackBar.show(
        context,
        message: AppLocalizations.of(context)!.pleaseCapturePosition,
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _loadingStatus = AppLocalizations.of(context)!.statusPreparing;
    });

    try {
      // final auth = ref.read(authServiceProvider); // Unused
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw AppLocalizations.of(context)!.userNotLoggedIn;

      // 1. Upload Exterior Image
      setState(
        () => _loadingStatus = AppLocalizations.of(
          context,
        )!.statusUploadingMainPhoto,
      );
      final imageExtension = _imageFile!.path.split('.').last;
      final imagePath =
          'places/${DateTime.now().millisecondsSinceEpoch}_ext.$imageExtension';

      // Use 'files' bucket
      await Supabase.instance.client.storage
          .from('files')
          .upload(imagePath, _imageFile!);

      final imageUrl = Supabase.instance.client.storage
          .from('files')
          .getPublicUrl(imagePath);

      // 1b. Upload Interior Image (Optional)
      String? interiorImageUrl;
      if (_interiorImageFile != null) {
        setState(
          () => _loadingStatus = AppLocalizations.of(
            context,
          )!.statusUploadingInteriorPhoto,
        );
        final intImageExtension = _interiorImageFile!.path.split('.').last;
        final intImagePath =
            'places/${DateTime.now().millisecondsSinceEpoch}_int.$intImageExtension';
        await Supabase.instance.client.storage
            .from('files')
            .upload(intImagePath, _interiorImageFile!);

        interiorImageUrl = Supabase.instance.client.storage
            .from('files')
            .getPublicUrl(intImagePath);
      }

      // 2. Use Captured Location
      final position = _capturedPosition!;

      // 3. Insert into Database
      setState(
        () => _loadingStatus = AppLocalizations.of(context)!.statusSavingPlace,
      );
      // Fetch user name for "submitted_by_name" and role
      final userData = await Supabase.instance.client
          .from('users')
          .select('first_name, last_name, role')
          .eq('id', user.id)
          .single();
      final submitterName =
          "${userData['first_name']} ${userData['last_name']}";
      final isAdmin = userData['role'] == 'admin';

      await Supabase.instance.client.from('locations').insert({
        'name': _nameController.text.trim(),
        'category': _category,
        'image_url': imageUrl,
        'interior_image_url': interiorImageUrl,
        'responsible_name': _responsibleController.text.trim(),
        'contact_phone': _phoneController.text.trim(),
        'submitted_by_name': submitterName,
        'submitted_by_id': user.id,
        'is_validated': isAdmin, // Auto-validate for admins
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': l10n.addressUnspecified,
      });
      if (!mounted) return;

      // Trigger Notification
      ref.invalidate(locationsStreamProvider); // Refresh the list
      ref.read(notificationServiceProvider).showNotification(
            id: DateTime.now().millisecondsSinceEpoch,
            title: l10n.placeSubmittedTitle,
            body: isAdmin
                ? l10n.placePublishedImmediately
                : l10n.placeProposalSent(_nameController.text),
          );

      Navigator.pop(context);
      SmartSnackBar.show(
        context,
        message: isAdmin ? l10n.placeAddedAndValidated : l10n.placeSubmittedPending,
        isSuccess: true,
      );
    } catch (e) {
      if (mounted) {
        SmartSnackBar.show(
          context,
          message: "${l10n.errorPrefix}$e",
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0024),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context)!.proposeSacredPlace,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
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
                            color: AppTheme.primaryColor.withValues(alpha: 0.5),
                            style: BorderStyle.solid,
                          ),
                          image: _imageFile != null
                              ? DecorationImage(
                                  image: FileImage(_imageFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _imageFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_a_photo,
                                    color: Colors.white54,
                                    size: 30,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.exteriorFacade,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
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
                          image: _interiorImageFile != null
                              ? DecorationImage(
                                  image: FileImage(_interiorImageFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _interiorImageFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_photo_alternate,
                                    color: Colors.white54,
                                    size: 30,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.interiorOptional,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
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
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  AppLocalizations.of(context)!.placeNameLabel,
                ),
                validator: (v) => v?.isEmpty ?? true
                    ? AppLocalizations.of(context)!.requiredField
                    : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _category,
                // Use value instead of initialValue for controlled component
                dropdownColor: const Color(0xFF2D0036),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  AppLocalizations.of(context)!.categoryLabel,
                ),
                items: _categories.map((c) {
                  String label = c;
                  final loc = AppLocalizations.of(context)!;
                  if (c == "Église") {
                    label = loc.church;
                  } else if (c == "Salle de répétition") {
                    label = loc.rehearsalRoom;
                  } else if (c == "Studio d'enregistrement") {
                    label = loc.recordingStudio;
                  } else if (c == "Espace événementiel") {
                    label = loc.eventSpace;
                  }
                  return DropdownMenuItem(value: c, child: Text(label));
                }).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _responsibleController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  AppLocalizations.of(context)!.managerNameLabel,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  AppLocalizations.of(context)!.contactPhoneLabel,
                ),
              ),

              const SizedBox(height: 24),

              // GPS Capture Button
              InkWell(
                onTap: _isCapturingLocation ? null : _captureLocation,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _capturedPosition != null
                          ? [Colors.green.shade800, Colors.green.shade600]
                          : [
                              Colors.orange.shade800,
                              Colors.deepOrange.shade800,
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_capturedPosition != null
                                    ? Colors.green
                                    : Colors.orange)
                                .withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _capturedPosition != null
                            ? Icons.check_circle
                            : Icons.my_location,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      _isCapturingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _capturedPosition != null
                                  ? AppLocalizations.of(
                                      context,
                                    )!.positionSavedEdit
                                  : AppLocalizations.of(
                                      context,
                                    )!.markThisPlaceGps,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ],
                  ),
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
                    : Text(
                        AppLocalizations.of(context)!.submitForValidation,
                        style: const TextStyle(
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
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
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
    );
  }
}
