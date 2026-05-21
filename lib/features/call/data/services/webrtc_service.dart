import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;

  Function(RTCIceCandidate)? onIceCandidate;
  Function(MediaStream)? onAddRemoteStream;
  Function(RTCPeerConnectionState)? onConnectionState;

  Future<void> initialize(bool isVideo) async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {
          'urls': [
            'stun:stun.l.google.com:19302',
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302',
          ]
        }
      ],
      'sdpSemantics': 'unified-plan',
    };

    final Map<String, dynamic> constraints = {
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };

    // 1. Create Peer Connection
    _peerConnection = await createPeerConnection(configuration, constraints);

    // 2. Configure Peer Connection Listeners
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (onIceCandidate != null) {
        onIceCandidate!(candidate);
      }
    };

    _peerConnection!.onAddStream = (MediaStream stream) {
      remoteStream = stream;
      if (onAddRemoteStream != null) {
        onAddRemoteStream!(stream);
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      if (onConnectionState != null) {
        onConnectionState!(state);
      }
    };

    // 3. Get User Media and Add to Peer Connection
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': isVideo
          ? {
              'mandatory': {
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': [],
            }
          : false,
    };

    localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, localStream!);
    });
  }

  Future<RTCSessionDescription> createOffer() async {
    if (_peerConnection == null) throw Exception('Peer Connection not initialized');
    
    final Map<String, dynamic> constraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [],
    };

    final offer = await _peerConnection!.createOffer(constraints);
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer(RTCSessionDescription offer) async {
    if (_peerConnection == null) throw Exception('Peer Connection not initialized');

    final Map<String, dynamic> constraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [],
    };

    await _peerConnection!.setRemoteDescription(offer);
    final answer = await _peerConnection!.createAnswer(constraints);
    await _peerConnection!.setLocalDescription(answer);
    return answer;
  }

  Future<void> setRemoteDescription(RTCSessionDescription desc) async {
    if (_peerConnection == null) throw Exception('Peer Connection not initialized');
    await _peerConnection!.setRemoteDescription(desc);
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection == null) throw Exception('Peer Connection not initialized');
    await _peerConnection!.addCandidate(candidate);
  }

  Future<void> dispose() async {
    if (localStream != null) {
      for (final track in localStream!.getTracks()) {
        await track.stop();
      }
      await localStream!.dispose();
      localStream = null;
    }
    if (remoteStream != null) {
      for (final track in remoteStream!.getTracks()) {
        await track.stop();
      }
      await remoteStream!.dispose();
      remoteStream = null;
    }
    if (_peerConnection != null) {
      await _peerConnection!.close();
      await _peerConnection!.dispose();
      _peerConnection = null;
    }
  }
}
