import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  Stream<UserModel?> getUserData() {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  Future<void> saveUserData(UserModel user) async {
    await _firestore.collection('users').doc(uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<String?> saveLocalImage(File image, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final extension = p.extension(image.path);
      final uniqueFileName = '${uid}_$fileName$extension';
      await image.copy('$path/$uniqueFileName');
      return uniqueFileName; // Return only the filename
    } catch (e) {
      debugPrint('Error saving local image: $e');
      return null;
    }
  }

  Future<String> getLocalPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }
}
