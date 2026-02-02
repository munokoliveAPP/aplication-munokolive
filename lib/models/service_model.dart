/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */

class ServiceModel {
  final String id;
  final String providerId;
  final String title;
  final String? description;
  final double rateAmount;
  final String rateType; // 'hourly' or 'fixed'
  final bool isActive;
  final DateTime createdAt;

  ServiceModel({
    required this.id,
    required this.providerId,
    required this.title,
    this.description,
    required this.rateAmount,
    required this.rateType,
    this.isActive = true,
    required this.createdAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      providerId: json['provider_id'],
      title: json['title'],
      description: json['description'],
      rateAmount: (json['rate_amount'] as num).toDouble(),
      rateType: json['rate_type'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider_id': providerId,
      'title': title,
      'description': description,
      'rate_amount': rateAmount,
      'rate_type': rateType,
      'is_active': isActive,
    };
  }

  ServiceModel copyWith({
    String? id,
    String? providerId,
    String? title,
    String? description,
    double? rateAmount,
    String? rateType,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      title: title ?? this.title,
      description: description ?? this.description,
      rateAmount: rateAmount ?? this.rateAmount,
      rateType: rateType ?? this.rateType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
