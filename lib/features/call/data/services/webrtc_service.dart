import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;

  Function(RTCIceCandidate)? onIceCandidate;
  Function(MediaStream)? onAddRemoteStream;
  Function(RTCPeerConnectionState)? onConnectionState;

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  Future<void> initialize(bool isVideo) async {
    _peerConnection = await createPeerConnection(_configuration, _constraints);

    _peerConnection!.onIceCandidate = (candidate) {
      onIceCandidate?.call(candidate);
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        onAddRemoteStream?.call(remoteStream!);
      }
    };

    _peerConnection!.onConnectionState = (state) {
      onConnectionState?.call(state);
    };

    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': isVideo ? {'facingMode': 'user'} : false,
    };

    localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    
    localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, localStream!);
    });
  }

  Future<RTCSessionDescription> createOffer() async {
    RTCSessionDescription offer = await _peerConnection!.createOffer(_constraints);
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer(RTCSessionDescription offer) async {
    await _peerConnection!.setRemoteDescription(offer);
    RTCSessionDescription answer = await _peerConnection!.createAnswer(_constraints);
    await _peerConnection!.setLocalDescription(answer);
    return answer;
  }

  Future<void> setRemoteDescription(RTCSessionDescription desc) async {
    await _peerConnection!.setRemoteDescription(desc);
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    await _peerConnection!.addIceCandidate(candidate);
  }

  Future<void> dispose() async {
    localStream?.getTracks().forEach((track) => track.stop());
    localStream?.dispose();
    remoteStream?.dispose();
    await _peerConnection?.close();
    _peerConnection = null;
  }
}
