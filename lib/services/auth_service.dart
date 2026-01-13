import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munokolive_music/utils/rate_limiter.dart';
import 'security_service.dart';
import 'local_database_service.dart';
import '../models/user_profile.dart';

final discreteModeProvider = StateProvider<bool>((ref) => false);

final authServiceProvider = Provider<AuthService>((ref) {
  final securityService = ref.read(securityServiceProvider);
  final localDatabaseService = ref.read(localDatabaseServiceProvider);
  return AuthService(securityService, localDatabaseService);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.read(authServiceProvider).getUserProfileStream(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SecurityService _securityService;
  final LocalDatabaseService _localDatabaseService;
  final RateLimiter _rateLimiter = RateLimiter(
    maxRequests: 5,
    duration: const Duration(minutes: 1),
  );

  AuthService(this._securityService, this._localDatabaseService);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    if (!_rateLimiter.canRequest()) {
      throw FirebaseAuthException(
        code: 'rate-limited',
        message: 'Trop de tentatives. Veuillez patienter un moment.',
      );
    }
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user != null) {
      await ensureUserDoc(cred.user!);
    }
    return cred;
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    if (!_rateLimiter.canRequest()) {
      throw FirebaseAuthException(
        code: 'rate-limited',
        message: 'Trop de tentatives. Veuillez patienter un moment.',
      );
    }
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user != null) {
      await ensureUserDoc(cred.user!);
    }
    return cred;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // Secure data destruction on logout
    await _localDatabaseService.deleteDatabaseFile();
    await _securityService.secureWipe();
  }

  Future<void> ensureUserDoc(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      // Check if user is the super admin
      String initialStatus = 'pending';
      if (user.email == 'munokolive@gmail.com') {
        initialStatus = 'validated_admin';
      }

      final profile = UserProfile(
        uid: user.uid,
        firstName: '',
        lastName: '',
        email: user.email,
        phone: user.phoneNumber,
        photoUrl: user.photoURL,
        category: 'Membre',
        status: initialStatus,
        createdAt: DateTime.now(),
      );
      await docRef.set(profile.toJson());
    } else {
      // If user exists, force update status if it is the super admin
      if (user.email == 'munokolive@gmail.com') {
        final data = snapshot.data();
        if (data != null && data['status'] != 'validated_admin') {
          await docRef.update({'status': 'validated_admin'});
        }
      }
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _firestore
        .collection('users')
        .doc(profile.uid)
        .set(profile.toJson(), SetOptions(merge: true));
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromJson(doc.data()!);
    }
    return null;
  }

  Stream<UserProfile?> getUserProfileStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromJson(doc.data()!) : null);
  }

  Stream<List<UserProfile>> getAllUsersStream() {
    return _firestore
        .collection('users')
        .where('status', isEqualTo: 'active') // Only show active users
        .limit(100) // Limit to avoid massive reads
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserProfile.fromJson(doc.data()))
              .toList();
        });
  }

  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    // Simple search implementation
    // Note: Firestore doesn't support full-text search natively.
    // We'll search by firstName for this implementation.
    final querySnapshot = await _firestore
        .collection('users')
        .where('firstName', isGreaterThanOrEqualTo: query)
        .where('firstName', isLessThan: '${query}z')
        .limit(10)
        .get();

    return querySnapshot.docs
        .map((doc) => UserProfile.fromJson(doc.data()))
        .toList();
  }
}
