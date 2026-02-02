/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */

class CarpoolOffer {
  final String id;
  final String driverId;
  final String eventId;
  final String origin;
  final DateTime departureTime;
  final int availableSeats;
  final double price;
  final String? vehicleDescription;

  CarpoolOffer({
    required this.id,
    required this.driverId,
    required this.eventId,
    required this.origin,
    required this.departureTime,
    required this.availableSeats,
    required this.price,
    this.vehicleDescription,
  });

  factory CarpoolOffer.fromMap(Map<String, dynamic> map) {
    return CarpoolOffer(
      id: map['id'] ?? '',
      driverId: map['driver_id'] ?? '',
      eventId: map['event_id'] ?? '',
      origin: map['origin'] ?? '',
      departureTime: DateTime.parse(map['departure_time']),
      availableSeats: map['available_seats'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      vehicleDescription: map['vehicle_description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driver_id': driverId,
      'event_id': eventId,
      'origin': origin,
      'departure_time': departureTime.toIso8601String(),
      'available_seats': availableSeats,
      'price': price,
      'vehicle_description': vehicleDescription,
    };
  }
}
