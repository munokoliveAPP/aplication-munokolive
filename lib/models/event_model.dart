class EventModel {
  final String id;
  final String name;
  final String? description;
  final DateTime eventDate;
  final String? imageUrl;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String? submittedByName;
  final String? submittedById;
  final bool isValidated;
  final DateTime? createdAt;
  final String? category; // Added

  EventModel({
    required this.id,
    required this.name,
    this.description,
    required this.eventDate,
    this.imageUrl,
    this.locationName,
    this.latitude,
    this.longitude,
    this.submittedByName,
    this.submittedById,
    this.isValidated = false,
    this.createdAt,
    this.category,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      eventDate: DateTime.parse(json['event_date']),
      imageUrl: json['image_url'] as String?,
      locationName: json['location_name'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      submittedByName: json['submitted_by_name'] as String?,
      submittedById: json['submitted_by_id'] as String?,
      isValidated: json['is_validated'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'event_date': eventDate.toIso8601String(),
      'image_url': imageUrl,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'submitted_by_name': submittedByName,
      'submitted_by_id': submittedById,
      'is_validated': isValidated,
      'created_at': createdAt?.toIso8601String(),
      'category': category,
    };
  }
}
