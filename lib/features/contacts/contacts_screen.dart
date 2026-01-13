import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  String _selectedFilter = 'Tous';
  String _selectedSort = 'Dernière activité';

  final List<String> _filters = [
    'Tous',
    'Pasteur',
    'Pianiste',
    'Batteur',
    'Chantre',
  ];

  final List<String> _sortOptions = [
    'Dernière activité',
    'Proximité',
    'Alphabétique',
  ];

  // Mock Data
  final List<Map<String, dynamic>> _allContacts = [
    {
      'name': 'Jean Dupont',
      'role': 'Pasteur',
      'status': 'online',
      'lastActive': DateTime.now().subtract(const Duration(minutes: 5)),
      'distance': 1200, // meters
      'img': 'https://i.pravatar.cc/150?u=jean',
    },
    {
      'name': 'Marie Curie',
      'role': 'Pianiste',
      'status': 'offline',
      'lastActive': DateTime.now().subtract(const Duration(hours: 2)),
      'distance': 500,
      'img': 'https://i.pravatar.cc/150?u=marie',
    },
    {
      'name': 'Paul Martin',
      'role': 'Batteur',
      'status': 'online',
      'lastActive': DateTime.now(), // Just now
      'distance': 8000,
      'img': 'https://i.pravatar.cc/150?u=paul',
    },
    {
      'name': 'Sarah Connor',
      'role': 'Chantre',
      'status': 'online',
      'lastActive': DateTime.now().subtract(const Duration(minutes: 30)),
      'distance': 300,
      'img': 'https://i.pravatar.cc/150?u=sarah',
    },
    {
      'name': 'Luc Skywalker',
      'role': 'Pasteur',
      'status': 'offline',
      'lastActive': DateTime.now().subtract(const Duration(days: 1)),
      'distance': 15000,
      'img': 'https://i.pravatar.cc/150?u=luc',
    },
  ];

  List<Map<String, dynamic>> _getFilteredAndSortedContacts() {
    // 1. Filter
    var filtered = _selectedFilter == 'Tous'
        ? List<Map<String, dynamic>>.from(_allContacts)
        : _allContacts.where((c) => c['role'] == _selectedFilter).toList();

    // 2. Sort
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'Proximité':
          return (a['distance'] as int).compareTo(b['distance'] as int);
        case 'Alphabétique':
          return (a['name'] as String).compareTo(b['name'] as String);
        case 'Dernière activité':
        default:
          // Most recent first
          return (b['lastActive'] as DateTime).compareTo(
            a['lastActive'] as DateTime,
          );
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final displayedContacts = _getFilteredAndSortedContacts();
    final isDiscreteMode = ref.watch(discreteModeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF190019),
      appBar: AppBar(
        title: const Text('Contacts', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Row(
            children: [
              Text(
                'Mode Discret',
                style: TextStyle(
                  fontSize: 12,
                  color: isDiscreteMode
                      ? const Color(0xFFE600E6)
                      : Colors.white70,
                ),
              ),
              Switch(
                value: isDiscreteMode,
                onChanged: (value) {
                  ref.read(discreteModeProvider.notifier).state = value;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Mode Discret activé : Votre position est masquée.'
                            : 'Mode Discret désactivé : Vous êtes visible.',
                      ),
                      backgroundColor: const Color(0xFF800080),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                activeThumbColor: const Color(0xFFE600E6),
              ),
            ],
          ),
          // Sort Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: (value) {
              setState(() {
                _selectedSort = value;
              });
            },
            itemBuilder: (context) => _sortOptions
                .map(
                  (option) => PopupMenuItem(
                    value: option,
                    child: Text(
                      option,
                      style: TextStyle(
                        color: _selectedSort == option
                            ? const Color(0xFF800080)
                            : Colors.black,
                        fontWeight: _selectedSort == option
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.white10,
                    selectedColor: const Color(0xFF800080),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Contacts List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: displayedContacts.length,
              itemBuilder: (context, index) {
                final contact = displayedContacts[index];
                final isOnline = contact['status'] == 'online';
                final distance = contact['distance'] as int;
                final lastActive = contact['lastActive'] as DateTime;

                // Format time ago
                final diff = DateTime.now().difference(lastActive);
                String timeAgo;
                if (diff.inMinutes < 1) {
                  timeAgo = 'À l\'instant';
                } else if (diff.inMinutes < 60) {
                  timeAgo = '${diff.inMinutes} min';
                } else if (diff.inHours < 24) {
                  timeAgo = '${diff.inHours} h';
                } else {
                  timeAgo = '${diff.inDays} j';
                }

                return Card(
                  color: Colors.white10,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(contact['img']),
                          backgroundColor: Colors.grey[800],
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF190019),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      contact['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          contact['role'],
                          style: const TextStyle(color: Color(0xFFE600E6)),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.white54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              distance < 1000
                                  ? '${distance}m'
                                  : '${(distance / 1000).toStringAsFixed(1)}km',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.white54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeAgo,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.message_outlined,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Discussion avec ${contact['name']}'),
                            backgroundColor: const Color(0xFF800080),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
