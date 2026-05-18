import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../domain/models/call_model.dart';
import '../../domain/repositories/call_repository.dart';

class CallRepositoryImpl implements CallRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  @override
  Future<String> initiateCall(CallModel call) async {
    await _database.ref('calls/${call.callId}').set(call.toMap());
    // Also notify receiver of incoming call
    await _database.ref('users/${call.receiverId}/incomingCall').set(call.toMap());
    return call.callId;
  }

  @override
  Future<void> sendOffer(String callId, RTCSessionDescription offer) async {
    await _database.ref('calls/$callId/offer').set({
      'sdp': offer.sdp,
      'type': offer.type,
    });
  }

  @override
  Future<void> answerCall(String callId, RTCSessionDescription answer) async {
    await _database.ref('calls/$callId/answer').set({
      'sdp': answer.sdp,
      'type': answer.type,
    });
    await _database.ref('calls/$callId').update({'status': 'active'});
  }

  @override
  Future<void> rejectCall(String callId) async {
    await _database.ref('calls/$callId').update({'status': 'rejected'});
    // Optionally clear incoming call on receiver's side
  }

  @override
  Future<void> endCall(String callId) async {
    await _database.ref('calls/$callId').update({'status': 'ended'});
  }

  @override
  Future<void> sendIceCandidate(String callId, String senderId, RTCIceCandidate candidate) async {
    await _database.ref('calls/$callId/candidates/$senderId').push().set({
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    });
  }

  @override
  Stream<CallModel?> listenForIncomingCall(String userId) {
    return _database.ref('users/$userId/incomingCall').onValue.map((event) {
      if (event.snapshot.value == null) return null;
      return CallModel.fromMap(Map<String, dynamic>.from(event.snapshot.value as Map));
    });
  }

  @override
  Stream<Map<String, dynamic>?> listenForOffer(String callId) {
    return _database.ref('calls/$callId/offer').onValue.map((event) {
      if (event.snapshot.value == null) return null;
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  @override
  Stream<Map<String, dynamic>?> listenForAnswer(String callId) {
    return _database.ref('calls/$callId/answer').onValue.map((event) {
      if (event.snapshot.value == null) return null;
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> listenForIceCandidates(String callId, String senderId) {
    return _database.ref('calls/$callId/candidates/$senderId').onValue.map((event) {
      if (event.snapshot.value == null) return [];
      final data = event.snapshot.value as Map;
      return data.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
  }
}
