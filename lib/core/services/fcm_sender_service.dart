import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FcmSenderService {
  final Dio _dio = Dio();

  Future<void> sendCallNotification({
    required String receiverFcmToken,
    required String callerName,
    required String callerPhoto,
    required String callId,
    required bool isVideo,
  }) async {
    final projectId = Firebase.app().options.projectId;
    final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

    // FCM HTTP v1 message structure
    final Map<String, dynamic> payload = {
      'message': {
        'token': receiverFcmToken,
        'data': {
          'type': 'incoming_call',
          'callId': callId,
          'callerName': callerName,
          'callerPhoto': callerPhoto,
          'isVideo': isVideo.toString(),
        },
        'android': {
          'priority': 'high',
          'ttl': '30s',
        },
        'apns': {
          'headers': {
            'apns-priority': '10',
            'apns-expiration': '0',
          },
          'payload': {
            'aps': {
              'content-available': 1,
            },
          },
        },
      }
    };

    try {
      final accessToken = await _getOAuth2Token();
      
      // In development/test environments, the token might be a mock.
      // In production, FCM v1 requires a valid OAuth2 Bearer token generated securely.
      if (accessToken == 'MOCK_TOKEN_USE_FIREBASE_FUNCTIONS_IN_PRODUCTION') {
        debugPrint('FCM: Mock token bypass. FCM messages should be sent via a secure server environment.');
        return;
      }

      await _dio.post(
        url,
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );
    } catch (e) {
      debugPrint('FCM sending failed: $e');
    }
  }

  Future<String> _getOAuth2Token() async {
    // TODO: Secure production setup:
    // To generate Google OAuth2 tokens securely on a backend server or a Firebase Cloud Function:
    // 1. Install 'googleapis_auth' package.
    // 2. Load Google Service Account JSON credentials.
    // 3. Request credentials access client:
    //    final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
    //    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    //    final client = await clientViaServiceAccount(credentials, scopes);
    //    return client.credentials.accessToken.data;
    //
    // For local frontend testing/mock purposes, we return a mock token:
    return 'MOCK_TOKEN_USE_FIREBASE_FUNCTIONS_IN_PRODUCTION';
  }
}
