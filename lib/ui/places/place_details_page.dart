import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';
import 'package:munokolive_music/models/place_model.dart';
import 'package:munokolive_music/providers/app_state_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/cached_image_widget.dart';
import '../../services/analytics_service.dart';
import '../widgets/favorite_button.dart';
import '../../models/favorite_model.dart';
import '../../services/gamification_service.dart';
import '../../providers/user_provider.dart';

class PlaceDetailsPage extends ConsumerStatefulWidget {
  final PlaceModel place;

  const PlaceDetailsPage({super.key, required this.place});

  @override
  ConsumerState<PlaceDetailsPage> createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends ConsumerState<PlaceDetailsPage> {
  bool _hasCheckedIn = false;

  void _handleShare() {
    // ignore: deprecated_member_use
    Share.share(
      'Découvrez ${widget.place.name} sur MunokoLive ! ${widget.place.address}, ${widget.place.city}. Téléchargez l\'app maintenant !',
      subject: 'Découverte : ${widget.place.name}',
    );

    // Gamification reward for sharing
    final user = ref.read(userProfileProvider).value;
    if (user != null) {
      ref
          .read(gamificationServiceProvider)
          .awardPoints(user.uid, 5, reason: 'share_place');
    }
  }

  void _handleCheckIn() {
    setState(() {
      _hasCheckedIn = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Check-in réussi ! +10 points'),
        backgroundColor: Colors.green,
      ),
    );

    // Gamification reward for check-in
    final user = ref.read(userProfileProvider).value;
    if (user != null) {
      ref
          .read(gamificationServiceProvider)
          .awardPoints(user.uid, 10, reason: 'check_in');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logPlaceViewed(widget.place.id);
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header Image with 360/Virtual Tour Hint
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            actions: [
              FavoriteButton(
                type: FavoriteType.place,
                itemId: widget.place.id,
                metadata: {
                  'name': widget.place.name,
                  'city': widget.place.city,
                  'neighborhood': widget.place.neighborhood,
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.place.images.isNotEmpty)
                    CachedImageWidget(
                      imageUrl: widget.place.images.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  else
                    Container(color: Colors.grey),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.backgroundDark.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),

                  // Virtual Tour Badge (Functionality "Surprise")
                  Positioned(
                    top: 50,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenGallery(
                              images: widget.place.images,
                              initialIndex: 0,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.secondaryColor),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.secondaryColor.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.threed_rotation,
                              color: AppTheme.secondaryColor,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Visite 360° / Galerie",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                widget.place.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.backgroundDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges & Category
                  Row(
                    children: [
                      if (widget.place.isVerified)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blueAccent),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.verified,
                                color: Colors.blueAccent,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Vérifié",
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryColor),
                        ),
                        child: Text(
                          widget.place.categoryLabel,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    widget.place.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Heatmap / Popularity (Surprise Feature)
                  _buildHeatmapIndicator(),
                  const SizedBox(height: 24),

                  // Location Info
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white54,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${widget.place.address}, ${widget.place.city}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white54, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Géré par : ${widget.place.ownerName}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Action Buttons (Action-Oriented Design)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            if (widget.place.coordinates != null) {
                              // Sync with Radar
                              ref
                                  .read(mapFocusLocationProvider.notifier)
                                  .state = LatLng(
                                widget.place.coordinates!.latitude,
                                widget.place.coordinates!.longitude,
                              );
                              ref.read(bottomNavIndexProvider.notifier).state =
                                  1; // Go to Radar
                              Navigator.pop(
                                context,
                              ); // Close details to show map
                            }
                          },
                          icon: const Icon(
                            Icons.directions,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "S'y rendre",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(
                              color: AppTheme.secondaryColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () =>
                              _makePhoneCall(widget.place.contactPhone),
                          icon: const Icon(
                            Icons.phone,
                            color: AppTheme.secondaryColor,
                          ),
                          label: const Text(
                            "Appeler",
                            style: TextStyle(color: AppTheme.secondaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Social & Gamification Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _handleShare,
                          icon: const Icon(
                            Icons.share_outlined,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Partager",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (!_hasCheckedIn)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _handleCheckIn,
                            icon: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Check-in",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Validé",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Mini Map Preview
                  if (widget.place.coordinates != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              widget.place.coordinates!.latitude,
                              widget.place.coordinates!.longitude,
                            ),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId(widget.place.id),
                              position: LatLng(
                                widget.place.coordinates!.latitude,
                                widget.place.coordinates!.longitude,
                              ),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueViolet,
                              ),
                            ),
                          },
                          zoomControlsEnabled: false,
                          scrollGesturesEnabled: false,
                        ),
                      ),
                    ),

                  const SizedBox(height: 100), // Spacing for bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapIndicator() {
    // "Heatmap de Disponibilité" - Mock logic based on "random" or real data if available
    // For now, let's pretend it's calculated based on nearby users (which we could get from providers if we wanted)
    bool isBusy = DateTime.now().minute % 2 == 0; // Randomize for demo

    return GlassmorphicContainer(
      width: double.infinity,
      height: 60,
      borderRadius: 12,
      blur: 10,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.01),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.05),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              isBusy ? Icons.local_fire_department : Icons.spa,
              color: isBusy ? Colors.orange : Colors.greenAccent,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isBusy ? "Actuellement Populaire" : "Ambiance Calme",
                  style: TextStyle(
                    color: isBusy ? Colors.orange : Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isBusy
                      ? "Beaucoup de membres à proximité"
                      : "Idéal pour se concentrer",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenGallery({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: CachedImageWidget(
                    imageUrl: widget.images[index],
                    fit: BoxFit.contain,
                    placeholder: Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                    errorWidget: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${_currentIndex + 1} / ${widget.images.length}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
