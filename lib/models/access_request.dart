import 'package:cloud_firestore/cloud_firestore.dart';

enum AccessRequestStatus { pending, accepted, rejected, expired }

class AccessRequest {
  final String id;
  final String requesterId;
  final String targetId;
  final AccessRequestStatus status;
  final int durationMinutes; // 30, 60, or -1 for indefinite
  final DateTime createdAt;

  AccessRequest({
    required this.id,
    required this.requesterId,
    required this.targetId,
    required this.status,
    required this.durationMinutes,
    required this.createdAt,
  });

  factory AccessRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AccessRequest(
      id: doc.id,
      requesterId: data['requesterId'] as String,
      targetId: data['targetId'] as String,
      status: AccessRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AccessRequestStatus.pending,
      ),
      durationMinutes: data['durationMinutes'] as int? ?? 30,
      // Guard against missing server timestamp in some reads.
      // If `createdAt` is not yet set (null), use `DateTime.now()` as a safe fallback.
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requesterId': requesterId,
      'targetId': targetId,
      'status': status.name,
      'durationMinutes': durationMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
