import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/call_model.dart';

abstract class CallRepository {
  Future<String> initiateCall(CallModel call);
  Future<void> sendOffer(String callId, RTCSessionDescription offer);
  Future<void> answerCall(String callId, RTCSessionDescription answer);
  Future<void> rejectCall(String callId);
  Future<void> endCall(String callId);
  Future<void> sendIceCandidate(String callId, String senderId, RTCIceCandidate candidate);
  Stream<CallModel?> listenForIncomingCall(String userId);
  Stream<Map<String, dynamic>?> listenForOffer(String callId);
  Stream<Map<String, dynamic>?> listenForAnswer(String callId);
  Stream<List<Map<String, dynamic>>> listenForIceCandidates(String callId, String senderId);
}
