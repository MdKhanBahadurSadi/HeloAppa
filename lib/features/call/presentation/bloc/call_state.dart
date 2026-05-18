import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../domain/models/call_model.dart';

abstract class CallState extends Equatable {
  const CallState();

  @override
  List<Object?> get props => [];
}

class CallIdle extends CallState {}

class CallOutgoing extends CallState {
  final CallModel call;
  const CallOutgoing(this.call);

  @override
  List<Object?> get props => [call];
}

class CallIncoming extends CallState {
  final CallModel call;
  const CallIncoming(this.call);

  @override
  List<Object?> get props => [call];
}

class CallActive extends CallState {
  final CallModel call;
  final MediaStream? localStream;
  final MediaStream? remoteStream;

  const CallActive(this.call, this.localStream, this.remoteStream);

  @override
  List<Object?> get props => [call, localStream, remoteStream];
}

class CallEnded extends CallState {}

class CallError extends CallState {
  final String message;
  const CallError(this.message);

  @override
  List<Object?> get props => [message];
}
