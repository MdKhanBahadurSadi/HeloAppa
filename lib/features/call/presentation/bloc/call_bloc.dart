import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/fcm_sender_service.dart';
import '../../domain/models/call_model.dart';
import '../../domain/repositories/call_repository.dart';
import '../../data/services/webrtc_service.dart';
import 'call_event.dart';
import 'call_state.dart';
import '../../../../main.dart';

class CallBloc extends Bloc<CallEvent, CallState> {
  final CallRepository _callRepository;
  final Uuid _uuid = const Uuid();

  WebRTCService? _webRTCService;

  StreamSubscription? _incomingCallSubscription;
  StreamSubscription? _answerSubscription;
  StreamSubscription? _candidatesSubscription;
  StreamSubscription? _statusSubscription;

  CallBloc({required CallRepository callRepository})
      : _callRepository = callRepository,
        super(CallIdle()) {
    on<ListenForIncomingCalls>(_onListenForIncomingCalls);
    on<IncomingCallReceived>(_onIncomingCallReceived);
    on<StartCall>(_onStartCall);
    on<AcceptCall>(_onAcceptCall);
    on<RejectCall>(_onRejectCall);
    on<EndCall>(_onEndCall);
    on<IceCandidateReceived>(_onIceCandidateReceived);
    on<RemoteStreamReceived>(_onRemoteStreamReceived);
    on<CallStateUpdated>(_onCallStateUpdated);
  }

  void _onCallStateUpdated(CallStateUpdated event, Emitter<CallState> emit) {
    emit(event.state);
  }

  Future<void> _onListenForIncomingCalls(
    ListenForIncomingCalls event,
    Emitter<CallState> emit,
  ) async {
    await _incomingCallSubscription?.cancel();
    _incomingCallSubscription = _callRepository.listenForIncomingCall(event.userId).listen((call) {
      if (call != null) {
        if (call.status == CallStatus.ringing) {
          add(IncomingCallReceived(call));
        } else if (call.status == CallStatus.rejected || call.status == CallStatus.ended) {
          add(EndCall(call.callId));
        }
      }
    });
  }

  void _onIncomingCallReceived(
    IncomingCallReceived event,
    Emitter<CallState> emit,
  ) {
    if (state is! CallActive && state is! CallOutgoing && state is! CallIncoming) {
      emit(CallIncoming(event.call));
    }
  }

  Future<void> _onStartCall(
    StartCall event,
    Emitter<CallState> emit,
  ) async {
    try {
      final callId = _uuid.v4();
      String? receiverFcmToken;

      if (!isMockMode) {
        // Fetch receiver FCM token from Firestore
        final receiverSnapshot = await FirebaseFirestore.instance
            .collection('USERS')
            .doc(event.receiverId)
            .get();
        receiverFcmToken = receiverSnapshot.data()?['fcmToken'] as String?;
      }

      // 1. Initialize WebRTC Service
      _webRTCService = sl<WebRTCService>();
      await _webRTCService!.initialize(event.isVideo);

      // 2. Create local SDP offer
      final offer = await _webRTCService!.createOffer();

      // 3. Create Call Model
      final call = CallModel(
        callId: callId,
        callerId: event.callerId,
        callerName: event.callerName,
        callerPhoto: event.callerPhoto,
        receiverId: event.receiverId,
        status: CallStatus.ringing,
        isVideo: event.isVideo,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        offer: {
          'sdp': offer.sdp,
          'type': offer.type,
        },
      );

      // 4. Save call in database
      await _callRepository.initiateCall(call);

      // Send Call notification to receiver via FCM if token exists
      if (!isMockMode && receiverFcmToken != null && receiverFcmToken.isNotEmpty) {
        sl<FcmSenderService>().sendCallNotification(
          receiverFcmToken: receiverFcmToken,
          callerName: event.callerName,
          callerPhoto: event.callerPhoto,
          callId: callId,
          isVideo: event.isVideo,
        );
      }

      // 5. Setup WebRTC Callbacks
      _webRTCService!.onIceCandidate = (candidate) {
        _callRepository.sendIceCandidate(callId, event.callerId, candidate);
      };

      _webRTCService!.onAddRemoteStream = (stream) {
        add(RemoteStreamReceived(stream));
      };

      _webRTCService!.onConnectionState = (connectionState) {
        if (connectionState == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            connectionState == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            connectionState == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          add(EndCall(callId));
        }
      };

      // 6. Listen for connection status changes (ended/rejected)
      if (!isMockMode) {
        await _statusSubscription?.cancel();
        _statusSubscription = FirebaseDatabase.instance
            .ref('calls/$callId/status')
            .onValue
            .listen((dbEvent) {
          final status = dbEvent.snapshot.value as String?;
          if (status == 'ended' || status == 'rejected') {
            add(EndCall(callId));
          }
        });
      }

      // 7. Listen for answer SDP from the receiver
      await _answerSubscription?.cancel();
      _answerSubscription = _callRepository.listenForAnswer(callId).listen((answerMap) async {
        if (answerMap != null && _webRTCService != null) {
          final answerSdp = RTCSessionDescription(answerMap['sdp'], answerMap['type']);
          await _webRTCService!.setRemoteDescription(answerSdp);

          final currentState = state;
          if (currentState is CallOutgoing) {
            add(CallStateUpdated(CallActive(
              currentState.call.copyWith(status: CallStatus.active),
              localStream: _webRTCService!.localStream,
              remoteStream: _webRTCService!.remoteStream,
            )));
          }
        }
      });

      // 8. Listen for receiver ICE Candidates
      await _candidatesSubscription?.cancel();
      _candidatesSubscription = _callRepository
          .listenForIceCandidates(callId, event.receiverId)
          .listen((candidatesList) {
        if (_webRTCService != null) {
          for (final candidateMap in candidatesList) {
            final candidate = RTCIceCandidate(
              candidateMap['candidate'],
              candidateMap['sdpMid'],
              candidateMap['sdpMLineIndex'],
            );
            _webRTCService!.addIceCandidate(candidate);
          }
        }
      });

      emit(CallOutgoing(call));
    } catch (e) {
      emit(CallError(e.toString()));
    }
  }

