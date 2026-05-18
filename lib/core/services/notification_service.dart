import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import '../di/injection.dart';
import '../../features/call/domain/repositories/call_repository.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get token and save
      String? token = await _fcm.getToken();
      if (token != null) {
        _saveTokenToFirestore(token);
      }
    }

    // Refresh token listener
    _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

    // Local notifications setup
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _localNotifications.initialize(initializationSettings);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'incoming_call') {
        showIncomingCallNotification(
          message.data['callerName'],
          message.data['callerPhoto'] ?? '',
          message.data['callId'],
          message.data['isVideo'] == 'true',
        );
      } else {
        _showLocalNotification(message);
      }
    });

    // Handle background click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle navigation if needed
    });
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection(AppConstants.USERS)
          .doc(user.uid)
          .update({'fcmToken': token});
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'helo_appa_channel',
      'HeloAppa Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _localNotifications.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  Future<void> showIncomingCallNotification(
      String callerName, String callerPhoto, String callId, bool isVideo) async {
    CallKitParams params = CallKitParams(
      id: const Uuid().v4(),
      nameCaller: callerName,
      appName: AppConstants.appName,
      avatar: callerPhoto,
      handle: '0123456789',
      type: isVideo ? 1 : 0,
      duration: 30000,
      textAccept: 'Accept',
      textDecline: 'Decline',
      extra: <String, dynamic>{'callId': callId, 'isVideo': isVideo},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        backgroundUrl: 'https://i.pravatar.cc/500',
        actionColor: '#4CAF50',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);

    FlutterCallkitIncoming.onEvent.listen((event) async {
      switch (event!.event) {
        case Event.actionCallAccept:
          // User accepted the call. Navigate to call screen via app state/router
          break;
        case Event.actionCallDecline:
          await sl<CallRepository>().rejectCall(callId);
          break;
        default:
          break;
      }
    });
  }
}
