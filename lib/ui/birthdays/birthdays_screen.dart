import 'package:flutter/material.dart'
    show
        Align,
        Alignment,
        BorderRadius,
        BorderSide,
        BoxDecoration,
        BoxShadow,
        BuildContext,
        Card,
        CircleAvatar,
        Color,
        Colors,
        Column,
        Container,
        CrossAxisAlignment,
        CustomScrollView,
        EdgeInsets,
        FontWeight,
        LinearGradient,
        ListTile,
        MainAxisAlignment,
        NetworkImage,
        Offset,
        RoundedRectangleBorder,
        SizedBox,
        SliverChildBuilderDelegate,
        SliverList,
        SliverPadding,
        SliverToBoxAdapter,
        Stack,
        State,
        StatefulWidget,
        Text,
        TextStyle,
        Widget;
import 'package:confetti/confetti.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../models/user_profile.dart';
import '../theme/app_theme.dart';

class BirthdaysListWidget extends StatefulWidget {
  final List<UserProfile> users;

  const BirthdaysListWidget({super.key, required this.users});

  @override
  State<BirthdaysListWidget> createState() => _BirthdaysListWidgetState();
}

class _BirthdaysListWidgetState extends State<BirthdaysListWidget> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    // Auto-play for demo if there's a birthday today
    if (_hasBirthdayToday(widget.users)) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  bool _hasBirthdayToday(List<UserProfile> users) {
    final today = DateTime.now();
    return users.any((u) {
      if (u.dateOfBirth == null) return false;
      return u.dateOfBirth!.day == today.day &&
          u.dateOfBirth!.month == today.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    // Filter today's birthdays
    final todaysBirthdays = widget.users.where((u) {
      if (u.dateOfBirth == null) return false;
      return u.dateOfBirth!.day == today.day &&
          u.dateOfBirth!.month == today.month;
    }).toList();

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Celebration Card (Top)
            if (todaysBirthdays.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildCelebrationCard(todaysBirthdays.first),
              ),

            // List of Upcoming
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final user = widget.users[index];
                  // Skip if displayed in header
                  if (todaysBirthdays.contains(user)) {
                    return const SizedBox.shrink();
                  }

                  final dob = user.dateOfBirth!;
                  final nextBirthday = _getNextBirthday(dob);

                  return Card(
                    color: AppTheme.backgroundLight.withValues(alpha: 0.5),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.secondaryColor,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.firstName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        '${user.firstName} ${user.lastName}',
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                      subtitle: Text(
                        user.category,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('d MMMM', 'fr_FR').format(dob),
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getDaysUntil(nextBirthday),
                            style: TextStyle(
                              color: AppTheme.textSecondary.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }, childCount: widget.users.length),
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
    );
  }

  DateTime _getNextBirthday(DateTime dob) {
    final today = DateTime.now();
    var nextBirthday = DateTime(today.year, dob.month, dob.day);
    if (nextBirthday.isBefore(today.subtract(const Duration(days: 1)))) {
      nextBirthday = DateTime(today.year + 1, dob.month, dob.day);
    }
    return nextBirthday;
  }

  String _getDaysUntil(DateTime date) {
    final today = DateTime.now();
    final diff = date.difference(today).inDays;
    if (diff == 0) return 'Aujourd\'hui';
    if (diff == 1) return 'Demain';
    return 'Dans $diff jours';
  }

  Widget _buildCelebrationCard(UserProfile user) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF800080), Color(0xFFDF00FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDF00FF).withValues(alpha: 0.3),
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
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? Text(
                      user.firstName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 24),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${user.firstName} ${user.lastName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            user.category,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
