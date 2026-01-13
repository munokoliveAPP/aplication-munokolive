import 'package:cloud_firestore/cloud_firestore.dart';

class SOSModel {
  final String id;
  final String requesterId;
  final String requesterName;
  final GeoPoint location;
  final double radiusKm;
  final DateTime timestamp;
  final String status; // 'active', 'resolved'
  final List<String> notifiedUserIds;
  final Map<String, dynamic> details;
  final String? locationDescription;

  SOSModel({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.location,
    required this.radiusKm,
    required this.timestamp,
    required this.status,
    required this.notifiedUserIds,
    this.details = const {},
    this.locationDescription,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'requesterId': requesterId,
    'requesterName': requesterName,
    'location': location,
    'radiusKm': radiusKm,
    'timestamp': Timestamp.fromDate(timestamp),
    'status': status,
    'notifiedUserIds': notifiedUserIds,
    'details': details,
    'locationDescription': locationDescription,
  };

  static SOSModel fromJson(Map<String, dynamic> json) => SOSModel(
    id: json['id'] as String,
    requesterId: json['requesterId'] as String,
    requesterName: json['requesterName'] as String,
    location: json['location'] as GeoPoint,
    radiusKm: (json['radiusKm'] as num).toDouble(),
    timestamp: (json['timestamp'] as Timestamp).toDate(),
    status: json['status'] as String,
    notifiedUserIds: (json['notifiedUserIds'] as List<dynamic>).cast<String>(),
    details: json['details'] as Map<String, dynamic>? ?? {},
    locationDescription: json['locationDescription'] as String?,
  );
}