  Future<void> _onAcceptCall(
    AcceptCall event,
    Emitter<CallState> emit,
  ) async {
    try {
      final call = event.call;

      // 1. Initialize WebRTC Service
      _webRTCService = sl<WebRTCService>();
      await _webRTCService!.initialize(call.isVideo);

      // 2. Setup WebRTC Callbacks
      _webRTCService!.onIceCandidate = (candidate) {
        _callRepository.sendIceCandidate(call.callId, call.receiverId, candidate);
      };

      _webRTCService!.onAddRemoteStream = (stream) {
        add(RemoteStreamReceived(stream));
      };

      _webRTCService!.onConnectionState = (connectionState) {
        if (connectionState == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            connectionState == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            connectionState == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          add(EndCall(call.callId));
        }
      };

      // 3. Set Remote Description (Caller's Offer SDP)
      if (call.offer == null) throw Exception('SDP Offer is missing from Call Session');
      final offerSdp = RTCSessionDescription(call.offer!['sdp'], call.offer!['type']);
      
      // 4. Create Answer SDP and set local description
      final answer = await _webRTCService!.createAnswer(offerSdp);

      // 5. Save answer to DB
      await _callRepository.answerCall(call.callId, answer);

      // 6. Listen for connection status changes (ended/rejected)
      if (!isMockMode) {
        await _statusSubscription?.cancel();
        _statusSubscription = FirebaseDatabase.instance
            .ref('calls/${call.callId}/status')
            .onValue
            .listen((dbEvent) {
          final status = dbEvent.snapshot.value as String?;
          if (status == 'ended' || status == 'rejected') {
            add(EndCall(call.callId));
          }
        });
      }

      // 7. Listen for caller ICE Candidates
      await _candidatesSubscription?.cancel();
      _candidatesSubscription = _callRepository
          .listenForIceCandidates(call.callId, call.callerId)
          .listen((candidatesList) {
        if (_webRTCService != null) {
          for (final candidateMap in candidatesList) {
            final candidate = RTCIceCandidate(
              candidateMap['candidate'],
              candidateMap['sdpMid'],
              candidateMap['sdpMLineIndex'],
            );
            _webRTCService!.addIceCandidate(candidate);
          }
        }
      });

      emit(CallActive(
        call.copyWith(status: CallStatus.active),
        localStream: _webRTCService!.localStream,
        remoteStream: _webRTCService!.remoteStream,
      ));
    } catch (e) {
      emit(CallError(e.toString()));
    }
  }

  Future<void> _onRejectCall(
    RejectCall event,
    Emitter<CallState> emit,
  ) async {
    try {
      await _callRepository.rejectCall(event.callId);
      await _cleanupCall();
      emit(CallEnded());
    } catch (e) {
      emit(CallError(e.toString()));
    }
  }

  Future<void> _onEndCall(
    EndCall event,
    Emitter<CallState> emit,
  ) async {
    try {
      await _callRepository.endCall(event.callId);
      await _cleanupCall();
      emit(CallEnded());
    } catch (e) {
      emit(CallError(e.toString()));
    }
  }

  Future<void> _onIceCandidateReceived(
    IceCandidateReceived event,
    Emitter<CallState> emit,
  ) async {
    await _webRTCService?.addIceCandidate(event.candidate);
  }

  void _onRemoteStreamReceived(
    RemoteStreamReceived event,
    Emitter<CallState> emit,
  ) {
    final currentState = state;
    if (currentState is CallActive) {
      emit(CallActive(
        currentState.call,
        localStream: currentState.localStream,
        remoteStream: event.stream,
      ));
    }
  }

  Future<void> _cleanupCall() async {
    await _answerSubscription?.cancel();
    await _candidatesSubscription?.cancel();
    await _statusSubscription?.cancel();
    _answerSubscription = null;
    _candidatesSubscription = null;
    _statusSubscription = null;

    if (_webRTCService != null) {
      await _webRTCService!.dispose();
      _webRTCService = null;
    }
  }

  @override
  Future<void> close() async {
    await _incomingCallSubscription?.cancel();
    await _cleanupCall();
    return super.close();
  }
}
