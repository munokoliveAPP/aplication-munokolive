import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class BirthdaysScreen extends StatefulWidget {
  const BirthdaysScreen({super.key});

  @override
  State<BirthdaysScreen> createState() => _BirthdaysScreenState();
}

class _BirthdaysScreenState extends State<BirthdaysScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    // Auto-play for demo if there's a birthday today
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final today = DateTime.now();
    final birthdays = [
      {
        'name': 'Sarah Levite',
        'date': today,
        'role': 'Chantre',
        'img': 'https://i.pravatar.cc/150?u=sarah',
      },
      {
        'name': 'Jean Pierre',
        'date': today.add(const Duration(days: 2)),
        'role': 'Pasteur',
        'img': 'https://i.pravatar.cc/150?u=jean',
      },
      {
        'name': 'Marie Claire',
        'date': today.add(const Duration(days: 5)),
        'role': 'Pianiste',
        'img': 'https://i.pravatar.cc/150?u=marie',
      },
    ];

    final todaysBirthdays = birthdays.where((b) {
      final date = b['date'] as DateTime;
      return date.day == today.day && date.month == today.month;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF190019),
      appBar: AppBar(
        title: const Text('Anniversaires'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.celebration),
            onPressed: () => _confettiController.play(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Celebration Card (Top)
              if (todaysBirthdays.isNotEmpty)
                _buildCelebrationCard(todaysBirthdays.first),

              // List of Upcoming
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: birthdays.length,
                  itemBuilder: (context, index) {
                    final b = birthdays[index];
                    final date = b['date'] as DateTime;
                    final isToday =
                        date.day == today.day && date.month == today.month;
                    if (isToday) {
                      return const SizedBox.shrink(); // Already shown in card
                    }

                    return Card(
                      color: Colors.white10,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(b['img'] as String),
                        ),
                        title: Text(
                          b['name'] as String,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          b['role'] as String,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          DateFormat('d MMMM', 'fr_FR').format(date),
                          style: const TextStyle(
                            color: Color(0xFFE600E6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Confetti Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
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
      ),
    );
  }

  Widget _buildCelebrationCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF800080), Color(0xFFE600E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE600E6).withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'JOYEUX ANNIVERSAIRE !',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 36,
              backgroundImage: NetworkImage(user['img'] as String),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user['name'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            user['role'] as String,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
