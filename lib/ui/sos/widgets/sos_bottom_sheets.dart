import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../providers/sos_provider.dart';
import '../../../services/auth_service.dart';
import '../../../models/user_profile.dart';
import 'dart:ui' as ui;

/// Show Musician SOS BottomSheet
void showMusicianSOSBottomSheet(
  BuildContext context,
  UserProfile user,
  GeoPoint? userLocation,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (context) =>
        MusicianSOSBottomSheet(user: user, userLocation: userLocation),
  );
}

/// Show Pastor SOS BottomSheet
void showPastorSOSBottomSheet(
  BuildContext context,
  UserProfile user,
  GeoPoint? userLocation,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (context) =>
        PastorSOSBottomSheet(user: user, userLocation: userLocation),
  );
}

/// Main SOS Selection BottomSheet
void showSOSSelectionBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (context) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red.shade900.withValues(alpha: 0.95),
                Colors.red.shade700.withValues(alpha: 0.95),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emergency,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'SOS - L\'Armée du Salut',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Options
                Consumer(
                  builder: (context, ref, _) {
                    final currentUserAsync = ref.watch(
                      currentUserProfileProvider,
                    );
                    return currentUserAsync.when(
                      data: (user) {
                        if (user == null) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Veuillez vous connecter',
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            _buildSOSOption(
                              context,
                              icon: Icons.music_note,
                              title: 'Besoin d\'un Musicien',
                              subtitle: 'Trouvez un instrumentiste à proximité',
                              color: Colors.red,
                              onTap: () {
                                final navigatorContext = context;
                                Navigator.pop(navigatorContext);
                                Future.delayed(
                                  const Duration(milliseconds: 300),
                                  () async {
                                    if (navigatorContext.mounted) {
                                      _getUserLocationAndShow(
                                        navigatorContext,
                                        user,
                                        (location) {
                                          if (navigatorContext.mounted) {
                                            showMusicianSOSBottomSheet(
                                              navigatorContext,
                                              user,
                                              location,
                                            );
                                          }
                                        },
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                            _buildSOSOption(
                              context,
                              icon: Icons.church,
                              title: 'Besoin d\'un Homme de Dieu',
                              subtitle: 'Solicitez un Pasteur/Prêtre',
                              color: Colors.blue,
                              onTap: () {
                                final navigatorContext = context;
                                Navigator.pop(navigatorContext);
                                Future.delayed(
                                  const Duration(milliseconds: 300),
                                  () async {
                                    if (navigatorContext.mounted) {
                                      _getUserLocationAndShow(
                                        navigatorContext,
                                        user,
                                        (location) {
                                          if (navigatorContext.mounted) {
                                            showPastorSOSBottomSheet(
                                              navigatorContext,
                                              user,
                                              location,
                                            );
                                          }
                                        },
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      error: (_, __) => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Erreur de chargement',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildSOSOption(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _getUserLocationAndShow(
  BuildContext context,
  UserProfile user,
  Function(GeoPoint?) callback,
) async {
  try {
    final position = await Geolocator.getCurrentPosition();
    final location = GeoPoint(position.latitude, position.longitude);
    if (context.mounted) {
      callback(location);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de déterminer votre localisation'),
          backgroundColor: Colors.red,
        ),
      );
      callback(null);
    }
  }
}

/// Musician SOS Form BottomSheet
class MusicianSOSBottomSheet extends ConsumerStatefulWidget {
  final UserProfile user;
  final GeoPoint? userLocation;

  const MusicianSOSBottomSheet({
    super.key,
    required this.user,
    this.userLocation,
  });

  @override
  ConsumerState<MusicianSOSBottomSheet> createState() =>
      _MusicianSOSBottomSheetState();
}

class _MusicianSOSBottomSheetState extends ConsumerState<MusicianSOSBottomSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _programController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedInstrument = 'Pianiste';
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSending = false;
  bool _sendSMS = false;
  bool _isGettingAddress = false;

  final List<String> _instruments = [
    'Pianiste',
    'Batteur',
    'Chantre',
    'Guitariste',
    'Bassiste',
    'Saxophoniste',
    'Trompettiste',
    'Violoniste',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _programController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getAddressFromLocation() async {
    if (widget.userLocation == null) return;

    setState(() => _isGettingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        widget.userLocation!.latitude,
        widget.userLocation!.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.street != null && place.street!.isNotEmpty) {
          parts.add(place.street!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          parts.add(place.country!);
        }

        if (parts.isNotEmpty && mounted) {
          setState(() {
            _locationController.text = parts.join(', ');
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de récupérer l\'adresse'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingAddress = false);
      }
    }
  }

  Future<void> _sendSOS() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.userLocation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de déterminer votre localisation'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isSending = true);

    try {
      final sosService = ref.read(sosServiceProvider);
      final timeStr =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      await sosService.sendMusicianSOS(
        requesterId: widget.user.uid,
        requesterName: '${widget.user.firstName} ${widget.user.lastName}',
        instrumentType: _selectedInstrument,
        programType: _programController.text.trim(),
        time: timeStr,
        location: _locationController.text.trim(),
        userLocation: widget.userLocation!,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'SOS envoyé avec succès ! Les musiciens à proximité ont été alertés.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.red.shade900.withValues(alpha: 0.95),
                  const Color(0xFF190019).withValues(alpha: 0.98),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Besoin d\'un Musicien',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Instrument Selection
                            _buildGlassSection(
                              title: 'Type d\'instrumentiste',
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedInstrument,
                                items: _instruments
                                    .map(
                                      (inst) => DropdownMenuItem(
                                        value: inst,
                                        child: Text(inst),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedInstrument = val!),
                                dropdownColor: const Color(0xFF2B124C),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    Icons.music_note,
                                    color: Colors.red,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.white12,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.black12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Program Type
                            _buildGlassSection(
                              title: 'Type de programme',
                              child: TextFormField(
                                controller: _programController,
                                style: const TextStyle(color: Colors.white),
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Ce champ est requis'
                                    : null,
                                decoration: InputDecoration(
                                  labelText:
                                      'Ex: Programme de prière, Veillée, Concert...',
                                  labelStyle: const TextStyle(
                                    color: Colors.white54,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.event,
                                    color: Colors.red,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.white12,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.black12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Time
                            _buildGlassSection(
                              title: 'Heure',
                              child: GestureDetector(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: _selectedTime,
                                  );
                                  if (time != null) {
                                    setState(() => _selectedTime = time);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _selectedTime.format(context),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Location
                            _buildGlassSection(
                              title: 'Lieu exact',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _locationController,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          validator: (val) =>
                                              val == null || val.isEmpty
                                              ? 'Ce champ est requis'
                                              : null,
                                          maxLines: 2,
                                          decoration: InputDecoration(
                                            labelText:
                                                'Adresse complète du lieu',
                                            labelStyle: const TextStyle(
                                              color: Colors.white54,
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.location_on,
                                              color: Colors.red,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.white12,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.red,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.black12,
                                          ),
                                        ),
                                      ),
                                      if (widget.userLocation != null) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: _isGettingAddress
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.red,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.my_location,
                                                  color: Colors.red,
                                                ),
                                          onPressed: _isGettingAddress
                                              ? null
                                              : _getAddressFromLocation,
                                          tooltip:
                                              'Détecter l\'adresse automatiquement',
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (widget.userLocation != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'L\'adresse sera détectée automatiquement si le champ est vide',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // SMS Option
                            _buildGlassSection(
                              title: 'Options de notification',
                              child: CheckboxListTile(
                                value: _sendSMS,
                                onChanged: (val) =>
                                    setState(() => _sendSMS = val ?? false),
                                title: const Text(
                                  'Envoyer aussi par SMS',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  'Si disponible, envoie un SMS aux musiciens',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                                activeColor: Colors.red,
                                checkColor: Colors.white,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Send Button
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: const LinearGradient(
                                  colors: [Colors.red, Colors.redAccent],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.6),
                                    blurRadius: 25,
                                    spreadRadius: 3,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isSending ? null : _sendSOS,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: _isSending
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.send, color: Colors.white),
                                          SizedBox(width: 12),
                                          Text(
                                            'ENVOYER LE SOS',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
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
    );
  }

  Widget _buildGlassSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Pastor SOS Form BottomSheet
class PastorSOSBottomSheet extends ConsumerStatefulWidget {
  final UserProfile user;
  final GeoPoint? userLocation;

  const PastorSOSBottomSheet({
    super.key,
    required this.user,
    this.userLocation,
  });

  @override
  ConsumerState<PastorSOSBottomSheet> createState() =>
      _PastorSOSBottomSheetState();
}

class _PastorSOSBottomSheetState extends ConsumerState<PastorSOSBottomSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String _selectedNeedType = 'Consécration d\'enfant';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  bool _isSending = false;
  bool _sendSMS = false;
  bool _isGettingAddress = false;

  final List<String> _needTypes = [
    'Consécration d\'enfant',
    'Accompagnement spirituel',
    'Délivrance',
    'Bénédiction',
    'Mariage',
    'Funérailles',
    'Autre besoin spirituel',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getAddressFromLocation() async {
    if (widget.userLocation == null) return;

    setState(() => _isGettingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        widget.userLocation!.latitude,
        widget.userLocation!.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.street != null && place.street!.isNotEmpty) {
          parts.add(place.street!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          parts.add(place.country!);
        }

        if (parts.isNotEmpty && mounted) {
          setState(() {
            _locationController.text = parts.join(', ');
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de récupérer l\'adresse'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingAddress = false);
      }
    }
  }

  Future<void> _sendSOS() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.userLocation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de déterminer votre localisation'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isSending = true);

    try {
      final sosService = ref.read(sosServiceProvider);
      final dateStr = DateFormat('dd MMM yyyy', 'fr_FR').format(_selectedDate);

      await sosService.sendPastorSOS(
        requesterId: widget.user.uid,
        requesterName: '${widget.user.firstName} ${widget.user.lastName}',
        requesterPhone: widget.user.phone ?? '',
        needType: _selectedNeedType,
        date: dateStr,
        location: _locationController.text.trim(),
        userLocation: widget.userLocation!,
        sendSMS: _sendSMS,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'SOS envoyé avec succès ! Les Hommes de Dieu à proximité ont été alertés.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade900.withValues(alpha: 0.95),
                  const Color(0xFF190019).withValues(alpha: 0.98),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.church,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Besoin d\'un Homme de Dieu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Need Type
                            _buildGlassSection(
                              title: 'Type de besoin',
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedNeedType,
                                items: _needTypes
                                    .map(
                                      (need) => DropdownMenuItem(
                                        value: need,
                                        child: Text(need),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedNeedType = val!),
                                dropdownColor: const Color(0xFF2B124C),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    Icons.church,
                                    color: Colors.blue,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.white12,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.black12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Date
                            _buildGlassSection(
                              title: 'Date',
                              child: GestureDetector(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2030),
                                  );
                                  if (date != null) {
                                    setState(() => _selectedDate = date);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy',
                                          'fr_FR',
                                        ).format(_selectedDate),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Location
                            _buildGlassSection(
                              title: 'Lieu exact',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _locationController,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          validator: (val) =>
                                              val == null || val.isEmpty
                                              ? 'Ce champ est requis'
                                              : null,
                                          maxLines: 2,
                                          decoration: InputDecoration(
                                            labelText:
                                                'Adresse complète du lieu',
                                            labelStyle: const TextStyle(
                                              color: Colors.white54,
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.location_on,
                                              color: Colors.blue,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.white12,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.blue,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.black12,
                                          ),
                                        ),
                                      ),
                                      if (widget.userLocation != null) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: _isGettingAddress
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.blue,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.my_location,
                                                  color: Colors.blue,
                                                ),
                                          onPressed: _isGettingAddress
                                              ? null
                                              : _getAddressFromLocation,
                                          tooltip:
                                              'Détecter l\'adresse automatiquement',
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (widget.userLocation != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'L\'adresse sera détectée automatiquement si le champ est vide',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // SMS Option
                            _buildGlassSection(
                              title: 'Options de notification',
                              child: CheckboxListTile(
                                value: _sendSMS,
                                onChanged: (val) =>
                                    setState(() => _sendSMS = val ?? false),
                                title: const Text(
                                  'Envoyer aussi par SMS',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  'Si disponible, envoie un SMS aux Hommes de Dieu',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                                activeColor: Colors.blue,
                                checkColor: Colors.white,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Send Button
                            ScaleTransition(
                              scale: _pulseAnimation,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  gradient: const LinearGradient(
                                    colors: [Colors.blue, Colors.blueAccent],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withValues(alpha: 0.6),
                                      blurRadius: 25,
                                      spreadRadius: 3,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isSending ? null : _sendSOS,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: _isSending
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.send,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'ENVOYER LE SOS',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.5,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
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
    );
  }

  Widget _buildGlassSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
