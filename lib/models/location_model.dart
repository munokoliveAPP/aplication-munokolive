class LocationModel {
  final String id;
  final String name;
  final String category;
  final String? imageUrl; // Exterior
  final String? interiorImageUrl; // Interior
  final String? responsibleName;
  final String? contactPhone;
  final String? address;
  final String? submittedByName;
  final String? submittedById;
  final bool isValidated;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  LocationModel({
    required this.id,
    required this.name,
    required this.category,
    this.imageUrl,
    this.interiorImageUrl,
    this.responsibleName,
    this.contactPhone,
    this.address,
    this.submittedByName,
    this.submittedById,
    this.isValidated = false,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      imageUrl: json['image_url'] as String?,
      interiorImageUrl: json['interior_image_url'] as String?,
      responsibleName: json['responsible_name'] as String?,
      contactPhone: json['contact_phone'] as String?,
      address: json['address'] as String?,
      submittedByName: json['submitted_by_name'] as String?,
      submittedById: json['submitted_by_id'] as String?,
      isValidated: json['is_validated'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'image_url': imageUrl,
      'interior_image_url': interiorImageUrl,
      'responsible_name': responsibleName,
      'contact_phone': contactPhone,
      'address': address,
      'submitted_by_name': submittedByName,
      'submitted_by_id': submittedById,
      'is_validated': isValidated,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
