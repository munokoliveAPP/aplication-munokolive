import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getPendingAdminRequests() {
    return _firestore
        .collection('users')
        .where('status', whereIn: ['pending', 'pending_admin'])
        .snapshots();
  }

  Future<void> validateAdmin(String uid) async {
    // Valider un admin ou un utilisateur standard
    await _firestore.collection('users').doc(uid).update({
      'status': 'validated_admin', // ou 'active' selon la logique
      'isValidated': true,
    });
  }

  Future<void> validateUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'status': 'active',
      'isValidated': true,
    });
  }

  Future<void> rejectUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'status': 'rejected',
      'isValidated': false,
    });
  }

  Future<void> assignAdmin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'status': 'admin',
      'category': 'Admin',
    });
  }

  Future<void> removeAdmin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'status': 'member',
      'category': 'Membre',
    });
  }
}
