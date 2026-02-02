/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munokolive_music/providers/navigation_provider.dart';
import 'package:munokolive_music/ui/home/home_screen.dart';
import 'package:munokolive_music/ui/map/map_screen.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';
import 'package:munokolive_music/ui/widgets/offline_banner.dart';
import 'package:munokolive_music/providers/user_provider.dart';
import 'package:munokolive_music/ui/contacts/contacts_page.dart';
import 'package:munokolive_music/ui/places/places_page.dart';
import 'package:munokolive_music/ui/events/events_page.dart';

import 'package:munokolive_music/services/engagement_service.dart';
import 'package:munokolive_music/ui/chat/salon_chat_page.dart';
import 'package:munokolive_music/ui/profile/view_profile_page.dart';
import 'package:munokolive_music/providers/presence_provider.dart';
import 'package:munokolive_music/l10n/app_localizations.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _welcomeShown = false;

  @override
  void initState() {
    super.initState();
    // Initialize Global Presence Tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(presenceControllerProvider.notifier).init();
      // Initialize Engagement Engine (Notifications)
      ref.read(engagementEngineProvider);
    });
  }

  void _handleDeepLink(BuildContext context, DeepLinkTarget target) {
    if (target.type == 'salon') {
      final isMusicos = target.id == 'musicos';
      // Navigate to Salon
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SalonChatPage(
            salonId: target.id,
            salonTitle: isMusicos
                ? AppLocalizations.of(context)!.musiciansSalon
                : AppLocalizations.of(context)!.pastorsSalon,
            themeColor: isMusicos ? Colors.cyanAccent : Colors.amber,
          ),
        ),
      );
    } else if (target.type == 'message_prive') {
      // Navigate to User Profile or Chat (assuming ViewProfilePage has chat button)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewProfilePage(userId: target.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigation = ref.watch(navigationProvider);

    // Listen for Deep Links
    ref.listen<DeepLinkTarget?>(pendingNavigationProvider, (prev, next) {
      if (next != null) {
        _handleDeepLink(context, next);
        // Reset state
        ref.read(pendingNavigationProvider.notifier).state = null;
      }
    });

    // Welcome "Surprise" for Super Admin
    ref.listen(currentUserProfileProvider, (previous, next) {
      if (!_welcomeShown && next.hasValue && next.value != null) {
        final profile = next.value!;
        if (profile.role == 'admin' &&
            profile.email == 'munokolive@gmail.com') {
          _welcomeShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.welcomeSuperAdmin,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.amber[700],
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          });
        }
      }
    });

    final List<Widget> screens = [
      const HomeScreen(),
      const EventsPage(), // Events (New!)
      const MapScreen(), // Map/Radar
      const ContactsPage(), // Contacts
      const PlacesPage(), // Nos Lieux
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF2D0036), // Match image background
      extendBody: true, // Important for curved bar transparency effect
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: screens[navigation.currentIndex]),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: navigation.currentIndex,
        height: 75.0, // Hauteur ajustée pour la Safe Area et visibilité
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.event, size: 30, color: Colors.white),
          Icon(Icons.radar, size: 30, color: Colors.white),
          Icon(Icons.people_alt, size: 30, color: Colors.white),
          Icon(Icons.location_on, size: 30, color: Colors.white),
        ],
        color: const Color(
          0xFF1A0020,
        ).withValues(alpha: 0.9), // Plus opaque pour lisibilité
        buttonBackgroundColor: AppTheme.primaryColor,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) => navigation.setIndex(index),
        letIndexChange: (index) => true,
      ),
    );
  }
}
