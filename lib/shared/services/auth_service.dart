import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rang_adda/shared/models/user_model.dart';

final authProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final userProvider = StreamProvider<User?>((ref) {
  if (Firebase.apps.isEmpty) return Stream.value(null);
  return FirebaseAuth.instance.userChanges();
});

class AuthService {
  FirebaseAuth? get _auth =>
      Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null;
  FirebaseFirestore? get _db =>
      Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;

  Future<User?> signInAnonymously(String displayName) async {
    if (_auth == null || _db == null) return null;
    UserCredential result = await _auth!.signInAnonymously();
    User? user = result.user;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await user.reload();

      // Create user profile in Firestore
      final userRef = _db!.collection('users').doc(user.uid);
      final doc = await userRef.get();
      if (!doc.exists) {
        final newUser = UserModel(
          uid: user.uid,
          displayName: displayName,
          createdAt: DateTime.now(),
        );
        await userRef.set(newUser.toJson());
      }

      return _auth!.currentUser;
    }
    return null;
  }

  Future<void> signOut() async {
    if (_auth != null) await _auth!.signOut();
  }

  Future<void> updateDisplayName(String newName) async {
    if (_auth == null || _db == null) return;
    final user = _auth!.currentUser;
    if (user == null) return;

    await user.updateDisplayName(newName);
    await user.reload();

    // Update Firestore user doc
    final userRef = _db!.collection('users').doc(user.uid);
    await userRef.update({'displayName': newName});
  }
}
