import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../domain/models/call_model.dart';

abstract class CallEvent extends Equatable {
  const CallEvent();

  @override
  List<Object?> get props => [];
}

class StartCall extends CallEvent {
  final String callerId;
  final String callerName;
  final String? callerPhoto;
  final String receiverId;
  final bool isVideo;

  const StartCall({
    required this.callerId,
    required this.callerName,
    this.callerPhoto,
    required this.receiverId,
    required this.isVideo,
  });

  @override
  List<Object?> get props => [callerId, callerName, callerPhoto, receiverId, isVideo];
}

class AcceptCall extends CallEvent {
  final CallModel call;
  const AcceptCall(this.call);

  @override
  List<Object?> get props => [call];
}

class RejectCall extends CallEvent {
  final String callId;
  const RejectCall(this.callId);

  @override
  List<Object?> get props => [callId];
}

class EndCall extends CallEvent {
  final String callId;
  const EndCall(this.callId);

  @override
  List<Object?> get props => [callId];
}

class IceCandidateReceived extends CallEvent {
  final RTCIceCandidate candidate;
  const IceCandidateReceived(this.candidate);

  @override
  List<Object?> get props => [candidate];
}

class RemoteStreamReceived extends CallEvent {
  final MediaStream stream;
  const RemoteStreamReceived(this.stream);

  @override
  List<Object?> get props => [stream];
}

class _UpdateIncomingCall extends CallEvent {
  final CallModel? call;
  const _UpdateIncomingCall(this.call);
}

class _UpdateAnswerReceived extends CallEvent {
  final Map<String, dynamic> answer;
  const _UpdateAnswerReceived(this.answer);
}
