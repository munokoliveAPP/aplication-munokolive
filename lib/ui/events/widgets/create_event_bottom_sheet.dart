import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../../models/user_profile.dart';
import 'title_suggestions_widget.dart';
import 'location_picker_widget.dart';

class CreateEventBottomSheet extends ConsumerStatefulWidget {
  final UserProfile? user;

  const CreateEventBottomSheet({super.key, this.user});

  @override
  ConsumerState<CreateEventBottomSheet> createState() =>
      _CreateEventBottomSheetState();
}

class _CreateEventBottomSheetState
    extends ConsumerState<CreateEventBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  String _selectedCategory = 'Concert de Louange';
  bool _isCreating = false;
  GeoPoint? _selectedLocation;

  final List<String> _categories = [
    'Concert de Louange',
    'Soirée d\'Adoration',
    'Camp de Prière',
    'Croisade d\'Évangélisation',
    'Conférence Biblique',
    'Cinéma Gospel',
    'Festival de Musique',
    'Stand-up/Humour Chrétien',
    'Sortie Détente (Pique-nique)',
    'Atelier de Chant',
    'Masterclass Instrument',
    'Rencontre de Couples',
    'Forum Jeunesse',
    'Gala de Charité',
    'Don de Sang',
    'Action Sociale',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.user == null) return;

    setState(() => _isCreating = true);

    try {
      final date = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      final timeStr =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      await FirebaseFirestore.instance.collection('events').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'date': Timestamp.fromDate(date),
        'time': timeStr,
        'location': _locationController.text.trim(),
        'geoPoint': _selectedLocation,
        'creatorId': widget.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'attendees': [],
        'status': 'pending',
        'isValidated': false,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Annonce créée avec succès ! En attente de validation.',
            ),
            backgroundColor: Colors.green,
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
        setState(() => _isCreating = false);
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
                  const Color(0xFF2B124C).withValues(alpha: 0.95),
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
                            color: const Color(
                              0xFFDF00FF,
                            ).withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Nouvelle Divine Annonce',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
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
                            // Category Selection
                            _buildGlassSection(
                              title: 'Catégorie',
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedCategory,
                                items: _categories
                                    .map(
                                      (cat) => DropdownMenuItem(
                                        value: cat,
                                        child: Text(
                                          cat,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedCategory = val!),
                                dropdownColor: const Color(0xFF2B124C),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    Icons.category,
                                    color: Color(0xFFDF00FF),
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
                                      color: Color(0xFFDF00FF),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.black12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Title with Suggestions
                            _buildGlassSection(
                              title: 'Titre de l\'annonce',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _titleController,
                                    style: const TextStyle(color: Colors.white),
                                    validator: (val) =>
                                        val == null || val.isEmpty
                                        ? 'Titre requis'
                                        : null,
                                    decoration: InputDecoration(
                                      hintText: 'Ex: Grande Nuit de Louange',
                                      hintStyle: const TextStyle(
                                        color: Colors.white30,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.title,
                                        color: Color(0xFFDF00FF),
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
                                          color: Color(0xFFDF00FF),
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.black12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TitleSuggestionsWidget(
                                    category: _selectedCategory,
                                    titleController: _titleController,
                                    onSuggestionSelected: (title) {},
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Date & Time Row (REQUESTED FEATURE)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildGlassSection(
                                    title: 'Date',
                                    child: InkWell(
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
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.white12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              color: Color(0xFFDF00FF),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                DateFormat(
                                                  'dd/MM/yy',
                                                ).format(_selectedDate),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildGlassSection(
                                    title: 'Heure',
                                    child: InkWell(
                                      onTap: () async {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: _selectedTime,
                                        );
                                        if (time != null) {
                                          setState(() => _selectedTime = time);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.white12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              color: Color(0xFFDF00FF),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _selectedTime.format(context),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Location
                            _buildGlassSection(
                              title: 'Lieu',
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _locationController,
                                    style: const TextStyle(color: Colors.white),
                                    validator: (val) =>
                                        val == null || val.isEmpty
                                        ? 'Lieu requis'
                                        : null,
                                    decoration: InputDecoration(
                                      hintText: 'Adresse ou nom du lieu',
                                      hintStyle: const TextStyle(
                                        color: Colors.white30,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.location_on,
                                        color: Color(0xFFDF00FF),
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
                                          color: Color(0xFFDF00FF),
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.black12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Simplified location picker trigger
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => Dialog(
                                          backgroundColor: Colors.transparent,
                                          insetPadding: const EdgeInsets.all(
                                            16,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            child: SizedBox(
                                              height: 400,
                                              child: LocationPickerWidget(
                                                onLocationSelected:
                                                    (point, address) {
                                                      setState(() {
                                                        _selectedLocation =
                                                            point;
                                                        if (address != null) {
                                                          _locationController
                                                                  .text =
                                                              address;
                                                        }
                                                      });
                                                      Navigator.pop(context);
                                                    },
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.map,
                                      color: Color(0xFFDF00FF),
                                    ),
                                    label: const Text(
                                      'Choisir sur la carte',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Colors.white24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Description
                            _buildGlassSection(
                              title: 'Description',
                              child: TextFormField(
                                controller: _descriptionController,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: 'Détails de l\'événement...',
                                  hintStyle: const TextStyle(
                                    color: Colors.white30,
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
                                      color: Color(0xFFDF00FF),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.black12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            ElevatedButton(
                              onPressed: _isCreating ? null : _createEvent,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDF00FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                shadowColor: const Color(
                                  0xFFDF00FF,
                                ).withValues(alpha: 0.5),
                              ),
                              child: _isCreating
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'PUBLIER L\'ANNONCE',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
