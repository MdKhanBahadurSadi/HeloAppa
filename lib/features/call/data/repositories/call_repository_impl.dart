import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../domain/models/call_model.dart';
import '../../domain/repositories/call_repository.dart';

class CallRepositoryImpl implements CallRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  @override
  Future<String> initiateCall(CallModel call) async {
    final callId = call.callId;
    final callMap = call.toMap();

    // 1. Write call session to RTDB calls/{callId}
    await _db.ref('calls/$callId').set(callMap);

    // 2. Set receiver's incomingCall details so they react
    await _db.ref('users/${call.receiverId}/incomingCall').set(callMap);

    return callId;
  }

  @override
  Future<void> answerCall(String callId, RTCSessionDescription answer) async {
    final callRef = _db.ref('calls/$callId');

    // Update status to active
    await callRef.update({
      'status': CallStatus.active.name,
    });

    // Write answer SDP
    await callRef.child('answer').set({
      'sdp': answer.sdp,
      'type': answer.type,
    });
  }

  @override
  Future<void> rejectCall(String callId) async {
    final callRef = _db.ref('calls/$callId');
    final snapshot = await callRef.get();

    if (snapshot.exists) {
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final receiverId = data['receiverId'] as String?;

      // Update call session status to rejected
      await callRef.update({
        'status': CallStatus.rejected.name,
      });

      // Clear incoming call from receiver's path
      if (receiverId != null) {
        await _db.ref('users/$receiverId/incomingCall').remove();
      }
    }
  }

  @override
  Future<void> endCall(String callId) async {
    final callRef = _db.ref('calls/$callId');
    final snapshot = await callRef.get();

    if (snapshot.exists) {
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final receiverId = data['receiverId'] as String?;

      // Update call session status to ended
      await callRef.update({
        'status': CallStatus.ended.name,
      });

      // Clear incoming call from receiver's path
      if (receiverId != null) {
        await _db.ref('users/$receiverId/incomingCall').remove();
      }
    }
  }

  @override
  Future<void> sendIceCandidate(String callId, String senderId, RTCIceCandidate candidate) async {
    final candidateRef = _db.ref('calls/$callId/candidates/$senderId').push();
    await candidateRef.set({
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    });
  }

  @override
  Stream<CallModel?> listenForIncomingCall(String userId) {
    return _db.ref('users/$userId/incomingCall').onValue.map((event) {
      final value = event.snapshot.value;
      if (value != null) {
        try {
          final map = Map<String, dynamic>.from(value as Map);
          return CallModel.fromMap(map);
        } catch (_) {
          return null;
        }
      }
      return null;
    });
  }

  @override
  Stream<Map<String, dynamic>?> listenForAnswer(String callId) {
    return _db.ref('calls/$callId/answer').onValue.map((event) {
      final value = event.snapshot.value;
      if (value != null) {
        try {
          return Map<String, dynamic>.from(value as Map);
        } catch (_) {
          return null;
        }
      }
      return null;
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> listenForIceCandidates(String callId, String senderId) {
    return _db.ref('calls/$callId/candidates/$senderId').onValue.map((event) {
      final value = event.snapshot.value;
      if (value != null) {
        final list = <Map<String, dynamic>>[];
        try {
          if (value is Map) {
            value.forEach((key, val) {
              if (val != null) {
                list.add(Map<String, dynamic>.from(val as Map));
              }
            });
          }
        } catch (_) {}
        return list;
      }
      return const [];
    });
  }
}
