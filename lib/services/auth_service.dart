import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final userProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInAnonymously(String displayName) async {
    UserCredential result = await _auth.signInAnonymously();
    User? user = result.user;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await user.reload();
      return _auth.currentUser;
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
