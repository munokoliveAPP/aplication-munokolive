import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final imageUploadServiceProvider = Provider<ImageUploadService>(
  (ref) => ImageUploadService(),
);

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImage(String uid, File imageFile) async {
    final ref = _storage
        .ref()
        .child('user_profiles')
        .child(uid)
        .child('profile.jpg');
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    final uploadTask = ref.putFile(imageFile, metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
