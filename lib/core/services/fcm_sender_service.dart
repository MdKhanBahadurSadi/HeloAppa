import 'package:dio/dio.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'dart:developer' as dev;
import '../constants/app_constants.dart';

class FcmSenderService {
  final Dio _dio = Dio();
  final String _projectId = AppConstants.firebaseProjectId;

  Future<void> sendCallNotification({
    required String receiverFcmToken,
    required String callerName,
    required String callerPhoto,
    required String callId,
    required bool isVideo,
  }) async {
    try {
      final String accessToken = await _getAccessToken();

      final String url = 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
        data: {
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
            },
          }
        },
      );

      dev.log('FCM Response: ${response.data}');
    } catch (e) {
      dev.log('Error sending FCM: $e');
    }
  }

  Future<String> _getAccessToken() async {
    // TODO: In production, do NOT store service account JSON on the client.
    // Use a Firebase Cloud Function to handle FCM sending instead.
    // This is for demonstration purposes of FCM HTTP v1 API.
    
    /* 
    final serviceAccountJson = { ... }; 
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson), scopes);
    return client.credentials.accessToken.data;
    */
    
    return 'YOUR_ACCESS_TOKEN'; // Mock token or use Firebase Functions
  }
}
