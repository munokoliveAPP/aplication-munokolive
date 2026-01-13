import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui' as ui;

final activeSosProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('sos_alerts')
      .where('requesterId', isEqualTo: currentUser.uid)
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((snapshot) {
        final now = DateTime.now();
        return snapshot.docs
            .where((doc) {
              final data = doc.data();
              final expiresAt = data['expiresAt'] as Timestamp?;
              if (expiresAt == null) return true;
              return expiresAt.toDate().isAfter(now);
            })
            .map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'type': data['type'] as String? ?? '',
                'instrumentType': data['instrumentType'] as String?,
                'programType': data['programType'] as String?,
                'needType': data['needType'] as String?,
                'time': data['time'] as String?,
                'date': data['date'] as String?,
                'location': data['location'] as String? ?? '',
                'createdAt': data['createdAt'] as Timestamp?,
              };
            })
            .toList();
      });
});

class SOSActiveBanner extends ConsumerWidget {
  const SOSActiveBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSosAsync = ref.watch(activeSosProvider);

    return activeSosAsync.when(
      data: (sosList) {
        if (sosList.isEmpty) return const SizedBox.shrink();

        final latestSos = sosList.first;
        final isMusician = latestSos['type'] == 'musician';
        final title = isMusician ? 'SOS MUSICIEN ACTIF' : 'SOS MINISTÈRE ACTIF';
        final subtitle = isMusician
            ? '${latestSos['instrumentType']} recherché pour ${latestSos['programType']}'
            : '${latestSos['needType']} - ${latestSos['location']}';

        return Positioned(
          top: 70,
          left: 16,
          right: 16,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, (1 - value) * -100),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isMusician
                          ? [Colors.red.shade900, Colors.red.shade700]
                          : [Colors.blue.shade900, Colors.blue.shade700],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isMusician ? Colors.red : Colors.blue)
                            .withValues(alpha: 0.6),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isMusician ? Icons.music_note : Icons.church,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Option to dismiss or view details
                          FirebaseFirestore.instance
                              .collection('sos_alerts')
                              .doc(latestSos['id'])
                              .update({'status': 'dismissed'});
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
