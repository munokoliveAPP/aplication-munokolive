import 'package:cloud_firestore/cloud_firestore.dart';

enum PlaceCategory { studio, rehearsalRoom, eventSpace, trainingRoom, other }

enum PlaceStatus { pending, approved, rejected, hidden }

class PlaceModel {
  final String id;
  final String name;
  final String description;
  final PlaceCategory category;
  final GeoPoint? coordinates;
  final String address;
  final String city;
  final String commune;
  final String neighborhood;
  final List<String> images;
  final String ownerId;
  final String ownerName; // Denormalized for display
  final String contactPhone;
  final PlaceStatus status;
  final bool isVerified;
  final DateTime createdAt;
  final List<String> features; // e.g., "Wifi", "Parking", "Air Conditioned"
  final Map<String, dynamic> openingHours; // Structured data for hours
  final double rating;
  final int reviewCount;

  PlaceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.coordinates,
    required this.address,
    required this.city,
    required this.commune,
    required this.neighborhood,
    required this.images,
    required this.ownerId,
    required this.ownerName,
    required this.contactPhone,
    required this.status,
    this.isVerified = false,
    required this.createdAt,
    this.features = const [],
    this.openingHours = const {},
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  factory PlaceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlaceModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: _parseCategory(data['category']),
      coordinates: data['coordinates'] as GeoPoint?,
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      commune: data['commune'] ?? '',
      neighborhood: data['neighborhood'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? 'Inconnu',
      contactPhone: data['contactPhone'] ?? '',
      status: _parseStatus(data['status']),
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      features: List<String>.from(data['features'] ?? []),
      openingHours: data['openingHours'] ?? {},
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
    );
  }

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: _parseCategory(json['category']),
      coordinates: json['coordinates'] != null
          ? (json['coordinates'] is Map
                ? GeoPoint(
                    (json['coordinates']['latitude'] as num).toDouble(),
                    (json['coordinates']['longitude'] as num).toDouble(),
                  )
                : null) // Handle other cases if needed
          : null,
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      commune: json['commune'] ?? '',
      neighborhood: json['neighborhood'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? 'Inconnu',
      contactPhone: json['contactPhone'] ?? '',
      status: _parseStatus(json['status']),
      isVerified: json['isVerified'] ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String
                ? DateTime.parse(json['createdAt'])
                : (json['createdAt'] as Timestamp).toDate())
          : DateTime.now(),
      features: List<String>.from(json['features'] ?? []),
      openingHours: json['openingHours'] ?? {},
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'coordinates': coordinates != null
          ? {
              'latitude': coordinates!.latitude,
              'longitude': coordinates!.longitude,
            }
          : null,
      'address': address,
      'city': city,
      'commune': commune,
      'neighborhood': neighborhood,
      'images': images,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'contactPhone': contactPhone,
      'status': status.name,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'features': features,
      'openingHours': openingHours,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category.name,
      'coordinates': coordinates,
      'address': address,
      'city': city,
      'commune': commune,
      'neighborhood': neighborhood,
      'images': images,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'contactPhone': contactPhone,
      'status': status.name,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'features': features,
      'openingHours': openingHours,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  static PlaceCategory _parseCategory(String? value) {
    if (value == null) return PlaceCategory.other;
    return PlaceCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PlaceCategory.other,
    );
  }

  static PlaceStatus _parseStatus(String? value) {
    if (value == null) return PlaceStatus.pending;
    return PlaceStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PlaceStatus.pending,
    );
  }

  String get categoryLabel {
    switch (category) {
      case PlaceCategory.studio:
        return 'Studio d\'enregistrement';
      case PlaceCategory.rehearsalRoom:
        return 'Salle de répétition';
      case PlaceCategory.eventSpace:
        return 'Espace événementiel';
      case PlaceCategory.trainingRoom:
        return 'Salle de formation';
      default:
        return 'Autre';
    }
  }
}
