import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../constants/app_constants.dart';
import '../../main.dart';

class PresenceService {
  StreamSubscription<DatabaseEvent>? _connectedSubscription;
  StreamSubscription<DatabaseEvent>? _presenceSubscription;
  String? _currentUserId;

  void initialize(String userId) {
    if (isMockMode) return;
    if (_currentUserId == userId) return; // Already initialized for this user
    dispose(); // Clean up any previous listeners
    
    _currentUserId = userId;
    final database = FirebaseDatabase.instance;
    final firestore = FirebaseFirestore.instance;

    final presenceRef = database.ref("users/$userId/presence");
    final connectedRef = database.ref(".info/connected");

    // 1. Listen to RTDB presence path to sync with Firestore
    _presenceSubscription = presenceRef.onValue.listen((event) async {
      final snapshotValue = event.snapshot.value;
      if (snapshotValue != null) {
        try {
          final data = Map<dynamic, dynamic>.from(snapshotValue as Map);
          final isOnline = data['isOnline'] as bool? ?? false;
          final lastSeenTimestamp = data['lastSeen'] as int? ?? DateTime.now().millisecondsSinceEpoch;

          await firestore.collection(AppConstants.USERS).doc(userId).update({
            'isOnline': isOnline,
            'lastSeen': lastSeenTimestamp,
          });
        } catch (e) {
          // Silently handle if update fails
        }
      }
    });

    // 2. Listen to connection status to set up active state and onDisconnect hook
    _connectedSubscription = connectedRef.onValue.listen((event) async {
      final connected = event.snapshot.value as bool? ?? false;
      if (connected) {
        await presenceRef.onDisconnect().set({
          'isOnline': false,
          'lastSeen': ServerValue.timestamp,
        });

        await presenceRef.set({
          'isOnline': true,
          'lastSeen': ServerValue.timestamp,
        });
      }
    });
  }

  void dispose() {
    if (isMockMode) return;
    _connectedSubscription?.cancel();
    _presenceSubscription?.cancel();
    _connectedSubscription = null;
    _presenceSubscription = null;
    
    final userId = _currentUserId;
    if (userId != null) {
      try {
        final database = FirebaseDatabase.instance;
        final firestore = FirebaseFirestore.instance;

        database.ref("users/$userId/presence").set({
          'isOnline': false,
          'lastSeen': ServerValue.timestamp,
        });
        
        firestore.collection(AppConstants.USERS).doc(userId).update({
          'isOnline': false,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
        });
      } catch (e) {
        // Silently handle error
      }
    }
    _currentUserId = null;
  }
}
