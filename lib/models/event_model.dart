import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String creatorId;
  final List<String> attendees;
  final String? imageUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final String category;
  final String time;
  final String? neighborhood;
  final String? commune;
  final String? city;
  final GeoPoint? coordinates;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.creatorId,
    required this.attendees,
    this.imageUrl,
    this.status = 'pending',
    required this.category,
    required this.time,
    this.neighborhood,
    this.commune,
    this.city,
    this.coordinates,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: (json['date'] as Timestamp).toDate(),
      location: json['location'] ?? '',
      creatorId: json['creatorId'] ?? '',
      attendees: List<String>.from(json['attendees'] ?? []),
      imageUrl: json['imageUrl'],
      status: json['status'] ?? 'pending',
      category: json['category'] ?? 'Général',
      time: json['time'] ?? '',
      neighborhood: json['neighborhood'],
      commune: json['commune'],
      city: json['city'],
      coordinates: json['coordinates'] as GeoPoint?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'location': location,
      'creatorId': creatorId,
      'attendees': attendees,
      'imageUrl': imageUrl,
      'status': status,
      'category': category,
      'time': time,
      'neighborhood': neighborhood,
      'commune': commune,
      'city': city,
      'coordinates': coordinates,
    };
  }
}
