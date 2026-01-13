import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

// Provider for all users
final allUsersProvider = StreamProvider<List<UserProfile>>((ref) {
  return ref.read(authServiceProvider).getAllUsersStream();
});

// Auth State Provider
final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

// Provider for Current User Profile
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final userAsync = ref.watch(authStateProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value(null);

      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.exists ? UserProfile.fromJson(doc.data()!) : null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// Provider for specific User Profile by ID
final userProfileByIdProvider = StreamProvider.family<UserProfile?, String>((
  ref,
  userId,
) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) => doc.exists ? UserProfile.fromJson(doc.data()!) : null);
});
