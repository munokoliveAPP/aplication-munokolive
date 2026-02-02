class UrgentRequest {
  final String id;
  final String requesterId;
  final String roleNeeded;
  final String motive;
  final String? locationAddress;
  final double? locationLat;
  final double? locationLng;
  final String? hoursDescription;
  final String? budgetRange;
  final String status; // pending, broadcasted, accepted, completed, cancelled
  final String? assignedToId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields (optional, for UI display)
  final String? requesterName;
  final String? requesterPhotoUrl;
  final String? requesterPhone;

  UrgentRequest({
    required this.id,
    required this.requesterId,
    required this.roleNeeded,
    required this.motive,
    this.locationAddress,
    this.locationLat,
    this.locationLng,
    this.hoursDescription,
    this.budgetRange,
    required this.status,
    this.assignedToId,
    required this.createdAt,
    required this.updatedAt,
    this.requesterName,
    this.requesterPhotoUrl,
    this.requesterPhone,
  });

  factory UrgentRequest.fromJson(Map<String, dynamic> json) {
    // Handle joined user data if available
    String? rName;
    String? rPhoto;
    String? rPhone;

    if (json['users'] != null) {
      final user = json['users'];
      rName = "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}".trim();
      rPhoto = user['photo_url'];
      rPhone = user['phone_number'];
    }

    return UrgentRequest(
      id: json['id'],
      requesterId: json['requester_id'],
      roleNeeded: json['role_needed'] ?? 'Inconnu',
      motive: json['motive'] ?? 'Autre',
      locationAddress: json['location_address'],
      locationLat: json['location_lat'] != null
          ? (json['location_lat'] as num).toDouble()
          : null,
      locationLng: json['location_lng'] != null
          ? (json['location_lng'] as num).toDouble()
          : null,
      hoursDescription: json['hours_description'],
      budgetRange: json['budget_range'],
      status: json['status'] ?? 'pending',
      assignedToId: json['assigned_to_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      requesterName: rName,
      requesterPhotoUrl: rPhoto,
      requesterPhone: rPhone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requester_id': requesterId,
      'role_needed': roleNeeded,
      'motive': motive,
      'location_address': locationAddress,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'hours_description': hoursDescription,
      'budget_range': budgetRange,
      'status': status,
      'assigned_to_id': assignedToId,
      // created_at and updated_at are handled by DB
    };
  }

  UrgentRequest copyWith({String? status, String? assignedToId}) {
    return UrgentRequest(
      id: id,
      requesterId: requesterId,
      roleNeeded: roleNeeded,
      motive: motive,
      locationAddress: locationAddress,
      locationLat: locationLat,
      locationLng: locationLng,
      hoursDescription: hoursDescription,
      budgetRange: budgetRange,
      status: status ?? this.status,
      assignedToId: assignedToId ?? this.assignedToId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      requesterName: requesterName,
      requesterPhotoUrl: requesterPhotoUrl,
      requesterPhone: requesterPhone,
    );
  }
}
