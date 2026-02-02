/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:munokolive_music/models/location_model.dart';
import 'package:munokolive_music/providers/user_provider.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:munokolive_music/ui/widgets/smart_snackbar.dart';
import 'package:munokolive_music/ui/places/edit_place_page.dart';

class PlaceDetailsPage extends ConsumerStatefulWidget {
  final LocationModel location;
  final Position? userPosition;

  const PlaceDetailsPage({
    super.key,
    required this.location,
    this.userPosition,
  });

  @override
  ConsumerState<PlaceDetailsPage> createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends ConsumerState<PlaceDetailsPage> {
  late LocationModel _location;
  String _distanceInfo = "";
  String _timeInfo = "";
  int _currentImageIndex = 0; // For carousel dots
  Timer? _carouselTimer;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _location = widget.location;
    _calculateTravelInfo();
    _startCarousel();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startCarousel() {
    // Only start if we have more than 1 image (interior image exists)
    if (_location.interiorImageUrl != null) {
      _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_pageController.hasClients) {
          int nextPage = _pageController.page!.round() + 1;
          if (nextPage > 1) nextPage = 0;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Future<void> _editPlace() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPlacePage(location: _location),
      ),
    );

    if (result == true) {
      try {
        final updatedData = await Supabase.instance.client
            .from('locations')
            .select()
            .eq('id', _location.id)
            .single();

        if (mounted) {
          setState(() {
            _location = LocationModel.fromJson(updatedData);
            _calculateTravelInfo();
          });
        }
      } catch (e) {
        if (mounted) {
          SmartSnackBar.show(
            context,
            message: "Erreur lors de l'actualisation : $e",
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _deletePlace() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D0036),
        title: const Text(
          "Supprimer ce lieu ?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Cette action est irréversible. Seul un Super Administrateur peut faire cela.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('locations')
            .delete()
            .eq('id', _location.id);

        if (mounted) {
          Navigator.pop(context); // Close details
          SmartSnackBar.show(
            context,
            message: "Lieu supprimé avec succès",
            isSuccess: true,
          );
        }
      } catch (e) {
        if (mounted) {
          SmartSnackBar.show(context, message: "Erreur: $e", isError: true);
        }
      }
    }
  }

  void _calculateTravelInfo() {
    if (widget.userPosition != null &&
        _location.latitude != null &&
        _location.longitude != null) {
      final distanceInMeters = Geolocator.distanceBetween(
        widget.userPosition!.latitude,
        widget.userPosition!.longitude,
        _location.latitude!,
        _location.longitude!,
      );

      // Distance formatting
      if (distanceInMeters < 1000) {
        _distanceInfo = "${distanceInMeters.toStringAsFixed(0)} m";
      } else {
        _distanceInfo = "${(distanceInMeters / 1000).toStringAsFixed(1)} km";
      }

      // Time estimation (Heuristic)
      // Walking: 5 km/h (~83 m/min)
      // Driving: 40 km/h (~666 m/min) average city
      if (distanceInMeters < 1000) {
        final minutes = (distanceInMeters / 83).ceil();
        _timeInfo = "$minutes min à pied";
      } else {
        final minutes = (distanceInMeters / 666).ceil();
        _timeInfo = "$minutes min en voiture";
      }
    }
  }

  Future<void> _launchMaps() async {
    if (_location.latitude != null && _location.longitude != null) {
      final googleMapsUrl = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=${_location.latitude},${_location.longitude}",
      );
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          SmartSnackBar.show(
            context,
            message: "Impossible d'ouvrir la carte",
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E0024),
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E0024),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _location.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentImageIndex = index),
                    children: [
                      // Exterior Image
                      _location.imageUrl != null
                          ? Hero(
                              tag: 'place-img-${_location.id}',
                              child: CachedNetworkImage(
                                imageUrl: _location.imageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(color: Colors.grey[900]),

                      // Interior Image (if available)
                      if (_location.interiorImageUrl != null)
                        CachedNetworkImage(
                          imageUrl: _location.interiorImageUrl!,
                          fit: BoxFit.cover,
                        ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                  // Dots Indicator
                  if (_location.interiorImageUrl != null)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDot(0),
                          const SizedBox(width: 8),
                          _buildDot(1),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Details Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Validation Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryColor),
                        ),
                        child: Text(
                          _location.category,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_location.isValidated)
                        const Chip(
                          avatar: Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 16,
                          ),
                          label: Text(
                            "Vérifié",
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.green,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Smart Distance Card
                  if (_distanceInfo.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade900.withValues(alpha: 0.4),
                            Colors.purple.shade900.withValues(alpha: 0.4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.near_me,
                            color: Colors.lightBlueAccent,
                            size: 30,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "À $_distanceInfo de vous",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "Environ $_timeInfo",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Info Section
                  _buildInfoRow(
                    Icons.location_on,
                    "Adresse",
                    _location.address ?? "Non spécifiée",
                  ),
                  if (_location.responsibleName != null &&
                      _location.responsibleName!.isNotEmpty)
                    _buildInfoRow(
                      Icons.person,
                      "Responsable",
                      _location.responsibleName!,
                    ),
                  if (_location.contactPhone != null &&
                      _location.contactPhone!.isNotEmpty)
                    _buildInfoRow(
                      Icons.phone,
                      "Contact",
                      _location.contactPhone!,
                    ),

                  const SizedBox(height: 30),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _launchMaps,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 10,
                        shadowColor: AppTheme.primaryColor.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      icon: const Icon(Icons.directions, color: Colors.white),
                      label: const Text(
                        "Y ALLER MAINTENANT",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Admin / Creator Actions
                  Consumer(
                    builder: (context, ref, child) {
                      final currentUser = ref.watch(userProfileProvider).value;
                      final isSuperAdmin = currentUser?.role == 'super_admin';
                      final isCreator =
                          currentUser?.id == _location.submittedById;

                      if (!isSuperAdmin && !isCreator) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        children: [
                          if (isCreator)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _editPlace,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orangeAccent,
                                    side: const BorderSide(
                                      color: Colors.orangeAccent,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(Icons.edit),
                                  label: const Text("MODIFIER CE LIEU"),
                                ),
                              ),
                            ),

                          if (isSuperAdmin)
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Center(
                                child: TextButton.icon(
                                  onPressed: _deletePlace,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    backgroundColor: Colors.red.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(Icons.delete_forever),
                                  label: const Text("SUPPRIMER (Super Admin)"),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _currentImageIndex == index ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: _currentImageIndex == index
            ? AppTheme.primaryColor
            : Colors.white.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
