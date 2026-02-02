/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
// import 'package:geocoding/geocoding.dart'; // Uncomment if geocoding is needed

class LocationPickerWidget extends StatefulWidget {
  final Function(String address, LatLng? coordinates) onLocationSelected;
  final String? initialLocation;

  const LocationPickerWidget({
    super.key,
    required this.onLocationSelected,
    this.initialLocation,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  final TextEditingController _controller = TextEditingController();
  LatLng? _selectedCoordinates;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _controller.text = widget.initialLocation!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pickLocation() async {
    // This is a placeholder for a real map picker navigation.
    // In a full implementation, this would navigate to a MapPage
    // where the user selects a point, and we reverse geocode it.
    
    // For now, we simulate a picker or just use the text field.
    // Let's show a dialog for manual entry or "Current Location" simulation.
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choisir un lieu"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Adresse ou nom du lieu",
                hintText: "Ex: Église Centrale, Paris",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Real-time updates if needed
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Simulate getting current location
                _controller.text = "Position actuelle (Simulée)";
                _selectedCoordinates = const LatLng(48.8566, 2.3522); // Paris
                setState(() {});
                widget.onLocationSelected(_controller.text, _selectedCoordinates);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.my_location),
              label: const Text("Utiliser ma position"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              widget.onLocationSelected(_controller.text, _selectedCoordinates);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text("Valider"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Lieu de l'événement",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickLocation,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.purpleAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _controller.text.isEmpty
                        ? "Appuyer pour choisir un lieu"
                        : _controller.text,
                    style: TextStyle(
                      color: _controller.text.isEmpty ? Colors.white38 : Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white38),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
