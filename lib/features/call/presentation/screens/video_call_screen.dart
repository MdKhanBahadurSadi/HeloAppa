import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../domain/models/call_model.dart';
import '../bloc/call_bloc.dart';
import '../bloc/call_event.dart';
import '../bloc/call_state.dart';

class VideoCallScreen extends StatefulWidget {
  final String callId;
  final String otherUserName;
  final String? otherUserPhoto;
  final bool isOutgoing;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.otherUserName,
    this.otherUserPhoto,
    required this.isOutgoing,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isAudioMuted = false;
  bool _isVideoMuted = false;
  bool _showControls = true;
  bool _renderersInitialized = false;

  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _startHideControlsTimer();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    if (!mounted) return;
    final currentState = context.read<CallBloc>().state;
    if (currentState is CallActive) {
      if (currentState.localStream != null) {
        _localRenderer.srcObject = currentState.localStream;
      }
      if (currentState.remoteStream != null) {
        _remoteRenderer.srcObject = currentState.remoteStream;
      }
    }
    if (mounted) {
      setState(() {
        _renderersInitialized = true;
      });
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _onScreenTap() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  void _toggleAudio() {
    setState(() {
      _isAudioMuted = !_isAudioMuted;
    });
    final currentState = context.read<CallBloc>().state;
    if (currentState is CallActive && currentState.localStream != null) {
      for (final track in currentState.localStream!.getAudioTracks()) {
        track.enabled = !_isAudioMuted;
      }
    }
  }

  void _toggleVideo() {
    setState(() {
      _isVideoMuted = !_isVideoMuted;
    });
    final currentState = context.read<CallBloc>().state;
    if (currentState is CallActive && currentState.localStream != null) {
      for (final track in currentState.localStream!.getVideoTracks()) {
        track.enabled = !_isVideoMuted;
      }
    }
  }

  void _flipCamera() {
    final currentState = context.read<CallBloc>().state;
    if (currentState is CallActive && currentState.localStream != null) {
      final videoTrack = currentState.localStream!.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        Helper.switchCamera(videoTrack);
      }
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CallBloc, CallState>(
      listener: (context, state) {
        if (state is CallActive && _renderersInitialized) {
          if (state.localStream != null) {
            _localRenderer.srcObject = state.localStream;
          }
          if (state.remoteStream != null) {
            _remoteRenderer.srcObject = state.remoteStream;
          }
        } else if (state is CallEnded) {
          if (mounted && Navigator.canPop(context)) {
            context.pop();
          }
        } else if (state is CallError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Call Error: ${state.message}')),
          );
        }
      },
      builder: (context, state) {
        bool showAcceptReject = false;
        CallModel? currentCall;

        if (state is CallIncoming) {
          showAcceptReject = !widget.isOutgoing;
          currentCall = state.call;
        } else if (state is CallOutgoing) {
          currentCall = state.call;
        } else if (state is CallActive) {
          currentCall = state.call;
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // 1. Full Screen Remote Video Stream
              GestureDetector(
                onTap: _onScreenTap,
                child: Container(
                  color: Colors.black,
                  child: _remoteRenderer.srcObject != null
                      ? RTCVideoView(
                          _remoteRenderer,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(color: Colors.white),
                              const SizedBox(height: 16),
                              Text(
                                state is CallOutgoing ? 'Ringing...' : 'Connecting streams...',
                                style: const TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              // 2. Small Local PiP Video Stream
              if (_localRenderer.srcObject != null && !_isVideoMuted)
                Positioned(
                  right: 16,
                  bottom: _showControls ? 120 : 32,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 110,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: RTCVideoView(
                        _localRenderer,
                        mirror: true,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ),

              // 3. Overlay Title and Peer User Name (Top Section)
              if (_showControls)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black54, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.otherUserName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              state is CallActive ? 'Connected' : 'Calling...',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // 4. Overlay Interactive Call Controls (Bottom Section)
              if (_showControls)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black54],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: showAcceptReject && currentCall != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              FloatingActionButton(
                                backgroundColor: Colors.green,
                                child: const Icon(Icons.call, color: Colors.white),
                                onPressed: () {
                                  context.read<CallBloc>().add(AcceptCall(currentCall!));
                                },
                              ),
                              FloatingActionButton(
                                backgroundColor: Colors.red,
                                child: const Icon(Icons.call_end, color: Colors.white),
                                onPressed: () {
                                  context.read<CallBloc>().add(RejectCall(widget.callId));
                                },
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isAudioMuted ? Icons.mic_off : Icons.mic,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: _toggleAudio,
                              ),
                              IconButton(
                                icon: Icon(
                                  _isVideoMuted ? Icons.videocam_off : Icons.videocam,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: _toggleVideo,
                              ),
                              FloatingActionButton(
                                backgroundColor: Colors.red,
                                child: const Icon(Icons.call_end, color: Colors.white),
                                onPressed: () {
                                  context.read<CallBloc>().add(EndCall(widget.callId));
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.switch_camera,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: _flipCamera,
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
