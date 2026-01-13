import 'package:flutter/material.dart'
    show
        Alignment,
        Animation,
        AnimationController,
        AppBar,
        BackdropFilter,
        Border,
        BorderRadius,
        BorderSide,
        BoxDecoration,
        BoxShadow,
        BuildContext,
        Center,
        CircularProgressIndicator,
        ClipRect,
        Color,
        Colors,
        Column,
        Container,
        CrossAxisAlignment,
        CurvedAnimation,
        Curves,
        DropdownButtonFormField,
        DropdownMenuItem,
        EdgeInsets,
        ElevatedButton,
        Expanded,
        FontWeight,
        Form,
        FormState,
        GestureDetector,
        GlobalKey,
        Icon,
        IconThemeData,
        Icons,
        InputDecoration,
        LinearGradient,
        MainAxisAlignment,
        Navigator,
        Offset,
        OutlineInputBorder,
        RoundedRectangleBorder,
        Row,
        SafeArea,
        Scaffold,
        ScaffoldMessenger,
        ScaleTransition,
        SingleChildScrollView,
        SingleTickerProviderStateMixin,
        SizedBox,
        SnackBar,
        Tab,
        TabBar,
        TabBarView,
        TabController,
        Text,
        TextAlign,
        TextEditingController,
        TextFormField,
        TextOverflow,
        TextStyle,
        TimeOfDay,
        Tween,
        Widget,
        debugPrint,
        showDatePicker,
        showTimePicker;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../providers/sos_provider.dart';
import '../../models/user_profile.dart';
import '../widgets/location_permission_banner.dart';
import '../theme/app_theme.dart';
import 'dart:ui' as ui;

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GeoPoint? _userLocation;
  bool _showPermissionBanner = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkPermissionAndLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionAndLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _showPermissionBanner = true);
      return;
    }

    await _getUserLocation();
  }

  Future<void> _requestPermission() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      if (mounted) setState(() => _showPermissionBanner = false);
      await _getUserLocation();
    }
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLocation = GeoPoint(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'SOS - L\'Armée du Salut',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.withValues(alpha: 0.9),
                    Colors.red.shade900.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.textPrimary,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.music_note), text: 'Besoin d\'un Musicien'),
            Tab(icon: Icon(Icons.church), text: 'Besoin d\'un Homme de Dieu'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade900.withValues(alpha: 0.3),
              AppTheme.backgroundDark,
            ],
          ),
        ),
        child: SafeArea(
          child: currentUserAsync.when(
            data: (user) {
              if (user == null) {
                return const Center(
                  child: Text(
                    'Veuillez vous connecter pour utiliser le SOS',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                );
              }

              return Column(
                children: [
                  if (_showPermissionBanner)
                    LocationPermissionBanner(
                      onRequestPermission: _requestPermission,
                    ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        MusicianSOSForm(
                          user: user,
                          userLocation: _userLocation,
                        ),
                        PastorSOSForm(user: user, userLocation: _userLocation),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.red),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Erreur: $err',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MusicianSOSForm extends ConsumerStatefulWidget {
  final UserProfile user;
  final GeoPoint? userLocation;

  const MusicianSOSForm({super.key, required this.user, this.userLocation});

  @override
  ConsumerState<MusicianSOSForm> createState() => _MusicianSOSFormState();
}

class _MusicianSOSFormState extends ConsumerState<MusicianSOSForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _programController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedInstrument = 'Pianiste';
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSending = false;

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

  Future<void> _sendSOS() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de déterminer votre localisation'),
          backgroundColor: Colors.red,
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'SOS envoyé avec succès ! Les musiciens à proximité ont été alertés.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.music_note,
                    size: 50,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Besoin d\'un Musicien',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lancez une alerte aux musiciens à proximité (10km)',
                    style: TextStyle(
                      color: AppTheme.textPrimary.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Instrument Selection
            _buildGlassSection(
              title: 'Type d\'instrumentiste',
              child: DropdownButtonFormField<String>(
                initialValue: _selectedInstrument,
                items: _instruments
                    .map(
                      (inst) =>
                          DropdownMenuItem(value: inst, child: Text(inst)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedInstrument = val!),
                dropdownColor: AppTheme.backgroundLight,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.music_note,
                    color: AppTheme.primaryColor,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.textSecondary.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryColor),
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundLight.withValues(alpha: 0.3),
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
                validator: (val) =>
                    val == null || val.isEmpty ? 'Ce champ est requis' : null,
                decoration: InputDecoration(
                  labelText: 'Ex: Programme de prière, Veillée, Concert...',
                  labelStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.event, color: Color(0xFFDF00FF)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDF00FF)),
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
                      const Icon(Icons.access_time, color: Color(0xFFDF00FF)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedTime.format(context),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
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
              child: TextFormField(
                controller: _locationController,
                style: const TextStyle(color: Colors.white),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Ce champ est requis' : null,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Adresse complète du lieu',
                  labelStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  filled: true,
                  fillColor: Colors.black12,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Send Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFF800080), Color(0xFFDF00FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDF00FF).withValues(alpha: 0.4),
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
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isSending
                    ? const CircularProgressIndicator(
                        color: AppTheme.textPrimary,
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, color: AppTheme.textPrimary),
                          SizedBox(width: 12),
                          Text(
                            'ENVOYER LE SOS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textPrimary.withValues(alpha: 0.1)),
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

class PastorSOSForm extends ConsumerStatefulWidget {
  final UserProfile user;
  final GeoPoint? userLocation;

  const PastorSOSForm({super.key, required this.user, this.userLocation});

  @override
  ConsumerState<PastorSOSForm> createState() => _PastorSOSFormState();
}

class _PastorSOSFormState extends ConsumerState<PastorSOSForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String _selectedNeedType = 'Consécration d\'enfant';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  bool _isSending = false;
  final bool _sendSMS = false;

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

  Future<void> _sendSOS() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de déterminer votre localisation'),
          backgroundColor: Colors.red,
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'SOS envoyé avec succès ! Les Hommes de Dieu à proximité ont été alertés.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2B124C).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFDF00FF).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.church, size: 50, color: Color(0xFFDF00FF)),
                  const SizedBox(height: 12),
                  const Text(
                    'Besoin d\'un Homme de Dieu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Solicitez un Pasteur/Prêtre pour un besoin spirituel',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Need Type
            _buildGlassSection(
              title: 'Type de besoin',
              child: DropdownButtonFormField<String>(
                initialValue: _selectedNeedType,
                items: _needTypes
                    .map(
                      (need) =>
                          DropdownMenuItem(value: need, child: Text(need)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedNeedType = val!),
                dropdownColor: const Color(0xFF2B124C),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.church,
                    color: Color(0xFFDF00FF),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDF00FF)),
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
                        color: Color(0xFFDF00FF),
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
              child: TextFormField(
                controller: _locationController,
                style: const TextStyle(color: Colors.white),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Ce champ est requis' : null,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Adresse complète du lieu',
                  labelStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  filled: true,
                  fillColor: Colors.black12,
                ),
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
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isSending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
            ),
          ],
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
              color: Color(0xFFDF00FF),
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
