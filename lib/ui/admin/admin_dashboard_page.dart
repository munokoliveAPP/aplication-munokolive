import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:confetti/confetti.dart'; // Import confetti
import 'package:munokolive_music/models/user_profile.dart';
import 'package:munokolive_music/models/event_model.dart';
import 'package:munokolive_music/models/place_model.dart';
import '../theme/app_theme.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ConfettiController _confettiController; // Controller for confetti
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = "";
  String _selectedFilter = "All"; // All, Active, Banned, Admin

  // System States
  bool _maintenanceMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _loadSystemSettings();
  }

  Future<void> _loadSystemSettings() async {
    try {
      final doc = await _firestore
          .collection('system_settings')
          .doc('config')
          .get();
      if (doc.exists) {
        setState(() {
          _maintenanceMode = doc.data()?['maintenance_mode'] ?? false;
        });
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // --- User Actions ---

  Future<void> _updateUserStatus(String uid, String status) async {
    try {
      await _firestore.collection('users').doc(uid).update({'status': status});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut utilisateur mis à jour: $status'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _rewardUser(String uid, int points) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'points': FieldValue.increment(points),
      });

      // Trigger Confetti
      _confettiController.play();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.stars, color: Colors.yellow),
                const SizedBox(width: 8),
                Text('$points points envoyés avec succès !'),
              ],
            ),
            backgroundColor: Colors.purple,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _deleteUser(String uid) async {
    // Dangerous action
    try {
      await _firestore.collection('users').doc(uid).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur supprimé'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  // --- Event Actions ---

  Future<void> _updateEventStatus(String eventId, String status) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'status': status,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Événement $status'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Événement supprimé'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  // --- Place Actions ---

  Future<void> _approvePlace(String placeId) async {
    try {
      await _firestore.collection('places').doc(placeId).update({
        'status': 'approved',
        'isVerified': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lieu approuvé et vérifié !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _rejectPlace(String placeId) async {
    try {
      await _firestore.collection('places').doc(placeId).update({
        'status': 'rejected',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lieu rejeté'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  // --- System Actions ---

  Future<void> _toggleMaintenance(bool value) async {
    try {
      await _firestore.collection('system_settings').doc('config').set({
        'maintenance_mode': value,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _maintenanceMode = value;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Mode Maintenance ACTIVÉ' : 'Mode Maintenance DÉSACTIVÉ',
            ),
            backgroundColor: value ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _sendBroadcast(String title, String message) async {
    try {
      await _firestore.collection('announcements').add({
        'title': title,
        'message': message,
        'created_at': FieldValue.serverTimestamp(),
        'type': 'global_alert',
      });

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annonce envoyée à tous les utilisateurs'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $error'), backgroundColor: Colors.red),
      );
    }
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'Centre de Contrôle',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.black.withValues(alpha: 0.7),
            elevation: 0,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.white60,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard), text: 'Vue Générale'),
                Tab(icon: Icon(Icons.people), text: 'Utilisateurs'),
                Tab(icon: Icon(Icons.event), text: 'Événements'),
                Tab(icon: Icon(Icons.place), text: 'Lieux'),
                Tab(icon: Icon(Icons.security), text: 'Sécurité'),
                Tab(icon: Icon(Icons.analytics), text: 'Analytique'),
              ],
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A1A), Colors.black],
              ),
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildEventsTab(),
                _buildPlacesTab(),
                _buildSecurityTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 120, 16, 0),
          child: Column(
            children: [
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Rechercher un utilisateur...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tous', 'All'),
                    _buildFilterChip('Actifs', 'active', color: Colors.green),
                    _buildFilterChip(
                      'En Attente',
                      'pending',
                      color: Colors.orange,
                    ),
                    _buildFilterChip(
                      'Admins',
                      'admin',
                      color: AppTheme.primaryColor,
                    ),
                    _buildFilterChip('Bannis', 'banned', color: Colors.red),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erreur: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Filter logic
              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = "${data['firstName']} ${data['lastName']}"
                    .toLowerCase();
                final matchesSearch = name.contains(_searchQuery);

                bool matchesFilter = true;
                if (_selectedFilter != 'All') {
                  if (_selectedFilter == 'admin') {
                    matchesFilter =
                        data['status'] == 'admin' ||
                        data['status'] == 'validated_admin';
                  } else {
                    matchesFilter = data['status'] == _selectedFilter;
                  }
                }

                return matchesSearch && matchesFilter;
              }).toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucun utilisateur trouvé',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              return AnimationLimiter(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final user = UserProfile.fromJson(
                      docs[index].data() as Map<String, dynamic>,
                    );
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(child: _buildUserTile(user)),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, {Color? color}) {
    final isSelected = _selectedFilter == value;
    final displayColor = color ?? Colors.white;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        selectedColor: displayColor.withValues(alpha: 0.2),
        checkmarkColor: displayColor,
        labelStyle: TextStyle(
          color: isSelected ? displayColor : Colors.white60,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(color: isSelected ? displayColor : Colors.transparent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildUserTile(UserProfile user) {
    Color statusColor = Colors.grey;
    if (user.status == 'active') statusColor = Colors.green;
    if (user.status == 'pending') statusColor = Colors.orange;
    if (user.status == 'banned') statusColor = Colors.red;
    if (user.status == 'admin') statusColor = AppTheme.primaryColor;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.photoUrl != null
              ? NetworkImage(user.photoUrl!)
              : null,
          child: user.photoUrl == null ? Text(user.firstName[0]) : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${user.firstName} ${user.lastName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (user.points > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, size: 12, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${user.points}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.category,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 11,
              ),
            ),
            Text(
              user.email ?? user.phone ?? 'Sans contact',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  user.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'validate') _updateUserStatus(user.uid, 'active');
            if (value == 'ban') _updateUserStatus(user.uid, 'banned');
            if (value == 'promote') _updateUserStatus(user.uid, 'admin');
            if (value == 'delete') _deleteUser(user.uid);
            if (value == 'reward') _showRewardDialog(user);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'validate',
              child: Row(
                children: [
                  Icon(Icons.check, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Valider'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'reward',
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber),
                  SizedBox(width: 8),
                  Text('Récompenser'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'promote',
              child: Row(
                children: [
                  Icon(Icons.star, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text('Promouvoir Admin'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'ban',
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Bannir'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRewardDialog(UserProfile user) {
    int selectedPoints = 50;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Récompenser ${user.firstName}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Combien de points souhaitez-vous attribuer ?',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPointOption(
                      10,
                      selectedPoints,
                      (val) => setState(() => selectedPoints = val),
                    ),
                    _buildPointOption(
                      50,
                      selectedPoints,
                      (val) => setState(() => selectedPoints = val),
                    ),
                    _buildPointOption(
                      100,
                      selectedPoints,
                      (val) => setState(() => selectedPoints = val),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '+ $selectedPoints Points',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  _rewardUser(user.uid, selectedPoints);
                  Navigator.pop(context);
                },
                child: const Text(
                  'ENVOYER',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPointOption(int value, int selectedValue, Function(int) onTap) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber
              : Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.amber : Colors.white24),
        ),
        child: Text(
          '$value',
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    return StatefulBuilder(
      builder: (context, setState) {
        String eventsFilter =
            'pending'; // 'pending', 'all', 'approved', 'rejected'
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 0),
              child: Column(
                children: [
                  // File d'attente améliorée avec statistiques
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('events')
                              .where('status', isEqualTo: 'pending')
                              .snapshots(),
                          builder: (context, snapshot) {
                            final pendingCount = snapshot.hasData
                                ? snapshot.data!.docs.length
                                : 0;
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.withValues(alpha: 0.2),
                                    Colors.orange.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha: 0.3,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.pending_actions,
                                      color: Colors.orange,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$pendingCount événements',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const Text(
                                        'en attente de validation',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Filtres améliorés
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildEventFilterChip(
                          'En attente',
                          'pending',
                          eventsFilter,
                          Colors.orange,
                          (val) {
                            setState(() => eventsFilter = val);
                          },
                        ),
                        _buildEventFilterChip(
                          'Tous',
                          'all',
                          eventsFilter,
                          Colors.blue,
                          (val) {
                            setState(() => eventsFilter = val);
                          },
                        ),
                        _buildEventFilterChip(
                          'Approuvés',
                          'approved',
                          eventsFilter,
                          Colors.green,
                          (val) {
                            setState(() => eventsFilter = val);
                          },
                        ),
                        _buildEventFilterChip(
                          'Rejetés',
                          'rejected',
                          eventsFilter,
                          Colors.red,
                          (val) {
                            setState(() => eventsFilter = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: eventsFilter == 'all'
                    ? _firestore
                          .collection('events')
                          .orderBy('date', descending: true)
                          .snapshots()
                    : _firestore
                          .collection('events')
                          .where('status', isEqualTo: eventsFilter)
                          .orderBy('date', descending: true)
                          .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            eventsFilter == 'pending'
                                ? 'Aucun événement en attente'
                                : 'Aucun événement trouvé',
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    );
                  }

                  // Trier pour afficher les pending en premier si filtre 'all'
                  final sortedDocs = eventsFilter == 'all'
                      ? (docs.toList()..sort((a, b) {
                          final aStatus = (a.data() as Map)['status'] ?? '';
                          final bStatus = (b.data() as Map)['status'] ?? '';
                          if (aStatus == 'pending' && bStatus != 'pending') {
                            return -1;
                          }
                          if (aStatus != 'pending' && bStatus == 'pending') {
                            return 1;
                          }
                          return 0;
                        }))
                      : docs.toList();

                  return AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedDocs.length,
                      itemBuilder: (context, index) {
                        final data =
                            sortedDocs[index].data() as Map<String, dynamic>;
                        data['id'] = sortedDocs[index].id;
                        final event = EventModel.fromJson(data);
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildEventTile(event),
                            ),
                          ),
                        );
                      },
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

  Widget _buildEventFilterChip(
    String label,
    String value,
    String selected,
    Color color,
    Function(String) onSelected,
  ) {
    final isSelected = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          onSelected(value);
        },
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        selectedColor: color.withValues(alpha: 0.3),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: isSelected ? color : Colors.white60,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildEventTile(EventModel event) {
    Color statusColor = Colors.grey;
    if (event.status == 'approved') statusColor = Colors.green;
    if (event.status == 'pending') statusColor = Colors.orange;
    if (event.status == 'rejected') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          if (event.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                event.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ListTile(
            title: Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.location,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        event.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${event.attendees.length} participants',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'approve') {
                  _updateEventStatus(event.id, 'approved');
                }
                if (value == 'reject') _updateEventStatus(event.id, 'rejected');
                if (value == 'delete') _deleteEvent(event.id);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'approve',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Approuver'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reject',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Rejeter'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacesTab() {
    return StatefulBuilder(
      builder: (context, setState) {
        String placesFilter =
            'pending'; // 'pending', 'all', 'approved', 'rejected'
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 0),
              child: Column(
                children: [
                  // File d'attente améliorée avec statistiques
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('places')
                              .where('status', isEqualTo: 'pending')
                              .snapshots(),
                          builder: (context, snapshot) {
                            final pendingCount = snapshot.hasData
                                ? snapshot.data!.docs.length
                                : 0;
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.withValues(alpha: 0.2),
                                    Colors.blue.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.pending_actions,
                                      color: Colors.blue,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$pendingCount lieux',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const Text(
                                        'en attente de validation',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Filtres améliorés
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPlaceFilterChip(
                          'En attente',
                          'pending',
                          placesFilter,
                          Colors.blue,
                          (val) {
                            setState(() => placesFilter = val);
                          },
                        ),
                        _buildPlaceFilterChip(
                          'Tous',
                          'all',
                          placesFilter,
                          Colors.purple,
                          (val) {
                            setState(() => placesFilter = val);
                          },
                        ),
                        _buildPlaceFilterChip(
                          'Approuvés',
                          'approved',
                          placesFilter,
                          Colors.green,
                          (val) {
                            setState(() => placesFilter = val);
                          },
                        ),
                        _buildPlaceFilterChip(
                          'Rejetés',
                          'rejected',
                          placesFilter,
                          Colors.red,
                          (val) {
                            setState(() => placesFilter = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: placesFilter == 'all'
                    ? _firestore
                          .collection('places')
                          .orderBy('createdAt', descending: true)
                          .snapshots()
                    : _firestore
                          .collection('places')
                          .where('status', isEqualTo: placesFilter)
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erreur: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            placesFilter == 'pending'
                                ? 'Aucun lieu en attente de validation'
                                : 'Aucun lieu trouvé',
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    );
                  }

                  return AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final place = PlaceModel.fromFirestore(docs[index]);
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildPlaceTile(place),
                            ),
                          ),
                        );
                      },
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

  Widget _buildPlaceFilterChip(
    String label,
    String value,
    String selected,
    Color color,
    Function(String) onSelected,
  ) {
    final isSelected = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          onSelected(value);
        },
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        selectedColor: color.withValues(alpha: 0.3),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: isSelected ? color : Colors.white60,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildPlaceTile(PlaceModel place) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          if (place.images.isNotEmpty)
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                image: DecorationImage(
                  image: NetworkImage(place.images.first),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ListTile(
            title: Text(
              place.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.categoryLabel,
                  style: const TextStyle(color: AppTheme.primaryColor),
                ),
                Text(
                  place.address,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  'Proposé par: ${place.ownerId}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _rejectPlace(place.id),
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text(
                    'Rejeter',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _approvePlace(place.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Valider'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeStats() {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return _buildStatCard(
                'Membres',
                count.toString(),
                Icons.people,
                Colors.purpleAccent,
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('events').snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return _buildStatCard(
                'Événements',
                count.toString(),
                Icons.event,
                Colors.tealAccent,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryAnalytics() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final docs = snapshot.data!.docs;
        int musicians = 0;
        int pastors = 0;
        int members = 0;
        int total = docs.length;

        if (total == 0) return const SizedBox();

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final category = data['category'] as String? ?? 'Membre';
          if (category == 'Musicien' || category == 'Chantre') {
            musicians++;
          } else if (category == 'Homme de Dieu' || category == 'Pasteur') {
            pastors++;
          } else {
            members++;
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildLegendItem('Musiciens', Colors.blue, musicians),
                  _buildLegendItem('Pasteurs', Colors.orange, pastors),
                  _buildLegendItem('Membres', Colors.green, members),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: [
                      if (musicians > 0)
                        Expanded(
                          flex: musicians,
                          child: Container(color: Colors.blue),
                        ),
                      if (pastors > 0)
                        Expanded(
                          flex: pastors,
                          child: Container(color: Colors.orange),
                        ),
                      if (members > 0)
                        Expanded(
                          flex: members,
                          child: Container(color: Colors.green),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isSwitch = false,
    bool switchValue = false,
    Function(bool)? onSwitchChanged,
  }) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        trailing: isSwitch
            ? Switch(
                value: switchValue,
                onChanged: onSwitchChanged,
                activeThumbColor: color,
              )
            : const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white38,
              ),
        onTap: isSwitch ? null : onTap,
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- STATS OVERVIEW ---
          const Text(
            "VUE D'ENSEMBLE",
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildRealTimeStats(),
          const SizedBox(height: 32),

          // --- ANALYTICS ---
          const Text(
            "RÉPARTITION",
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildCategoryAnalytics(),
          const SizedBox(height: 32),

          // --- PENDING QUEUES ---
          const Text(
            "FILES D'ATTENTE",
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('events')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;
                    return _buildStatCard(
                      'Événements en attente',
                      count.toString(),
                      Icons.event_available,
                      Colors.orange,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('places')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;
                    return _buildStatCard(
                      'Lieux en attente',
                      count.toString(),
                      Icons.place,
                      Colors.blue,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // --- TOOLS ---
          const Text(
            "OUTILS D'ADMINISTRATION",
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          _buildSettingsCard(
            'Mode Maintenance',
            'Bloquer l\'accès à l\'application pour tous',
            Icons.construction,
            Colors.orange,
            () {
              // Triggered by Switch
            },
            isSwitch: true,
            switchValue: _maintenanceMode,
            onSwitchChanged: _toggleMaintenance,
          ),
          _buildSettingsCard(
            'Annonce Globale',
            'Envoyer une notification à tous les membres',
            Icons.campaign,
            AppTheme.primaryColor,
            () {
              _showBroadcastDialog();
            },
          ),
          _buildSettingsCard(
            'Vider le Cache',
            'Optimiser les performances de l\'application',
            Icons.cleaning_services,
            Colors.blue,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache local vidé avec succès')),
              );
            },
          ),

          const SizedBox(height: 40),
          const Center(
            child: Column(
              children: [
                Icon(Icons.security, color: Colors.white10, size: 48),
                SizedBox(height: 8),
                Text(
                  'MunokoLive Admin System',
                  style: TextStyle(
                    color: Colors.white24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'v2.1.0 (Build 402)',
                  style: TextStyle(color: Colors.white12, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- MONITORING RADAR ---
          const Text(
            "MONITORING DES ACCÈS RADAR",
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('checkins')
                      .orderBy('timestamp', descending: true)
                      .limit(100)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;
                    return _buildStatCard(
                      'Check-ins récents',
                      count.toString(),
                      Icons.location_on,
                      Colors.purpleAccent,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('users')
                      .where('status', isEqualTo: 'banned')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;
                    return _buildStatCard(
                      'Utilisateurs bannis',
                      count.toString(),
                      Icons.block,
                      Colors.red,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // --- ACTIVITÉS RÉCENTES RADAR ---
          const Text(
            "ACTIVITÉS RADAR RÉCENTES",
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('checkins')
                .orderBy('timestamp', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Card(
                  color: Colors.white.withValues(alpha: 0.05),
                  child: const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'Aucune activité Radar récente',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: docs.take(15).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final userId = data['userId'] as String? ?? 'Inconnu';
                  final timestamp = data['timestamp'] as Timestamp?;
                  final location =
                      data['location'] as String? ?? 'Localisation inconnue';

                  return StreamBuilder<DocumentSnapshot>(
                    stream: _firestore
                        .collection('users')
                        .doc(userId)
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      String userName = 'Utilisateur inconnu';
                      String? userPhotoUrl;
                      if (userSnapshot.hasData && userSnapshot.data!.exists) {
                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>;
                        userName =
                            '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                                .trim();
                        if (userName.isEmpty) userName = 'Utilisateur $userId';
                        userPhotoUrl = userData['photoUrl'] as String?;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.purpleAccent.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purpleAccent.withValues(
                              alpha: 0.2,
                            ),
                            child: userPhotoUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      userPhotoUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.radar,
                                    color: Colors.purpleAccent,
                                    size: 20,
                                  ),
                          ),
                          title: Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: Colors.white54,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timestamp != null
                                    ? _formatTimestamp(timestamp.toDate())
                                    : 'Date inconnue',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.purpleAccent.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.radar,
                              color: Colors.purpleAccent,
                              size: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 32),

          // --- RAPPORTS DE COMPORTEMENT ---
          const Text(
            "RAPPORTS DE COMPORTEMENT",
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .where('status', whereIn: ['banned', 'pending'])
                .orderBy('status')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }
              final bannedDocs = snapshot.data!.docs
                  .where((doc) => (doc.data() as Map)['status'] == 'banned')
                  .toList();

              if (bannedDocs.isEmpty) {
                return Card(
                  color: Colors.white.withValues(alpha: 0.05),
                  child: const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'Aucun utilisateur banni',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: bannedDocs.take(10).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final user = UserProfile.fromJson(data);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.red.withValues(alpha: 0.1),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(user.firstName[0])
                            : null,
                      ),
                      title: Text(
                        '${user.firstName} ${user.lastName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Status: ${user.status.toUpperCase()}',
                        style: const TextStyle(color: Colors.red, fontSize: 11),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'unban') {
                            _updateUserStatus(user.uid, 'active');
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'unban',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Réactiver'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- STATISTIQUES DE PROXIMITÉ ---
          const Text(
            "STATISTIQUES DE PROXIMITÉ",
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    int activeUsers = 0;
                    if (snapshot.hasData) {
                      final now = DateTime.now();
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final lastActive = data['lastActive'] as Timestamp?;
                        if (lastActive != null) {
                          final diff = now.difference(lastActive.toDate());
                          if (diff.inHours < 24) activeUsers++;
                        }
                      }
                    }
                    return _buildStatCard(
                      'Utilisateurs actifs (24h)',
                      activeUsers.toString(),
                      Icons.people_outline,
                      Colors.greenAccent,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('checkins').snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;
                    return _buildStatCard(
                      'Total check-ins',
                      count.toString(),
                      Icons.location_history,
                      Colors.blueAccent,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // --- ZONES LES PLUS ACTIVES (HEATMAP) ---
          const Text(
            "ZONES LES PLUS ACTIVES (HEATMAP)",
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('checkins').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Calculer les zones les plus actives (par ville/quartier depuis les checkins)
              final docs = snapshot.data!.docs;
              final Map<String, int> zoneActivity = {};

              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final location = data['location'] as String? ?? 'Zone inconnue';
                zoneActivity[location] = (zoneActivity[location] ?? 0) + 1;
              }

              final sortedZones = zoneActivity.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              if (sortedZones.isEmpty) {
                return Card(
                  color: Colors.white.withValues(alpha: 0.05),
                  child: const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'Aucune donnée de zone disponible',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                );
              }

              final maxActivity = sortedZones.first.value;
              final topZones = sortedZones.take(10).toList();

              return Column(
                children: [
                  // Heatmap Visualization
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Légende de la heatmap
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Intensité d\'activité',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Faible',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.yellow.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Moyen',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Élevé',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Visualisation Heatmap avec grille
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: topZones.asMap().entries.map((entry) {
                            final index = entry.key;
                            final zone = entry.value;
                            final intensity = zone.value / maxActivity;

                            // Couleur basée sur l'intensité
                            Color heatColor;
                            if (intensity > 0.7) {
                              heatColor = Colors.red;
                            } else if (intensity > 0.4) {
                              heatColor = Colors.orange;
                            } else if (intensity > 0.2) {
                              heatColor = Colors.yellow;
                            } else {
                              heatColor = Colors.green;
                            }

                            final size = 50.0 + (intensity * 40);
                            final percentage = (zone.value / docs.length * 100)
                                .toStringAsFixed(1);

                            return Tooltip(
                              message:
                                  '${zone.key}\n${zone.value} check-ins\n$percentage%',
                              child: Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      heatColor.withValues(alpha: 0.8),
                                      heatColor.withValues(alpha: 0.3),
                                      heatColor.withValues(alpha: 0.1),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: heatColor.withValues(alpha: 0.5),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: size * 0.3,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Liste détaillée avec pourcentages améliorés
                  ...topZones.map((entry) {
                    final percentage = (entry.value / docs.length * 100)
                        .toStringAsFixed(1);
                    final intensity = entry.value / maxActivity;

                    Color barColor;
                    if (intensity > 0.7) {
                      barColor = Colors.red;
                    } else if (intensity > 0.4) {
                      barColor = Colors.orange;
                    } else if (intensity > 0.2) {
                      barColor = Colors.yellow;
                    } else {
                      barColor = Colors.green;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: barColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: barColor.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Text(
                                    '${entry.value} check-ins',
                                    style: TextStyle(
                                      color: barColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: intensity,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.1,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  barColor,
                                ),
                                minHeight: 10,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$percentage% de l\'activité totale',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: barColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // --- OPTIMISATION DES NOTIFICATIONS ---
          const Text(
            "OPTIMISATION DES NOTIFICATIONS",
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Recommandations',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('checkins').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox();
                      }

                      final totalCheckins = snapshot.data!.docs.length;
                      final now = DateTime.now();
                      final recentCheckins = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final timestamp = data['timestamp'] as Timestamp?;
                        if (timestamp == null) return false;
                        final diff = now.difference(timestamp.toDate());
                        return diff.inHours < 24;
                      }).length;

                      return Column(
                        children: [
                          _buildRecommendationItem(
                            'Activité récente (24h)',
                            '$recentCheckins check-ins',
                            recentCheckins > 10
                                ? 'Forte activité - Notifications recommandées'
                                : 'Activité modérée',
                            recentCheckins > 10 ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          _buildRecommendationItem(
                            'Activité totale',
                            '$totalCheckins check-ins',
                            totalCheckins > 100
                                ? 'Plateforme active'
                                : 'Croissance en cours',
                            Colors.blue,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
    String label,
    String value,
    String recommendation,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                recommendation,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  void _showBroadcastDialog() {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.campaign, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text('Nouvelle Annonce', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Titre',
                labelStyle: TextStyle(color: Colors.white60),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: msgCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message',
                labelStyle: TextStyle(color: Colors.white60),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && msgCtrl.text.isNotEmpty) {
                _sendBroadcast(titleCtrl.text, msgCtrl.text);
              }
            },
            child: const Text(
              'ENVOYER',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
