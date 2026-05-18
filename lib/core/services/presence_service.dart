import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class PresenceService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _connectionSubscription;

  void initialize(String userId) {
    final presenceRef = _database.ref('users/$userId/presence');
    final userFirestoreRef = _firestore.collection(AppConstants.USERS).doc(userId);

    _connectionSubscription = _database.ref('.info/connected').onValue.listen((event) async {
      final connected = event.snapshot.value as bool? ?? false;
      if (connected) {
        // Configure onDisconnect for Realtime Database
        await presenceRef.onDisconnect().set({
          'isOnline': false,
          'lastSeen': ServerValue.timestamp,
        });

        // Set online status in Realtime Database
        await presenceRef.set({
          'isOnline': true,
          'lastSeen': ServerValue.timestamp,
        });

        // Update Firestore for online status
        await userFirestoreRef.update({
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> setOffline(String userId) async {
    final presenceRef = _database.ref('users/$userId/presence');
    final userFirestoreRef = _firestore.collection(AppConstants.USERS).doc(userId);

    await presenceRef.set({
      'isOnline': false,
      'lastSeen': ServerValue.timestamp,
    });

    await userFirestoreRef.update({
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  void dispose() {
    _connectionSubscription?.cancel();
  }
}
