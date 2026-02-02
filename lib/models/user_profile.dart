/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
class UserProfile {
  final String id;
  final String? email;
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final String role; // 'user', 'admin'
  final String status; // 'active', 'pending', etc.
  final int points;
  final String? churchName;
  final String category; // 'Membre', 'Musicien', etc.
  final String? subCategory;
  final bool isValidated;
  final DateTime? createdAt;
  final String? phoneNumber;
  final String? country;
  final String? city;
  final String? commune;
  final String? neighborhood;
  final bool isAvailable;
  final String? referralCode;
  final String? referredBy;
  final DateTime? birthDate;

  UserProfile({
    required this.id,
    this.email,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
    this.role = 'user',
    this.status = 'pending',
    this.points = 0,
    this.churchName,
    this.category = 'Membre',
    this.subCategory,
    this.isValidated = false,
    this.createdAt,
    this.phoneNumber,
    this.country,
    this.city,
    this.commune,
    this.neighborhood,
    this.isAvailable = true,
    this.referralCode,
    this.referredBy,
    this.birthDate,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      role: json['role'] as String? ?? 'user',
      status: json['status'] as String? ?? 'pending',
      points: json['points'] as int? ?? 0,
      churchName: json['church_name'] as String?,
      category: json['category'] as String? ?? 'Membre',
      subCategory: json['sub_category'] as String?,
      isValidated: json['is_validated'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      phoneNumber: json['phone_number'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      commune: json['commune'] as String?,
      neighborhood: json['neighborhood'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      referralCode: json['referral_code'] as String?,
      referredBy: json['referred_by'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'photo_url': photoUrl,
      'role': role,
      'status': status,
      'points': points,
      'church_name': churchName,
      'category': category,
      'sub_category': subCategory,
      'is_validated': isValidated,
      'created_at': createdAt?.toIso8601String(),
      'phone_number': phoneNumber,
      'country': country,
      'city': city,
      'commune': commune,
      'neighborhood': neighborhood,
      'is_available': isAvailable,
      'referral_code': referralCode,
      'referred_by': referredBy,
      'birth_date': birthDate?.toIso8601String(),
    };
  }
  
  String get fullName => '$firstName $lastName';
}
