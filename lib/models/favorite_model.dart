import 'package:cloud_firestore/cloud_firestore.dart';

enum FavoriteType { place, event, user }

class FavoriteModel {
  final String id;
  final String userId;
  final FavoriteType type;
  final String itemId; // ID du lieu/événement/user
  final DateTime createdAt;
  final Map<String, dynamic>?
  metadata; // Données supplémentaires (nom, image, etc.)

  FavoriteModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.itemId,
    required this.createdAt,
    this.metadata,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: FavoriteType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FavoriteType.place,
      ),
      itemId: json['itemId'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type.name,
      'itemId': itemId,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }
}
