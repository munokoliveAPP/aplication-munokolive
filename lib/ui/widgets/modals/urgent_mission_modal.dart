import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';
import 'package:munokolive_music/ui/widgets/smart_snackbar.dart';
import 'package:munokolive_music/models/urgent_request_model.dart';
import 'package:munokolive_music/providers/urgent_requests_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UrgentMissionModal extends ConsumerStatefulWidget {
  const UrgentMissionModal({super.key});

  @override
  ConsumerState<UrgentMissionModal> createState() => _UrgentMissionModalState();
}

class _UrgentMissionModalState extends ConsumerState<UrgentMissionModal>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  String? _selectedRole;
  String? _selectedMotive;
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _hoursCtrl = TextEditingController();
  final TextEditingController _budgetCtrl = TextEditingController();
  bool _isBenevolent = false;
  bool _useGeolocation = true;
  bool _isSubmitting = false;
  double _searchRadius = 100.0; // Default 100m

  // Animation State for Radar Scan
  bool _isScanning = false;
  late AnimationController _radarScanController;
  String _loadingStatus = '';

  // Data Lists
  final List<String> _musicianRoles = const [
    'Pianiste',
    'Batteur',
    'Chantre',
    'Bassiste',
    'Guitariste',
    'Choriste',
    'Technicien Son',
  ];
  final List<String> _pastorRoles = const [
    'Pasteur',
    'Apôtre',
    'Diacre',
    'Évangéliste',
    'Prophète',
    'Docteur',
  ];

  final List<String> _musicianMotives = const [
    'Concert',
    'Veillée',
    'Répétition',
    'Culte',
    'Studio',
  ];
  final List<String> _pastorMotives = const [
    'Mariage',
    'Baptême',
    'Célébration',
    'Soutien Spirituel',
    'Délivrance',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _radarScanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (!_useGeolocation) return;
    try {
      final position = await Geolocator.getCurrentPosition();
      // In a real app, we would reverse geocode this to an address
      // For now, we simulate a detected address
      if (mounted && _locationCtrl.text.isEmpty) {
        _locationCtrl.text = "${position.latitude}, ${position.longitude}";
      }
    } catch (e) {
      debugPrint("Loc error: $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _radarScanController.dispose();
    _locationCtrl.dispose();
    _hoursCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitMission() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null || _selectedMotive == null) {
      SmartSnackBar.show(
        context,
        message: "Veuillez sélectionner un rôle et un motif.",
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _isScanning = true;
      _loadingStatus = 'Activation du radar...';
    });

    _radarScanController.repeat();

    try {
      // 1. Create the request object
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("Non connecté");

      setState(() => _loadingStatus = 'Diffusion de l\'alerte...');

      final newRequest = UrgentRequest(
        id: '', // Will be ignored by DB or generated
        requesterId: user.id,
        roleNeeded: _selectedRole!,
        motive: _selectedMotive!,
        locationAddress: _locationCtrl.text,
        hoursDescription: _hoursCtrl.text,
        budgetRange: _budgetCtrl.text,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        locationLat: 0.0, // Placeholder, normally from geolocation
        locationLng: 0.0,
      );

      // 2. Send to Supabase via Repository
      await ref
          .read(urgentRequestsRepositoryProvider)
          .createRequest(newRequest);

      // 3. Success Animation
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isScanning = false;
        });
        _radarScanController.stop();

        Navigator.pop(context);

        // Bannière Orange Vif (Confirmation)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.deepOrangeAccent,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.yellowAccent, width: 2),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.broadcast_on_personal,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "SOS LANCÉ : ${_selectedRole?.toUpperCase()} RECHERCHÉ !",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        "Votre demande est diffusée aux musiciens alentours.",
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _isScanning = false;
      });
      _radarScanController.stop();
      if (mounted) {
        SmartSnackBar.show(
          context,
          message: "Erreur lors de l'envoi : $e",
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return _buildScanningView();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: const Color(
              0xFF1A0B2E,
            ).withValues(alpha: 0.85), // Glass Effect
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
          child: Column(
            children: [
              // Header Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Tabs with Golden/Silver Glyphs Logic
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    labelColor: Colors.amberAccent, // Golden Text
                    unselectedLabelColor: Colors.white60,
                    labelStyle: GoogleFonts.cinzel(
                      fontWeight: FontWeight.bold,
                    ), // Elegant Font
                    onTap: (index) {
                      setState(() {
                        _selectedRole = null;
                        _selectedMotive = null;
                      });
                    },
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_note,
                              size: 16,
                            ), // Placeholder for Glyph
                            SizedBox(width: 8),
                            Text("MUSICIEN"),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                            ), // Placeholder for Glyph
                            SizedBox(width: 8),
                            Text("MINISTRE"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Form Content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildMissionForm(
                        _musicianRoles,
                        _musicianMotives,
                        isMusician: true,
                      ),
                      _buildMissionForm(
                        _pastorRoles,
                        _pastorMotives,
                        isMusician: false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanningView() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1A0B2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Signal du Ciel (Laser Beam)
          Positioned(
            bottom: 0,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutExpo,
              builder: (context, value, child) {
                return Container(
                  width: 4 + (value * 20), // Starts thin, gets glowy
                  height: MediaQuery.of(context).size.height * 0.8 * value,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.cyanAccent,
                        Colors.cyanAccent.withValues(alpha: 0.0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withValues(alpha: 0.6),
                        blurRadius: 20 * value,
                        spreadRadius: 5 * value,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated Radar Circles
                    AnimatedBuilder(
                      animation: _radarScanController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _RadarScanPainter(
                            animationValue: _radarScanController.value,
                          ),
                          size: const Size(200, 200),
                        );
                      },
                    ),
                    // Center Icon
                    const Icon(
                      Icons.wifi_tethering,
                      color: Colors.cyanAccent,
                      size: 50,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  "RECHERCHE ACTIVE...",
                  style: GoogleFonts.oxanium(
                    color: Colors.cyanAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Diffusion ciblée : ${_selectedRole?.toUpperCase()}",
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  "Rayon : ${_searchRadius.toInt()}m",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionForm(
    List<String> roles,
    List<String> motives, {
    required bool isMusician,
  }) {
    final accentColor = isMusician ? Colors.cyanAccent : Colors.amberAccent;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        Text(
          "FICHE DE MISSION",
          style: GoogleFonts.oxanium(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),

        // 1. Role Selection
        _buildDropdown(
          label: "Recherche Spécifique",
          hint: isMusician
              ? "Ex: Pianiste, Batteur..."
              : "Ex: Pasteur, Apôtre...",
          items: roles,
          value: _selectedRole,
          onChanged: (val) => setState(() => _selectedRole = val),
          accentColor: accentColor,
        ),
        const SizedBox(height: 16),

        // 2. Motive Selection
        _buildDropdown(
          label: "Motif de la Mission",
          hint: "Sélectionnez le type d'événement",
          items: motives,
          value: _selectedMotive,
          onChanged: (val) => setState(() => _selectedMotive = val),
          accentColor: accentColor,
        ),
        const SizedBox(height: 16),

        // 2.5 Radius Slider
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Rayon de Diffusion",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  "${_searchRadius.toInt()}m",
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _searchRadius,
              min: 100,
              max: 1000,
              divisions: 9,
              label: "${_searchRadius.toInt()}m",
              activeColor: accentColor,
              inactiveColor: Colors.white24,
              onChanged: (val) => setState(() => _searchRadius = val),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 3. Location & Geo Switch
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _buildTextField(
                controller: _locationCtrl,
                label: "Lieu de la Mission",
                hint: "Adresse ou Ville",
                icon: Icons.location_on_outlined,
                accentColor: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Text(
                  "TRACKING",
                  style: TextStyle(
                    color: _useGeolocation ? accentColor : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _useGeolocation,
                  thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return accentColor;
                    }
                    return Colors.grey;
                  }),
                  trackColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return accentColor.withValues(alpha: 0.3);
                    }
                    return Colors.black26;
                  }),
                  onChanged: (val) {
                    setState(() => _useGeolocation = val);
                    if (val) _getCurrentLocation();
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 4. Hours
        _buildTextField(
          controller: _hoursCtrl,
          label: "Horaires / Durée",
          hint: "Ex: 20h - 23h (3h)",
          icon: Icons.access_time,
          accentColor: accentColor,
        ),
        const SizedBox(height: 16),

        // 5. Service Options (Budget)
        const Text(
          "Modalités de Service",
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: RadioGroup<bool>(
            groupValue: _isBenevolent,
            onChanged: (val) {
              if (val != null) setState(() => _isBenevolent = val);
            },
            child: Column(
              children: [
                RadioListTile<bool>(
                  title: const Text(
                    "Bénévolat (Service pour Dieu)",
                    style: TextStyle(color: Colors.white),
                  ),
                  value: true,
                  fillColor: WidgetStateProperty.all(accentColor),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<bool>(
                  title: const Text(
                    "Défraiement / Cachet",
                    style: TextStyle(color: Colors.white),
                  ),
                  value: false,
                  fillColor: WidgetStateProperty.all(accentColor),
                  contentPadding: EdgeInsets.zero,
                ),
                if (!_isBenevolent)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: TextFormField(
                      controller: _budgetCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Montant à débattre ou fixe (FCFA)",
                        hintStyle: const TextStyle(color: Colors.white30),
                        isDense: true,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: accentColor),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitMission,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: accentColor.withValues(alpha: 0.5),
            ),
            child: _isSubmitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.black),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _loadingStatus,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded),
                      const SizedBox(width: 8),
                      Text(
                        "LANCER L'APPEL",
                        style: GoogleFonts.oxanium(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value != null ? accentColor : Colors.white12,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint, style: const TextStyle(color: Colors.white30)),
              isExpanded: true,
              dropdownColor: const Color(0xFF2A1B3E),
              icon: Icon(Icons.keyboard_arrow_down, color: accentColor),
              items: items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          validator: (val) => val == null || val.isEmpty ? "Requis" : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            prefixIcon: Icon(
              icon,
              color: accentColor.withValues(alpha: 0.7),
              size: 20,
            ),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _RadarScanPainter extends CustomPainter {
  final double animationValue;

  _RadarScanPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw scanning circles
    for (int i = 0; i < 3; i++) {
      final radius =
          (animationValue * size.width / 2 + i * 40) % (size.width / 2);
      final opacity = 1.0 - (radius / (size.width / 2));

      paint.color = Colors.cyanAccent.withValues(alpha: opacity);
      canvas.drawCircle(center, radius, paint);
    }

    // Draw scanner line
    final angle = animationValue * 2 * 3.14159;
    final linePaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..shader = const LinearGradient(
        colors: [Colors.cyanAccent, Colors.transparent],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawLine(Offset.zero, Offset(0, size.width / 2), linePaint);

    // Draw sector
    final sectorPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: size.width / 2),
      -3.14159 / 2, // Start at top
      3.14159 / 4, // 45 degrees
      true,
      sectorPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RadarScanPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
