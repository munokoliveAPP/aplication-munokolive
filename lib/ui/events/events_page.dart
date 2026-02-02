/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Added
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:munokolive_music/providers/notification_feed_provider.dart';
import 'package:munokolive_music/models/event_model.dart';
import 'dart:ui';
import 'package:munokolive_music/services/notification_service.dart'; // Added
import 'package:munokolive_music/ui/events/event_details_page.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:munokolive_music/ui/widgets/skeleton_loader.dart'; // Added
import 'package:munokolive_music/ui/widgets/smart_snackbar.dart';

import 'package:munokolive_music/providers/events_repository.dart';
import 'package:munokolive_music/ui/events/controllers/events_controller.dart';
import 'package:munokolive_music/providers/user_location_provider.dart';

class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage> {
  // Removed unused _supabase and manual location state
  bool _notifiedProximity = false;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterCategories = [
    'Tous',
    'Concert',
    'Programme de Prière',
    'Culte',
    'Moment d\'Adoration',
    'Djamming',
    'Formation',
    'Master Class',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    // Sync controller with provider state
    _searchController.text = ref.read(eventsSearchQueryProvider);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _checkProximity(List<EventModel> events, Position? currentPosition) {
    if (currentPosition == null || _notifiedProximity) return;

    for (var event in events) {
      if (event.latitude != null &&
          event.longitude != null &&
          event.isValidated) {
        final distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          event.latitude!,
          event.longitude!,
        );

        if (distance < 2000) {
          // Notify within 2km for events
          _notifiedProximity = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              SmartSnackBar.show(
                context,
                title: "🎉 Événement proche : ${event.name} !",
                message: "C'est juste à côté !",
                actionLabel: "VOIR",
                onActionPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailsPage(event: event),
                    ),
                  );
                },
              );
            }
          });
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(eventsCategoryProvider);
    final eventsAsync = ref.watch(filteredEventsProvider);
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
                  const Text(
                    "Nos Événements",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  InkWell(
                    onTap: () => _showAddEventDialog(context),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.deepOrange, Colors.orangeAccent],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepOrange.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_circle, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text(
                            "CRÉER",
                            style: TextStyle(
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

            // Barre de Recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(eventsSearchQueryProvider.notifier).state = val;
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Rechercher un événement...",
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.search, color: Colors.orange),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixIcon: Icon(Icons.tune, color: Colors.white38),
                  ),
                ),
              ),
            ),

            // Barre de filtres horizontale
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filterCategories.length,
                itemBuilder: (context, index) {
                  final category = _filterCategories[index];
                  final isSelected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        ref.read(eventsCategoryProvider.notifier).state =
                            category;
                      },
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      selectedColor: Colors.orange,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.orange : Colors.white24,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(eventsStreamProvider);
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                color: Colors.orange,
                backgroundColor: const Color(0xFF2D0036),
                child: eventsAsync.when(
                  loading: () => const SkeletonCardLoader(itemCount: 4),
                  error: (err, stack) => Center(
                    child: Text(
                      "Erreur: $err",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  data: (filteredEvents) {
                    if (filteredEvents.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 60,
                              color: Colors.white24,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Aucun événement trouvé pour cette catégorie.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      );
                    }

                    // Check proximity using the current position
                    _checkProximity(filteredEvents, currentPosition);

                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredEvents.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        final event = filteredEvents[index];
                        return _buildEventCard(event, currentPosition);
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

  Widget _buildEventCard(EventModel event, Position? currentPosition) {
    String distanceDisplay = "";
    if (currentPosition != null &&
        event.latitude != null &&
        event.longitude != null) {
      final dist = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        event.latitude!,
        event.longitude!,
      );
      distanceDisplay = dist < 1000
          ? "${dist.toStringAsFixed(0)}m"
          : "${(dist / 1000).toStringAsFixed(1)}km";
    }

    final isExpired = event.eventDate.isBefore(DateTime.now());

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsPage(
              event: event,
              distanceInfo: distanceDisplay.isNotEmpty ? distanceDisplay : null,
            ),
          ),
        );
      },
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isExpired
                  ? Colors.grey.withValues(alpha: 0.2)
                  : Colors.purple.withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster Image (Grayscale if expired)
              event.imageUrl != null
                  ? ColorFiltered(
                      colorFilter: isExpired
                          ? const ColorFilter.matrix(<double>[
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0,
                              0,
                              0,
                              1,
                              0,
                            ])
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            ),
                      child: Hero(
                        tag: 'event-img-${event.id}',
                        child: CachedNetworkImage(
                          imageUrl: event.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: Colors.grey[900]),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.image, color: Colors.white24),
                    ),

              // Overlay "TERMINÉ" if expired
              if (isExpired)
                Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  alignment: Alignment.center,
                  child: Transform.rotate(
                    angle: -0.2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "TERMINÉ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),

              // Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),

              // Date Badge (Top Left)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        event.eventDate.day.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        _getMonthName(event.eventDate.month),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Distance Badge (Top Right)
              if (distanceDisplay.isNotEmpty)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      distanceDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

              // Info (Bottom) - Glass Effect
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.black.withValues(alpha: 0.3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.locationName ?? "Lieu non précisé",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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

  String _getMonthName(int month) {
    const months = [
      "JAN",
      "FÉV",
      "MAR",
      "AVR",
      "MAI",
      "JUIN",
      "JUIL",
      "AOÛT",
      "SEP",
      "OCT",
      "NOV",
      "DÉC",
    ];
    return months[month - 1];
  }

  void _showAddEventDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddEventSheet(),
    );
  }
}

