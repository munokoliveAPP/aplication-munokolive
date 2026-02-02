import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_model.dart';
import '../services/auth_service.dart';

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return ServicesRepository(Supabase.instance.client);
});

final providerServicesProvider =
    StreamProvider.family<List<ServiceModel>, String>((ref, userId) {
      // Force refresh on auth change (Token Refresh)
      ref.watch(authStateProvider);

      return ref
          .watch(servicesRepositoryProvider)
          .getServicesStreamByProvider(userId);
    });

class ServicesRepository {
  final SupabaseClient _supabase;

  ServicesRepository(this._supabase);

  Future<List<ServiceModel>> getServicesByProvider(String providerId) async {
    final response = await _supabase
        .from('services')
        .select()
        .eq('provider_id', providerId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (response as List).map((e) => ServiceModel.fromJson(e)).toList();
  }

  Stream<List<ServiceModel>> getServicesStreamByProvider(String providerId) {
    return _supabase
        .from('services')
        .stream(primaryKey: ['id'])
        .eq('provider_id', providerId)
        .order('created_at', ascending: false)
        .map(
          (data) => data
              .where(
                (element) => element['is_active'] == true,
              ) // Filter locally or use view if needed, but stream doesn't support complex filtering easily on all SDKs versions.
              // Actually supabase stream supports simple eq. But mixing multiple eqs and order is fine.
              // Let's check if 'is_active' needs to be in the stream query or filtered after.
              // .stream() query builder is limited. .eq is supported.
              // Let's try to include .eq('is_active', true) in the stream definition if possible.
              // The standard Supabase stream implementation allows .eq modifiers.
              .map((e) => ServiceModel.fromJson(e))
              .toList(),
        );
  }

  Future<void> createService(ServiceModel service) async {
    await _supabase.from('services').insert({
      'provider_id': _supabase.auth.currentUser!.id,
      'title': service.title,
      'description': service.description,
      'rate_amount': service.rateAmount,
      'rate_type': service.rateType,
    });
  }

  Future<void> updateService(ServiceModel service) async {
    await _supabase
        .from('services')
        .update({
          'title': service.title,
          'description': service.description,
          'rate_amount': service.rateAmount,
          'rate_type': service.rateType,
          'is_active': service.isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', service.id);
  }

  Future<void> deleteService(String serviceId) async {
    await _supabase.from('services').delete().eq('id', serviceId);
  }
}
