import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/call_model.dart';
import '../../domain/repositories/call_repository.dart';
import '../../domain/repositories/contacts_repository.dart';
import '../../data/services/webrtc_service.dart';
import '../../../core/services/fcm_sender_service.dart';
import '../../../core/utils/error_handler.dart';
import 'call_event.dart';
import 'call_state.dart';

class CallBloc extends Bloc<CallEvent, CallState> {
  final CallRepository callRepository;
  final ContactsRepository contactsRepository;
  final FcmSenderService fcmSenderService;
  final WebRTCService Function() webRTCServiceFactory;
  
  WebRTCService? _webRTCService;
  StreamSubscription? _incomingCallSubscription;
  StreamSubscription? _answerSubscription;
  StreamSubscription? _iceCandidatesSubscription;
  StreamSubscription? _offerSubscription;

  CallBloc({
    required this.callRepository,
    required this.contactsRepository,
    required this.fcmSenderService,
    required this.webRTCServiceFactory,
  }) : super(CallIdle()) {
    on<StartCall>(_onStartCall);
    on<AcceptCall>(_onAcceptCall);
    on<RejectCall>(_onRejectCall);
    on<EndCall>(_onEndCall);
    on<IceCandidateReceived>(_onIceCandidateReceived);
    on<RemoteStreamReceived>(_onRemoteStreamReceived);
    on<_UpdateIncomingCall>(_onUpdateIncomingCall);
    on<_UpdateAnswerReceived>(_onUpdateAnswerReceived);
  }

  void listenForIncomingCalls(String userId) {
    _incomingCallSubscription?.cancel();
    _incomingCallSubscription = callRepository.listenForIncomingCall(userId).listen((call) {
      if (call != null && state is CallIdle) {
        add(_UpdateIncomingCall(call));
      }
    });
  }

  Future<void> _onStartCall(StartCall event, Emitter<CallState> emit) async {
    final callId = const Uuid().v4();
    final call = CallModel(
      callId: callId,
      callerId: event.callerId,
      callerName: event.callerName,
      callerPhoto: event.callerPhoto,
      receiverId: event.receiverId,
      status: CallStatus.ringing,
      isVideo: event.isVideo,
      createdAt: DateTime.now(),
    );

    try {
      await callRepository.initiateCall(call);

      final receiver = await contactsRepository.getUserById(event.receiverId);
      if (receiver != null) {
        // FCM sending logic would go here in production
      }

      _webRTCService = webRTCServiceFactory();
      await _webRTCService!.initialize(event.isVideo);
      
      _webRTCService!.onIceCandidate = (candidate) {
        callRepository.sendIceCandidate(callId, event.callerId, candidate);
      };
      
      _webRTCService!.onAddRemoteStream = (stream) {
        add(RemoteStreamReceived(stream));
      };

      final offer = await _webRTCService!.createOffer();
      await callRepository.sendOffer(callId, offer);

      emit(CallOutgoing(call));

      _answerSubscription?.cancel();
      _answerSubscription = callRepository.listenForAnswer(callId).listen((data) {
        if (data != null) add(_UpdateAnswerReceived(data));
      });

      _iceCandidatesSubscription?.cancel();
      _iceCandidatesSubscription = callRepository.listenForIceCandidates(callId, event.receiverId).listen((candidates) {
        for (var data in candidates) {
          final candidate = RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          );
          add(IceCandidateReceived(candidate));
        }
      });

    } catch (e) {
      emit(CallError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> _onAcceptCall(AcceptCall event, Emitter<CallState> emit) async {
    try {
      _webRTCService = webRTCServiceFactory();
      await _webRTCService!.initialize(event.call.isVideo);

      _webRTCService!.onIceCandidate = (candidate) {
        callRepository.sendIceCandidate(event.call.callId, event.call.receiverId, candidate);
      };

      _webRTCService!.onAddRemoteStream = (stream) {
        add(RemoteStreamReceived(stream));
      };

      _offerSubscription?.cancel();
      _offerSubscription = callRepository.listenForOffer(event.call.callId).listen((data) async {
        if (data != null) {
          final offer = RTCSessionDescription(data['sdp'], data['type']);
          final answer = await _webRTCService!.createAnswer(offer);
          await callRepository.answerCall(event.call.callId, answer);
          
          if (!emit.isDone) {
            emit(CallActive(event.call, _webRTCService!.localStream, _webRTCService!.remoteStream));
          }
        }
      });

      _iceCandidatesSubscription?.cancel();
      _iceCandidatesSubscription = callRepository.listenForIceCandidates(event.call.callId, event.call.callerId).listen((candidates) {
        for (var data in candidates) {
          final candidate = RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          );
          add(IceCandidateReceived(candidate));
        }
      });

    } catch (e) {
      emit(CallError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> _onUpdateAnswerReceived(_UpdateAnswerReceived event, Emitter<CallState> emit) async {
    if (state is CallOutgoing) {
      final call = (state as CallOutgoing).call;
      final answer = RTCSessionDescription(event.answer['sdp'], event.answer['type']);
      await _webRTCService!.setRemoteDescription(answer);
      emit(CallActive(call, _webRTCService!.localStream, _webRTCService!.remoteStream));
    }
  }

  void _onUpdateIncomingCall(_UpdateIncomingCall event, Emitter<CallState> emit) {
    emit(CallIncoming(event.call!));
  }

  Future<void> _onRejectCall(RejectCall event, Emitter<CallState> emit) async {
    await callRepository.rejectCall(event.callId);
    emit(CallEnded());
  }

  Future<void> _onEndCall(EndCall event, Emitter<CallState> emit) async {
    await _webRTCService?.dispose();
    await callRepository.endCall(event.callId);
    _answerSubscription?.cancel();
    _iceCandidatesSubscription?.cancel();
    _offerSubscription?.cancel();
    emit(CallEnded());
  }

  Future<void> _onIceCandidateReceived(IceCandidateReceived event, Emitter<CallState> emit) async {
    await _webRTCService?.addIceCandidate(event.candidate);
  }

  void _onRemoteStreamReceived(RemoteStreamReceived event, Emitter<CallState> emit) {
    if (state is CallActive) {
      final currentState = state as CallActive;
      emit(CallActive(currentState.call, currentState.localStream, event.stream));
    }
  }

  @override
  Future<void> close() {
    _incomingCallSubscription?.cancel();
    _answerSubscription?.cancel();
    _iceCandidatesSubscription?.cancel();
    _offerSubscription?.cancel();
    _webRTCService?.dispose();
    return super.close();
  }
}