class AddEventSheet extends ConsumerStatefulWidget {
  const AddEventSheet({super.key});

  @override
  ConsumerState<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends ConsumerState<AddEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _locationNameController = TextEditingController();

  // Catégories Gospel
  final List<String> _categories = [
    'Concert',
    'Programme de Prière',
    'Culte',
    'Moment d\'Adoration',
    'Djamming',
    'Formation',
    'Master Class',
    'Autre',
  ];
  String _selectedCategory = 'Concert';

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);

  File? _imageFile;
  Position? _capturedPosition;
  bool _isCapturingLocation = false;
  bool _isSubmitting = false;
  String _loadingStatus = '';
  bool _useGPS = true; // Par défaut, on utilise le GPS

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 1200,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
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
        setState(() => _capturedPosition = position);
        SmartSnackBar.show(
          context,
          message: "📍 Position de l'événement capturée !",
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        SmartSnackBar.show(context, message: "Erreur GPS", isError: true);
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
        message: "Pas de connexion Internet. Veuillez vérifier votre réseau.",
        isError: true,
      );
      return;
    }

    if (_imageFile == null) {
      SmartSnackBar.show(
        context,
        message: "L'affiche de l'événement est requise",
        isError: true,
      );
      return;
    }
    if (_useGPS && _capturedPosition == null) {
      SmartSnackBar.show(
        context,
        message: "Veuillez marquer le lieu (GPS) ou désactiver l'option GPS",
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
      if (user == null) throw "Non connecté";

      // Récupérer le profil utilisateur pour vérifier le rôle
      final userData = await Supabase.instance.client
          .from('users')
          .select('first_name, last_name, role')
          .eq('id', user.id)
          .single();

      final submitterName =
          "${userData['first_name']} ${userData['last_name']}";
      final isAdmin = userData['role'] == 'admin';

      // Upload Image
      setState(() => _loadingStatus = 'Envoi de l\'image...');
      final imageExtension = _imageFile!.path.split('.').last;
      final imagePath =
          'events/${DateTime.now().millisecondsSinceEpoch}.$imageExtension';

      // Utilisation du bucket unique 'files'
      const bucketName = 'files';

      // Upload avec Timeout et gestion d'erreur
      await Supabase.instance.client.storage
          .from(bucketName)
          .upload(
            imagePath,
            _imageFile!,
            fileOptions: const FileOptions(upsert: true),
          )
          .timeout(const Duration(seconds: 45));

      final imageUrl = Supabase.instance.client.storage
          .from(bucketName)
          .getPublicUrl(imagePath);

      // Date Time
      final eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Insert avec Timeout
      setState(() => _loadingStatus = 'Enregistrement...');
      // Note: On retire 'category' temporairement car la colonne n'existe pas encore en base de données
      // Cela corrige l'erreur PGRST204
      await Supabase.instance.client
          .from('events')
          .insert({
            'name': _nameController.text.trim(),
            'description':
                "${_descController.text.trim()}\n[Catégorie: $_selectedCategory]", // Hack pour garder l'info
            // 'category': _selectedCategory, // RETIRÉ pour éviter le crash
            'event_date': eventDateTime.toIso8601String(),
            'image_url': imageUrl,
            'location_name': _locationNameController.text.trim(),
            'latitude': _useGPS ? _capturedPosition?.latitude : null,
            'longitude': _useGPS ? _capturedPosition?.longitude : null,
            'submitted_by_name': submitterName,
            'submitted_by_id': user.id,
            'is_validated': isAdmin,
          })
          .timeout(const Duration(seconds: 15));

      // Notification
      try {
        ref
            .read(notificationServiceProvider)
            .showNotification(
              id: DateTime.now().millisecondsSinceEpoch,
              title: "Événement Envoyé !",
              body: isAdmin
                  ? "Votre événement est en ligne."
                  : "Votre événement est en attente de validation.",
            );
        // Force refresh notifications
        ref.invalidate(notificationFeedProvider);
      } catch (e) {
        debugPrint("Notification Error: $e");
      }

      if (mounted) {
        Navigator.pop(context); // Close sheet
        // Show success message
        SmartSnackBar.show(
          context,
          message: isAdmin
              ? "✅ Événement publié avec succès !"
              : "📩 Événement soumis ! En attente de validation.",
          isSuccess: true, // Shows green (or based on implementation)
        );
      }
    } catch (e) {
      if (mounted) {
        // Close sheet even on error if it's a specific one, or stay?
        // Better stay to let user retry.
        SmartSnackBar.show(
          context,
          message: "❌ Erreur (TimeOut ou Réseau) : $e",
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
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Créer un Événement",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Image Picker (Poster)
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.5),
                    ),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageFile == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              color: Colors.white54,
                              size: 50,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Ajouter l'affiche (Poster)",
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Nom de l'événement"),
                validator: (v) => v?.isEmpty ?? true ? "Requis" : null,
              ),
              const SizedBox(height: 12),

              // Dropdown Catégorie
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    dropdownColor: const Color(0xFF2D0036),
                    isExpanded: true,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.orange,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: _inputDecoration("Description"),
              ),
              const SizedBox(height: 12),

              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (d != null) setState(() => _selectedDate = d);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (t != null) setState(() => _selectedTime = t);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _locationNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  "Nom du lieu (ex: Stade Felix Houphouet)",
                ),
                validator: (v) => v?.isEmpty ?? true ? "Requis" : null,
              ),
              const SizedBox(height: 16),

              // GPS Toggle Switch
              SwitchListTile(
                title: const Text(
                  "Utiliser la localisation GPS",
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  "Désactivez si vous n'êtes pas sur le lieu",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                value: _useGPS,
                activeThumbColor: Colors.orange,
                onChanged: (bool value) {
                  setState(() {
                    _useGPS = value;
                    if (!value) _capturedPosition = null; // Reset si désactivé
                  });
                },
              ),

              if (_useGPS) ...[
                if (_capturedPosition == null)
                  ElevatedButton.icon(
                    onPressed: _isCapturingLocation ? null : _captureLocation,
                    icon: _isCapturingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.location_on),
                    label: Text(
                      _isCapturingLocation
                          ? "Localisation..."
                          : "Marquer le lieu (GPS)",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Position capturée :\nLat: ${_capturedPosition!.latitude.toStringAsFixed(5)}\nLng: ${_capturedPosition!.longitude.toStringAsFixed(5)}",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _captureLocation,
                        ),
                      ],
                    ),
                  ),
              ] else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.location_off, color: Colors.white54),
                      SizedBox(width: 8),
                      Text(
                        "Localisation GPS désactivée",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
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
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        "PUBLIER L'ÉVÉNEMENT",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
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
        borderSide: const BorderSide(color: Colors.orange),
      ),
    );
  }
}
