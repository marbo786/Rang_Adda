import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rang_adda/shared/services/auth_service.dart';
import 'package:rang_adda/shared/models/user_model.dart';
import 'package:rang_adda/shared/services/firestore_service.dart';

final userProfileProvider = StreamProvider<UserModel?>((ref) {
  if (Firebase.apps.isEmpty) return Stream.value(null);

  final user = ref.watch(userProvider).value;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromJson(doc.data()!) : null);
});

final leaderboardProvider = FutureProvider<List<UserModel>>((ref) async {
  if (Firebase.apps.isEmpty) return [];
  return ref.read(firestoreServiceProvider).getLeaderboard();
});
