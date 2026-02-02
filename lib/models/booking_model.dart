/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */

enum BookingStatus {
  pending,
  accepted,
  declined,
  enRoute, // en_route in DB
  inProgress, // in_progress in DB
  completed,
  cancelled,
}

class BookingModel {
  final String id;
  final String clientId;
  final String? serviceId;
  final String providerId;
  final BookingStatus status;
  final DateTime bookingDate;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final double? totalPrice;
  final DateTime createdAt;

  // Relations (peuvent être null si non chargés via join)
  final Map<String, dynamic>? clientData;
  final Map<String, dynamic>? providerData;
  final Map<String, dynamic>? serviceData;

  BookingModel({
    required this.id,
    required this.clientId,
    this.serviceId,
    required this.providerId,
    required this.status,
    required this.bookingDate,
    this.locationName,
    this.latitude,
    this.longitude,
    this.totalPrice,
    required this.createdAt,
    this.clientData,
    this.providerData,
    this.serviceData,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      clientId: json['client_id'],
      serviceId: json['service_id'],
      providerId: json['provider_id'],
      status: _parseStatus(json['status']),
      bookingDate: DateTime.parse(json['booking_date']),
      locationName: json['location_name'],
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      totalPrice: json['total_price'] != null
          ? (json['total_price'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at']),
      clientData: json['client'] as Map<String, dynamic>?,
      providerData: json['provider'] as Map<String, dynamic>?,
      serviceData: json['service'] as Map<String, dynamic>?,
    );
  }

  static BookingStatus _parseStatus(String status) {
    switch (status) {
      case 'accepted':
        return BookingStatus.accepted;
      case 'declined':
        return BookingStatus.declined;
      case 'en_route':
        return BookingStatus.enRoute;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  static String statusToString(BookingStatus status) {
    switch (status) {
      case BookingStatus.enRoute:
        return 'en_route';
      case BookingStatus.inProgress:
        return 'in_progress';
      default:
        return status.name; // pending, accepted, declined, completed, cancelled
    }
  }
}
