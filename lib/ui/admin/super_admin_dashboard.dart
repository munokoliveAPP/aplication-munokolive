/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munokolive_music/models/user_profile.dart';
import 'package:munokolive_music/providers/user_provider.dart';
import 'package:munokolive_music/ui/widgets/smart_snackbar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:munokolive_music/providers/admin_dashboard_provider.dart';

import 'package:munokolive_music/models/urgent_request_model.dart';
import 'package:munokolive_music/providers/urgent_requests_provider.dart';
import 'package:munokolive_music/ui/widgets/buttons/urgent_pulse_button.dart';

class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  ConsumerState<SuperAdminDashboard> createState() =>
      _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = Supabase.instance.client;

  // Config Controllers
  final TextEditingController _radiusCtrl = TextEditingController();
  final TextEditingController _aiMessageCtrl = TextEditingController();
  final TextEditingController _userSearchCtrl = TextEditingController();
  final TextEditingController _locationSearchCtrl =
      TextEditingController(); // Added
  String _userSearchTerm = '';
  String _locationSearchTerm = ''; // Added
  bool _maintenanceMode = false;
  bool _isLoadingConfig = false;
  String _validationType = 'users'; // 'users', 'places', 'events'

  StreamSubscription<List<Map<String, dynamic>>>? _configSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
    ); // Changed length to 6
    _setupConfigStream();
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    _tabController.dispose();
    _radiusCtrl.dispose();
    _aiMessageCtrl.dispose();
    _userSearchCtrl.dispose();
    _locationSearchCtrl.dispose(); // Added
    super.dispose();
  }

  void _setupConfigStream() {
    _configSubscription = supabase
        .from('app_config')
        .stream(primaryKey: ['id'])
        .eq('id', 1)
        .listen(
          (data) {
            if (data.isNotEmpty) {
              final config = data.first;
              if (mounted) {
                setState(() {
                  _maintenanceMode = config['maintenance_mode'] ?? false;
                  // Only update text controllers if not focused to avoid interrupting typing?
                  // For admin dashboard, usually one person edits. But let's be safe.
                  // Actually, if I type and it updates, it resets cursor.
                  // But this is for "viewing" updates.
                  // If I am the one editing, I don't want it to reset my text while I type.
                  // Simple check: if text is different and we are not editing (hard to know).
                  // For now, let's update it. If it's annoying, we can check focus.
                  if (_radiusCtrl.text !=
                      (config['radar_radius'] ?? 5000).toString()) {
                    _radiusCtrl.text = (config['radar_radius'] ?? 5000)
                        .toString();
                  }
                  if (_aiMessageCtrl.text != (config['ai_message'] ?? '')) {
                    _aiMessageCtrl.text = config['ai_message'] ?? '';
                  }
                });
              }
            }
          },
          onError: (e) {
            debugPrint("Error streaming config: $e");
          },
        );
  }

  Future<void> _saveConfigToSupabase() async {
    await supabase
        .from('app_config')
        .update({
          'maintenance_mode': _maintenanceMode,
          'radar_radius': int.tryParse(_radiusCtrl.text) ?? 5000,
          'ai_message': _aiMessageCtrl.text,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', 1);
  }

  Future<void> _updateConfig() async {
    setState(() => _isLoadingConfig = true);
    try {
      await _saveConfigToSupabase();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Configuration mise à jour"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoadingConfig = false);
    }
  }

  // NOTE: Logic moved to AdminActionNotifier

  Future<void> _cleanupDatabase({
    bool deleteEvents = false,
    bool deleteUsers = false,
  }) async {
    try {
      int deletedCount = 0;

      // 1. Supprimer les événements passés (+7 jours)
      if (deleteEvents) {
        final dateThreshold = DateTime.now().subtract(const Duration(days: 7));
        await supabase
            .from('events')
            .delete()
            .lt('event_date', dateThreshold.toIso8601String());
        // Note: Supabase doesn't return count on delete easily without select, assuming success
        deletedCount += 1; // Dummy increment
      }

      // 2. Supprimer les utilisateurs non validés (+30 jours) -> Comptes fantômes
      if (deleteUsers) {
        final dateThreshold = DateTime.now().subtract(const Duration(days: 30));
        await supabase
            .from('users')
            .delete()
            .eq('is_validated', false)
            .lt('created_at', dateThreshold.toIso8601String());
        deletedCount += 1;
      }

      // Use deletedCount to avoid warning
      debugPrint("Deleted batches count: $deletedCount");

      if (mounted) {
        SmartSnackBar.show(
          context,
          message: "Nettoyage intelligent terminé avec succès !",
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        SmartSnackBar.show(
          context,
          message: "Erreur nettoyage: $e",
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    _confirmDelete(
      context,
      "Supprimer cet utilisateur ?",
      "Cette action est irréversible et supprimera le compte ainsi que toutes les données associées.",
      () async {
        // Use Riverpod Action
        await ref
            .read(adminActionProvider.notifier)
            .deleteUser(context, userId);
      },
    );
  }

  Future<void> _deleteLocation(String locationId) async {
    _confirmDelete(
      context,
      "Supprimer ce lieu ?",
      "Cette action est irréversible.",
      () async {
        // Use Riverpod Action (reusing validateLocation for deletion via false)
        await ref
            .read(adminActionProvider.notifier)
            .validateLocation(context, locationId: locationId, isValid: false);
      },
    );
  }

  bool _isOptimisticallyHidden(String id) {
    // Check if the item is in the pending actions state
    final hiddenIds = ref.watch(adminActionProvider);
    return hiddenIds.contains(id);
  }

  // --- UI Components ---
  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        return Shimmer.fromColors(
          baseColor: Colors.white.withValues(alpha: 0.05),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Super Admin Dashboard"),
        backgroundColor: Colors.grey[900],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.verified_user), text: "Validation"),
            Tab(
              icon: Icon(Icons.cleaning_services),
              text: "Gestion & Nettoyage",
            ), // New Tab
            Tab(icon: Icon(Icons.person_search), text: "Utilisateurs"),
            Tab(icon: Icon(Icons.settings), text: "Config App"),
            Tab(icon: Icon(Icons.bug_report), text: "Console Debug"),
            Tab(icon: Icon(Icons.sos), text: "SOS Live"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildValidationTab(),
          _buildManagementTab(), // New Tab Body
          _buildUserSearchTab(),
          _buildConfigTab(),
          _buildDebugTab(),
          _buildSosLiveTab(),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm,
  ) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text(
              "SUPPRIMER",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. Validation Tab ---
  Widget _buildValidationTab() {
    return Column(
      children: [
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildFilterChip('users', 'Membres'),
              const SizedBox(width: 8),
              _buildFilterChip('places', 'Lieux Sacrés'),
              const SizedBox(width: 8),
              _buildFilterChip('events', 'Événements'),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _validationType == 'users'
              ? _buildUserValidationList()
              : _validationType == 'places'
              ? _buildPlaceValidationList()
              : _buildEventValidationList(),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _validationType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _validationType = value);
        }
      },
      selectedColor: Colors.purpleAccent,
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _showUserDetails(BuildContext context, UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          "${user.firstName} ${user.lastName}",
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user.photoUrl != null)
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(user.photoUrl!),
                  ),
                ),
              const SizedBox(height: 16),
              _buildDetailRow("Email", user.email),
              _buildDetailRow("Téléphone", user.phoneNumber),
              _buildDetailRow("Catégorie", user.category),
              _buildDetailRow("Sous-catégorie", user.subCategory),
              _buildDetailRow("Église", user.churchName),
              const Divider(color: Colors.white24),
              _buildDetailRow("Ville", user.city),
              _buildDetailRow("Commune", user.commune),
              _buildDetailRow("Quartier", user.neighborhood),
              _buildDetailRow("Code Parrainage", user.referralCode),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white70),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildUserValidationList() {
    // Watch StreamProvider
    final asyncUsers = ref.watch(pendingUsersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        // StreamProvider handles refresh automatically on reconnect,
        // but we can force refresh if needed.
        return ref.refresh(pendingUsersProvider.future);
      },
      child: asyncUsers.when(
        data: (users) {
          // Filter optimistically hidden items
          final visibleUsers = users
              .where((u) => !_isOptimisticallyHidden(u.id))
              .toList();

          if (visibleUsers.isEmpty) {
            return Center(
              child: Text(
                "Aucun membre en attente",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: visibleUsers.length,
            itemBuilder: (context, index) {
              final user = visibleUsers[index];
              return _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 12),
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
                                "${user.category} • ${user.subCategory ?? ''}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (user.churchName != null)
                      Text(
                        "Église: ${user.churchName}",
                        style: const TextStyle(color: Colors.white54),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showUserDetails(context, user),
                          icon: const Icon(
                            Icons.visibility,
                            size: 16,
                            color: Colors.blueAccent,
                          ),
                          label: const Text(
                            "VOIR PROFIL",
                            style: TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => ref
                              .read(adminActionProvider.notifier)
                              .validateUser(
                                context,
                                userId: user.id,
                                isValid: false,
                              ),
                          child: const Text(
                            "REJETER",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Validation avec Rôle (Unifié)
                        ElevatedButton.icon(
                          onPressed: () => _showValidationDialog(context, user),
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text("VALIDER"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _showValidationDialog(BuildContext context, UserProfile user) {
    String selectedRole = 'user'; // Default
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.verified_user, color: Colors.greenAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Valider ${user.firstName} ?",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Attribuer un rôle :",
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildRoleOption(
                title: "Membre (Défaut)",
                value: 'user',
                groupValue: selectedRole,
                onChanged: (val) => setState(() => selectedRole = val!),
                icon: Icons.person,
                color: Colors.blue,
              ),
              _buildRoleOption(
                title: "Artiste / Musicien",
                value: 'artist',
                groupValue: selectedRole,
                onChanged: (val) => setState(() => selectedRole = val!),
                icon: Icons.music_note,
                color: Colors.purple,
              ),
              _buildRoleOption(
                title: "Organisateur",
                value: 'organizer',
                groupValue: selectedRole,
                onChanged: (val) => setState(() => selectedRole = val!),
                icon: Icons.event,
                color: Colors.orange,
              ),
              _buildRoleOption(
                title: "Modérateur",
                value: 'moderator',
                groupValue: selectedRole,
                onChanged: (val) => setState(() => selectedRole = val!),
                icon: Icons.shield,
                color: Colors.teal,
              ),
              const Divider(color: Colors.white24),
              _buildRoleOption(
                title: "Administrateur",
                value: 'admin',
                groupValue: selectedRole,
                onChanged: (val) => setState(() => selectedRole = val!),
                icon: Icons.security,
                color: Colors.redAccent,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(adminActionProvider.notifier).validateUser(
                  context,
                  userId: user.id,
                  isValid: true,
                  role: selectedRole,
                );
              },
              child: const Text("CONFIRMER VALIDATION"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? color : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 20, color: isSelected ? color : Colors.white54),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceValidationList() {
    final asyncPlaces = ref.watch(pendingLocationsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(pendingLocationsProvider.future),
      child: asyncPlaces.when(
        data: (placesData) {
          final places = placesData
              .where((p) => !_isOptimisticallyHidden(p['id']))
              .toList();

          if (places.isEmpty) {
            return Center(
              child: Text(
                "Aucun lieu en attente",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];
              return _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📍 ${place['name']}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      "${place['category']}",
                      style: const TextStyle(color: Colors.purpleAccent),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Soumis par: ${place['submitted_by_name']}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _confirmDelete(
                              context,
                              "Rejeter ce lieu ?",
                              "Cette action est irréversible.",
                              () => ref
                                  .read(adminActionProvider.notifier)
                                  .validateLocation(
                                    context,
                                    locationId: place['id'],
                                    isValid: false,
                                  ),
                            );
                          },
                          child: const Text(
                            "REJETER",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(adminActionProvider.notifier)
                              .validateLocation(
                                context,
                                locationId: place['id'],
                                isValid: true,
                              ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text("VALIDER"),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        error: (err, stack) => Center(child: Text("Erreur: $err")),
        loading: () => _buildShimmerLoading(),
      ),
    );
  }

  Widget _buildEventValidationList() {
    // Not refactored to Riverpod yet (using StreamBuilder in original)
    // BUT consistent with user request, we should refactor it.
    // However, I didn't create pendingEventsProvider in step 1.
    // Let's stick to StreamBuilder for this one OR use the generic pattern if I added it.
    // Checking step 1... I added `pendingEventsProvider`! So I can use it.

    final asyncEvents = ref.watch(pendingEventsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(pendingEventsProvider.future),
      child: asyncEvents.when(
        data: (eventsData) {
          final events = eventsData
              .where((e) => !_isOptimisticallyHidden(e['id']))
              .toList();

          if (events.isEmpty) {
            return Center(
              child: Text(
                "Aucun événement en attente",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📅 ${event['name']}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      "Date: ${event['event_date'].toString().split('T')[0]}",
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Soumis par: ${event['submitted_by_name']}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _confirmDelete(
                              context,
                              "Rejeter et Supprimer ?",
                              "Attention : Cette action va supprimer définitivement cet événement de la base de données.",
                              () => ref
                                  .read(adminActionProvider.notifier)
                                  .validateEvent(
                                    context,
                                    eventId: event['id'],
                                    isValid: false,
                                  ),
                            );
                          },
                          child: const Text(
                            "REJETER (SUPPRIMER)",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(adminActionProvider.notifier)
                              .validateEvent(
                                context,
                                eventId: event['id'],
                                isValid: true,
                              ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text("VALIDER"),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        error: (err, stack) => Center(child: Text("Erreur: $err")),
        loading: () => _buildShimmerLoading(),
      ),
    );
  }

  // --- 1.2 Management & Cleanup Tab ---
  Widget _buildManagementTab() {
    return Column(
      children: [
        // 1. Optimisation Panel (Surprise)
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orangeAccent.withValues(alpha: 0.2),
                Colors.deepOrange.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.orangeAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.orangeAccent),
                  SizedBox(width: 8),
                  Text(
                    "Maintenance Intelligente",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _cleanupDatabase(deleteEvents: true),
                      icon: const Icon(Icons.history, size: 16),
                      label: const Text("Purger Vieux Événements"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _cleanupDatabase(deleteUsers: true),
                      icon: const Icon(Icons.person_off, size: 16),
                      label: const Text("Purger Comptes Fantômes"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Info: Supprime les données obsolètes pour alléger la base de données.",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        // 2. Location Management Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _locationSearchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Rechercher un lieu à supprimer...",
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.white54),
                onPressed: () {
                  _locationSearchCtrl.clear();
                  setState(() => _locationSearchTerm = '');
                },
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (val) => setState(() => _locationSearchTerm = val),
          ),
        ),

        const SizedBox(height: 10),

        // 3. Location List
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase
                .from('locations')
                .stream(primaryKey: ['id'])
                .order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _buildShimmerLoading();
              }

              var locationsData = snapshot.data!;
              // Filter optimistically deleted items
              var locations = locationsData
                  .where((l) => !_isOptimisticallyHidden(l['id']))
                  .toList();

              // Filter locally
              if (_locationSearchTerm.isNotEmpty) {
                locations = locations
                    .where(
                      (loc) => (loc['name'] as String).toLowerCase().contains(
                        _locationSearchTerm.toLowerCase(),
                      ),
                    )
                    .toList();
              }

              if (locations.isEmpty) {
                return const Center(
                  child: Text(
                    "Aucun lieu trouvé.",
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final loc = locations[index];
                  return _buildGlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                          image: loc['image_url'] != null
                              ? DecorationImage(
                                  image: NetworkImage(loc['image_url']),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: loc['image_url'] == null
                            ? const Icon(Icons.place, color: Colors.white54)
                            : null,
                      ),
                      title: Text(
                        loc['name'] ?? "Sans nom",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        loc['address'] ?? "Pas d'adresse",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _deleteLocation(loc['id']),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 1.5 User Search & Ghost Mode Tab ---
  Widget _buildUserSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _userSearchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Rechercher (Nom, Email)...",
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.purpleAccent),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.white54),
                onPressed: () {
                  _userSearchCtrl.clear();
                  setState(() => _userSearchTerm = '');
                },
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.purpleAccent),
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
            ),
            onChanged: (val) {
              setState(() => _userSearchTerm = val);
            },
          ),
        ),
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final asyncUsers = ref.watch(allUsersProvider(_userSearchTerm));

              return asyncUsers.when(
                data: (users) {
                  return _buildUserList(users);
                },
                loading: () => _buildShimmerLoading(),
                error: (err, stack) => Center(
                  child: Text(
                    "Erreur: $err",
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // NOTE: Helper streams removed in favor of allUsersProvider

  Widget _buildUserList(List<UserProfile> users) {
    final currentUser = ref.watch(userProfileProvider).value;
    final isSuperAdmin = currentUser?.role == 'super_admin';

    // Filtrage des éléments supprimés optimistiquement
    final visibleUsers = users
        .where((u) => !_isOptimisticallyHidden(u.id))
        .toList();

    if (visibleUsers.isEmpty) {
      return const Center(
        child: Text(
          "Aucun utilisateur trouvé",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: visibleUsers.length,
      itemBuilder: (context, index) {
        final user = visibleUsers[index];
        final isSelf = user.id == currentUser?.id;
        final isAdmin = user.role == 'admin';
        final isSuperAdminUser = user.role == 'super_admin';

        return _buildGlassCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    "${user.firstName} ${user.lastName}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (user.role != 'user')
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: user.role == 'super_admin'
                          ? Colors.redAccent
                          : Colors.blueAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              user.email ?? "Pas d'email",
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouton Mode Fantôme (Visible pour tous les admins)
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.cyanAccent),
                  tooltip: "Mode Fantôme",
                  onPressed: () {
                    _activateGhostMode(user);
                  },
                ),

                // Actions réservées au Super Admin
                if (isSuperAdmin && !isSelf) ...[
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    tooltip: "Gérer le rôle",
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteUser(user.id);
                      } else if (value == 'promote') {
                        _updateUserRole(user.id, 'admin');
                      } else if (value == 'demote') {
                        _updateUserRole(user.id, 'user');
                      }
                    },
                    itemBuilder: (context) => [
                      if (!isSuperAdminUser) // On ne peut pas modifier un autre super admin facilement
                        if (!isAdmin)
                          const PopupMenuItem(
                            value: 'promote',
                            child: Row(
                              children: [
                                Icon(Icons.verified_user, color: Colors.blue),
                                SizedBox(width: 8),
                                Text("Nommer Admin"),
                              ],
                            ),
                          )
                        else
                          const PopupMenuItem(
                            value: 'demote',
                            child: Row(
                              children: [
                                Icon(Icons.person, color: Colors.grey),
                                SizedBox(width: 8),
                                Text("Retirer Admin"),
                              ],
                            ),
                          ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_forever, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Supprimer"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    await ref
        .read(adminActionProvider.notifier)
        .updateUserRole(context, userId: userId, newRole: newRole);
  }

  void _activateGhostMode(UserProfile user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Mode Fantôme",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Vous allez voir l'application comme ${user.firstName}. \nAttention : Vos actions seront limitées par votre session Admin réelle, mais l'affichage sera celui de l'utilisateur.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(ghostModeUserIdProvider.notifier).state = user.id;
              Navigator.pop(context); // Close Admin Dashboard
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Mode Fantôme activé pour ${user.firstName}"),
                  backgroundColor: Colors.cyan,
                ),
              );
            },
            child: const Text("ACTIVER", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // --- 2. Config Tab ---
  Widget _buildConfigTab() {
    if (_isLoadingConfig) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildGlassCard(
            child: SwitchListTile(
              title: const Text(
                "Mode Maintenance",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                "Verrouille l'accès pour tous sauf les admins",
                style: TextStyle(color: Colors.white54),
              ),
              value: _maintenanceMode,
              onChanged: (val) => setState(() => _maintenanceMode = val),
              activeThumbColor: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 16),
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Rayon Radar (mètres)",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextField(
                  controller: _radiusCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "Ex: 5000",
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Message IA du Jour",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextField(
                  controller: _aiMessageCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Entrez un message inspirant...",
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _updateConfig,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.purpleAccent,
              ),
              child: const Text(
                "METTRE À JOUR LA CONFIG",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Debug Tab ---
  Widget _buildDebugTab() {
    return const Center(
      child: Text(
        "Console Debug (Logs en temps réel)",
        style: TextStyle(color: Colors.white54),
      ),
    );
  }

  // --- 4. SOS Live Tab ---
  Widget _buildSosLiveTab() {
    final asyncRequests = ref.watch(adminUrgentRequestsStreamProvider);

    return Column(
      children: [
        // Header / KPI
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.deepOrange, Colors.redAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.emergency_recording,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "CENTRE DE CONTRÔLE SOS",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Gérez les urgences en temps réel",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Petit radar animé (décoratif)
              const SizedBox(
                width: 40,
                height: 40,
                child: UrgentPulseButton(
                  isAdmin: true,
                ), // Mini version (juste l'anim)
              ),
            ],
          ),
        ),

        // Liste des alertes
        Expanded(
          child: asyncRequests.when(
            data: (requests) {
              if (requests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Aucune urgence en cours",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return _buildUrgentRequestCard(req);
                },
              );
            },
            error: (err, stack) {
              final errorStr = err.toString();
              if (errorStr.contains('PGRST205') ||
                  errorStr.contains('urgent_requests')) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.table_view,
                          size: 48,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Table 'urgent_requests' manquante",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Veuillez exécuter le script de migration '03_urgent_requests_system.sql' dans votre Dashboard Supabase.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Center(child: Text("Erreur: $err"));
            },
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }

  Widget _buildUrgentRequestCard(UrgentRequest req) {
    final isPending = req.status == 'pending';
    final isBroadcasted = req.status == 'broadcasted';

    Color statusColor;
    switch (req.status) {
      case 'pending':
        statusColor = Colors.redAccent;
        break;
      case 'broadcasted':
        statusColor = Colors.orangeAccent;
        break;
      case 'accepted':
        statusColor = Colors.greenAccent;
        break;
      case 'completed':
        statusColor = Colors.blueAccent;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.white;
    }

    // Récupérer les infos user (lazy loading)
    // final asyncUser = ref.watch(requestUserProvider(req.requesterId));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête (Statut + Temps)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  req.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimeAgo(req.createdAt),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),

          // Corps
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Demandeur
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: req.requesterPhotoUrl != null
                      ? NetworkImage(req.requesterPhotoUrl!)
                      : null,
                  child: req.requesterPhotoUrl == null
                      ? const Icon(Icons.person, color: Colors.white54)
                      : null,
                ),
                const SizedBox(width: 16),

                // Détails
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (req.requesterName != null) ...[
                        Text(
                          req.requesterName!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        "Recherche: ${req.roleNeeded}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Motif: ${req.motive}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              req.locationAddress ?? "Localisation inconnue",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (req.budgetRange != null &&
                          req.budgetRange!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.attach_money,
                              size: 14,
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              req.budgetRange!,
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          if (isPending || isBroadcasted)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _updateRequestStatus(req.id, 'cancelled'),
                    child: const Text(
                      "ANNULER",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isPending)
                    ElevatedButton.icon(
                      onPressed: () =>
                          _updateRequestStatus(req.id, 'broadcasted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.podcasts, size: 16),
                      label: const Text("DIFFUSER (PUSH)"),
                    ),
                  if (isBroadcasted)
                    ElevatedButton.icon(
                      onPressed: () => _updateRequestStatus(req.id, 'resolved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text("MARQUER RÉSOLU"),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _updateRequestStatus(String reqId, String newStatus) async {
    try {
      await ref
          .read(urgentRequestsRepositoryProvider)
          .updateStatus(reqId, newStatus);
      if (mounted) {
        SmartSnackBar.show(
          context,
          message: "Statut mis à jour: $newStatus",
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        SmartSnackBar.show(context, message: "Erreur: $e", isError: true);
      }
    }
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "Il y a ${diff.inHours} h";
    return "Il y a ${diff.inDays} j";
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }
}
