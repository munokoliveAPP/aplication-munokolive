import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final String category; // 'Membre', 'Pasteur', 'Chantre', 'Musicien', etc.
  final String? subCategory; // 'Pianiste', 'Batteur' (for Musicien)
  final String status; // 'active', 'pending', 'admin', 'validated_admin'
  final String? city;
  final String? neighborhood; // Quartier
  final String? commune; // Commune
  final String? churchName; // Nom de l'église
  final String?
  availabilityStatus; // 'available', 'unavailable', 'need_help', 'no_need_help'
  final double? latitude;
  final double? longitude;
  final String? sponsorId; // ID du Parrain
  final String? sponsorName; // Nom du Parrain
  final String? sponsorshipCode;
  final DateTime? dateOfBirth;
  final bool isOnline;
  final DateTime? lastActive;
  final List<String>? instruments;
  final bool isDiscretMode; // Renamed concept: Fuzzy Location (Zone 500m)
  final bool isGhostMode; // New: Total Invisibility (Panic Button)
  final bool isDndMode;
  final DateTime? createdAt; // Date d'inscription
  final String? whatsappNumber; // Numéro WhatsApp spécifique
  final int points; // Gamification Points
  final List<String> friends; // List of friend UIDs
  final List<String>
  interests; // Common interests (e.g., 'Gospel', 'Jazz', 'Tech')
  final List<String> badges; // New: Gamification Badges

  UserProfile({
    required this.uid,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.photoUrl,
    required this.category,
    this.subCategory,
    required this.status,
    this.city,
    this.neighborhood,
    this.commune,
    this.churchName,
    this.availabilityStatus,
    this.latitude,
    this.longitude,
    this.sponsorshipCode,
    this.sponsorId,
    this.sponsorName,
    this.dateOfBirth,
    this.createdAt,
    this.whatsappNumber,
    this.isOnline = false,
    this.lastActive,
    this.instruments,
    this.isDiscretMode = false,
    this.isGhostMode = false,
    this.isDndMode = false,
    this.points = 0,
    this.friends = const [],
    this.interests = const [],
    this.badges = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      photoUrl: json['photoUrl'] as String?,
      category: json['category'] as String? ?? 'Membre',
      subCategory: json['subCategory'] as String?,
      status: json['status'] as String? ?? 'pending',
      city: json['city'] as String?,
      neighborhood: json['neighborhood'] as String?,
      commune: json['commune'] as String?,
      churchName: json['churchName'] as String?,
      availabilityStatus: json['availabilityStatus'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      sponsorshipCode: json['sponsorshipCode'] as String?,
      sponsorId: json['sponsorId'] as String?,
      sponsorName: json['sponsorName'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? (json['dateOfBirth'] is Timestamp
                ? (json['dateOfBirth'] as Timestamp).toDate()
                : (json['dateOfBirth'] is String
                      ? DateTime.tryParse(json['dateOfBirth'] as String)
                      : null))
          : null,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
                ? (json['createdAt'] as Timestamp).toDate()
                : (json['createdAt'] is String
                      ? DateTime.tryParse(json['createdAt'] as String)
                      : null))
          : null,
      whatsappNumber: json['whatsappNumber'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastActive: json['lastActive'] != null
          ? (json['lastActive'] is Timestamp
                ? (json['lastActive'] as Timestamp).toDate()
                : (json['lastActive'] is String
                      ? DateTime.tryParse(json['lastActive'] as String)
                      : null))
          : null,
      instruments: (json['instruments'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      isDiscretMode: json['isDiscretMode'] as bool? ?? false,
      isGhostMode: json['isGhostMode'] as bool? ?? false,
      isDndMode: json['isDndMode'] as bool? ?? false,
      points: json['points'] as int? ?? 0,
      friends:
          (json['friends'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      interests:
          (json['interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'category': category,
      'subCategory': subCategory,
      'status': status,
      'city': city,
      'neighborhood': neighborhood,
      'commune': commune,
      'churchName': churchName,
      'availabilityStatus': availabilityStatus,
      'latitude': latitude,
      'longitude': longitude,
      'sponsorshipCode': sponsorshipCode,
      'sponsorId': sponsorId,
      'sponsorName': sponsorName,
      'dateOfBirth': dateOfBirth != null
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'whatsappNumber': whatsappNumber,
      'isOnline': isOnline,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'instruments': instruments,
      'isDiscretMode': isDiscretMode,
      'isGhostMode': isGhostMode,
      'isDndMode': isDndMode,
      'points': points,
      'friends': friends,
      'interests': interests,
      'badges': badges,
    };
  }

  String get displayName => "$firstName $lastName";
  String get photoURL => photoUrl ?? "";

  UserProfile copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? photoUrl,
    String? category,
    String? subCategory,
    String? status,
    String? city,
    String? neighborhood,
    String? commune,
    String? churchName,
    String? availabilityStatus,
    double? latitude,
    double? longitude,
    String? sponsorshipCode,
    String? sponsorId,
    String? sponsorName,
    DateTime? dateOfBirth,
    bool? isOnline,
    DateTime? lastActive,
    List<String>? instruments,
    bool? isDiscretMode,
    bool? isGhostMode,
    bool? isDndMode,
    DateTime? createdAt,
    String? whatsappNumber,
    int? points,
    List<String>? friends,
    List<String>? interests,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      status: status ?? this.status,
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      commune: commune ?? this.commune,
      churchName: churchName ?? this.churchName,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      sponsorshipCode: sponsorshipCode ?? this.sponsorshipCode,
      sponsorId: sponsorId ?? this.sponsorId,
      sponsorName: sponsorName ?? this.sponsorName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
      instruments: instruments ?? this.instruments,
      isDiscretMode: isDiscretMode ?? this.isDiscretMode,
      isGhostMode: isGhostMode ?? this.isGhostMode,
      isDndMode: isDndMode ?? this.isDndMode,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      createdAt: createdAt ?? this.createdAt,
      points: points ?? this.points,
      friends: friends ?? this.friends,
      interests: interests ?? this.interests,
    );
  }
}
