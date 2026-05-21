import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import '../router/app_router.dart';
import '../di/injection.dart';
import '../../features/call/domain/models/call_model.dart';
import '../../features/call/presentation/bloc/call_bloc.dart';
import '../../features/call/presentation/bloc/call_event.dart' hide CallEvent;
import '../../main.dart';

class NotificationService {
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (isMockMode) {
      debugPrint('Notification Service: Running in Mock Mode');
      return;
    }

    try {
      // 1. Request Notification Permissions
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // 2. Initialize Local Notifications for Foreground Messaging
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings =
          InitializationSettings(android: androidSettings);
      
      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          if (details.payload != null) {
            // Parse payloads and navigate if clicked
          }
        },
      );

      // Create default channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'default_channel',
        'Default Notifications',
        description: 'Channel for general messaging',
        importance: Importance.max,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 3. Listen to foreground FCM messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final type = message.data['type'];
        if (type == 'incoming_call') {
          final callerName = message.data['callerName'] ?? 'Unknown Caller';
          final callerPhoto = message.data['callerPhoto'] ?? '';
          final callId = message.data['callId'] ?? '';
          final isVideo = message.data['isVideo'] == 'true';
          showIncomingCallNotification(callerName, callerPhoto, callId, isVideo);
        } else {
          final notification = message.notification;
          if (notification != null) {
            _localNotifications.show(
              id: notification.hashCode,
              title: notification.title,
              body: notification.body,
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'default_channel',
                  'Default Notifications',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
              ),
            );
          }
        }
      });

      // 4. Handle clicks/opens when app is running in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationRouting);
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationRouting(initialMessage);
      }

      // 5. Track/Update User FCM Token
      _trackFcmToken();

      // 6. Listen to Native CallKit actions (Declined/Accepted)
      _listenToCallKitEvents();
    } catch (e) {
      debugPrint('Notification Service initialization error: $e');
    }
  }

  void _handleNotificationRouting(RemoteMessage message) {
    final type = message.data['type'];
    if (type == 'incoming_call') {
      final callId = message.data['callId'] ?? '';
      final isVideo = message.data['isVideo'] == 'true';
      final callerName = message.data['callerName'] ?? 'User';
      final callerPhoto = message.data['callerPhoto'];
      
      appRouter.push(
        isVideo ? '/video-call/$callId' : '/audio-call/$callId',
        extra: {
          'otherUserName': callerName,
          'otherUserPhoto': callerPhoto,
          'isOutgoing': false,
        },
      );
    } else if (type == 'chat') {
      final chatId = message.data['chatId'] ?? '';
      final senderName = message.data['senderName'] ?? 'Chat';
      appRouter.push('/chat/$chatId', extra: senderName);
    }
  }

  Future<void> showIncomingCallNotification(
    String callerName,
    String callerPhoto,
    String callId,
    bool isVideo,
  ) async {
    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'HeloAppa',
      avatar: callerPhoto.isNotEmpty ? callerPhoto : null,
      handle: 'HeloAppa Call',
      type: isVideo ? 1 : 0, // 0: Audio, 1: Video
      duration: 30000,
      android: const AndroidParams(
        isImportant: true,
        ringtonePath: 'system_ringtone_default',
        actionColor: '#6C63FF',
      ),
      ios: const IOSParams(
        iconName: 'CallKitIcon',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  void _listenToCallKitEvents() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;

      final callId = event.body['id'] as String?;
      if (callId == null || callId.isEmpty) return;

      switch (event.event) {
        case Event.actionCallAccept:
          final isVideo = event.body['type'] == 1;
          final callerName = event.body['nameCaller'] as String? ?? 'User';
          final callerPhoto = event.body['avatar'] as String?;

          // Navigate to the call screen
          appRouter.push(
            isVideo ? '/video-call/$callId' : '/audio-call/$callId',
            extra: {
              'otherUserName': callerName,
              'otherUserPhoto': callerPhoto,
              'isOutgoing': false,
            },
          );

          if (!isMockMode) {
            // Retrieve active CallModel from Realtime DB to get Offer SDP, then trigger BLoC Accept
            FirebaseDatabase.instance.ref('calls/$callId').get().then((snapshot) {
              if (snapshot.exists && snapshot.value != null) {
                try {
                  final map = Map<String, dynamic>.from(snapshot.value as Map);
                  final call = CallModel.fromMap(map);
                  sl<CallBloc>().add(AcceptCall(call));
                } catch (_) {}
              }
            });
          }
          break;

        case Event.actionCallDecline:
          sl<CallBloc>().add(RejectCall(callId));
          break;

        default:
          break;
      }
    });
  }

  Future<void> _trackFcmToken() async {
    if (isMockMode) return;
    try {
      // Write token if user is already authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _updateTokenInFirestore(user.uid);
      }

      // React to token refreshes
      _fcm.onTokenRefresh.listen((token) async {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await FirebaseFirestore.instance
              .collection('USERS')
              .doc(currentUser.uid)
              .update({'fcmToken': token});
        }
      });

      // Also update on AuthStateChanges via AuthBloc or direct listener
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user != null) {
          await _updateTokenInFirestore(user.uid);
        }
      });
    } catch (_) {}
  }

  Future<void> _updateTokenInFirestore(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('USERS')
            .doc(uid)
            .update({'fcmToken': token});
      }
    } catch (_) {
      // User doc might not exist yet, ignore
    }
  }
}
