/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:munokolive_music/providers/users_repository.dart';
import 'package:munokolive_music/ui/contacts/member_details_page.dart';
import 'package:munokolive_music/ui/settings/settings_page.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';
import 'package:munokolive_music/ui/widgets/cached_circle_avatar.dart';
import 'package:shimmer/shimmer.dart';

import 'package:munokolive_music/providers/presence_provider.dart';

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key});

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRoleFilter = "Tous"; // New Filter
  Position? _currentPosition; // For distance

  final List<String> _roleFilters = [
    "Tous",
    "Pasteur",
    "Chantre",
    "Instrumentiste",
    "Fidèle",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _currentPosition = pos);
    } catch (e) {
      // Ignore
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D0036), // Dark purple background
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Contacts & Membres",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white70, // Subtile
                      size: 24,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              tabs: const [
                Tab(text: "Tous les membres"),
                Tab(text: "Anniversaires"),
              ],
            ),
            const Divider(color: Colors.white10, height: 1),

            const SizedBox(height: 20),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor),
                  color: Colors.black.withValues(alpha: 0.2),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Rechercher un membre...",
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.search, color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Role Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _roleFilters.map((role) {
                  final isSelected = _selectedRoleFilter == role;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(role),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedRoleFilter = role);
                      },
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      selectedColor: AppTheme.primaryColor,
                      checkmarkColor: Colors.white,
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

            const SizedBox(height: 10),

            // List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMembersList(),
                  _buildBirthdaysList(), // Placeholder for now
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    final usersAsync = ref.watch(usersStreamProvider);
    final onlineUserIds = ref.watch(presenceControllerProvider);

    return usersAsync.when(
      loading: () => _buildShimmerLoading(),
      error: (err, stack) => Center(
        child: Text(
          "Erreur: $err",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      data: (users) {
        final filteredUsers = users.where((u) {
          // u is UserProfile
          // Only show users with completed profiles (photo is mandatory)
          final hasProfilePhoto = u.photoUrl != null && u.photoUrl!.isNotEmpty;
          if (!hasProfilePhoto) return false;

          final fullName = "${u.firstName} ${u.lastName}".toLowerCase();
          final category = (u.category).toLowerCase();
          final subCategory = (u.subCategory ?? "").toLowerCase();

          final matchesSearch = fullName.contains(_searchQuery.toLowerCase());

          bool matchesRole = true;
          if (_selectedRoleFilter != "Tous") {
            if (_selectedRoleFilter == "Pasteur") {
              matchesRole =
                  category.contains("homme de dieu") ||
                  subCategory.contains("pasteur");
            } else if (_selectedRoleFilter == "Chantre") {
              matchesRole =
                  category.contains("chantre") ||
                  subCategory.contains("chantre");
            } else if (_selectedRoleFilter == "Instrumentiste") {
              matchesRole =
                  category.contains("instrumentiste") ||
                  subCategory.contains("pianiste") ||
                  subCategory.contains("batteur");
            } else if (_selectedRoleFilter == "Fidèle") {
              matchesRole =
                  category.contains("fidèle") || category.contains("membre");
            }
          }

          return matchesSearch && matchesRole;
        }).toList();

        // SORTING: Online First, then Offline
        filteredUsers.sort((a, b) {
          final aOnline = onlineUserIds.contains(a.id);
          final bOnline = onlineUserIds.contains(b.id);
          if (aOnline && !bOnline) return -1;
          if (!aOnline && bOnline) return 1;
          return a.firstName.compareTo(b.firstName); // Fallback alphabetical
        });

        if (filteredUsers.isEmpty) {
          return const Center(
            child: Text(
              "Aucun membre trouvé",
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        // Count Stats
        final onlineCount = filteredUsers
            .where((u) => onlineUserIds.contains(u.id))
            .length;
        final offlineCount = filteredUsers.length - onlineCount;

        return Column(
          children: [
            // Online/Offline Stats Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _buildStatBadge(
                    "En ligne",
                    onlineCount,
                    Colors.greenAccent,
                    Icons.circle,
                  ),
                  const SizedBox(width: 12),
                  _buildStatBadge(
                    "Hors ligne",
                    offlineCount,
                    Colors.redAccent.withValues(alpha: 0.7),
                    Icons.circle_outlined,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredUsers.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  final name = "${user.firstName} ${user.lastName}";
                  final photoUrl = user.photoUrl;
                  final category = user.category;
                  final points = user.points;
                  final isOnline = onlineUserIds.contains(user.id);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MemberDetailsPage(
                            memberData: user.toJson(), // Compatibility for now
                            currentUserPosition: _currentPosition,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CachedCircleAvatar(
                                imageUrl: photoUrl,
                                radius: 24,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isOnline ? Colors.green : Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      if (isOnline)
                                        BoxShadow(
                                          color: Colors.greenAccent.withValues(
                                            alpha: 0.6,
                                          ),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        category, // e.g., Talent
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (user.subCategory != null) ...[
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          user.subCategory!, // e.g., Chantre
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
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
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  points.toString(),
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatBadge(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            "$label: $count",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 8,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.white.withValues(alpha: 0.05),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 24, backgroundColor: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 150, height: 14, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 100, height: 12, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBirthdaysList() {
    final usersAsync = ref.watch(usersStreamProvider);

    return usersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.pinkAccent),
      ),
      error: (err, stack) => Center(
        child: Text(
          "Erreur: $err",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      data: (users) {
        final today = DateTime.now();
        final tomorrow = today.add(const Duration(days: 1));

        final birthdayUsers = users.where((u) {
          if (u.birthDate == null) return false;
          final dob = u.birthDate!;
          // Check if birthday is today or tomorrow (ignoring year)
          final isToday = dob.month == today.month && dob.day == today.day;
          final isTomorrow =
              dob.month == tomorrow.month && dob.day == tomorrow.day;
          return isToday || isTomorrow;
        }).toList();

        if (birthdayUsers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cake, size: 60, color: Colors.white24),
                SizedBox(height: 16),
                Text(
                  "Aucun anniversaire aujourd'hui ou demain.",
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: birthdayUsers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final user = birthdayUsers[index];
            final dob = user.birthDate!;
            final isToday = dob.month == today.month && dob.day == today.day;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MemberDetailsPage(
                      memberData: user.toJson(),
                      currentUserPosition: _currentPosition,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isToday
                        ? [Colors.pinkAccent, Colors.purple]
                        : [Colors.white10, Colors.white10],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CachedCircleAvatar(imageUrl: user.photoUrl, radius: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${user.firstName} ${user.lastName}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            isToday
                                ? "C'est son anniversaire aujourd'hui ! 🎂"
                                : "C'est son anniversaire demain ! 🎈",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isToday) const Icon(Icons.cake, color: Colors.white),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
