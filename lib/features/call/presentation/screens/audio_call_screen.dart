import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/call_model.dart';
import '../bloc/call_bloc.dart';
import '../bloc/call_event.dart';
import '../bloc/call_state.dart';
import '../widgets/call_button.dart';

class AudioCallScreen extends StatefulWidget {
  final String callId;
  final String otherUserName;
  final String? otherUserPhoto;
  final bool isOutgoing;
  final bool isVideo;

  const AudioCallScreen({
    super.key,
    required this.callId,
    required this.otherUserName,
    this.otherUserPhoto,
    required this.isOutgoing,
    this.isVideo = false,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _renderersInitialized = false;

  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.isVideo) {
      _initRenderers();
    }

    // If it's outgoing, the CallBloc has already started it, or we can start it
    // Wait, the bloc handles StartCall when the call button is clicked.
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    if (mounted) {
      setState(() {
        _renderersInitialized = true;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    final currentState = context.read<CallBloc>().state;
    if (currentState is CallActive && currentState.localStream != null) {
      for (final track in currentState.localStream!.getAudioTracks()) {
        track.enabled = !_isMuted;
      }
    }
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    Helper.setSpeakerphoneOn(_isSpeakerOn);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<CallBloc, CallState>(
      listener: (context, state) {
        if (state is CallActive) {
          _startTimer();
          if (!widget.isVideo && _renderersInitialized) {
            if (state.localStream != null) {
              _localRenderer.srcObject = state.localStream;
            }
            if (state.remoteStream != null) {
              _remoteRenderer.srcObject = state.remoteStream;
            }
          }
        } else if (state is CallEnded) {
          _timer?.cancel();
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
        String statusText = 'Connecting...';
        bool showAcceptReject = false;

        if (state is CallOutgoing) {
          statusText = 'Ringing...';
        } else if (state is CallIncoming) {
          statusText = 'Incoming Call...';
          showAcceptReject = !widget.isOutgoing;
        } else if (state is CallActive) {
          statusText = _formatDuration(_seconds);
        } else if (state is CallEnded) {
          statusText = 'Call Ended';
        }

        // Retrieve current incoming call reference if available
        CallModel? currentCall;
        if (state is CallIncoming) {
          currentCall = state.call;
        } else if (state is CallOutgoing) {
          currentCall = state.call;
        } else if (state is CallActive) {
          currentCall = state.call;
        }

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: theme.brightness == Brightness.dark
                    ? [const Color(0xFF09090B), const Color(0xFF18181B)]
                    : [const Color(0xFFF4F4F5), const Color(0xFFE4E4E7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Section - Avatar and Name
                  Padding(
                    padding: const EdgeInsets.only(top: 80.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 64,
                          backgroundColor: AppTheme.primaryColor.withAlpha(30),
                          child: widget.otherUserPhoto != null && widget.otherUserPhoto!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(64),
                                  child: Image.network(
                                    widget.otherUserPhoto!,
                                    fit: BoxFit.cover,
                                    width: 128,
                                    height: 128,
                                  ),
                                )
                              : Text(
                                  widget.otherUserName.isNotEmpty
                                      ? widget.otherUserName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.otherUserName,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          statusText,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Optional WebRTC Video Rendering constraints for testing
                  if (!widget.isVideo && _renderersInitialized)
                    Opacity(
                      opacity: 0,
                      child: SizedBox(
                        height: 1,
                        width: 1,
                        child: Row(
                          children: [
                            Expanded(child: RTCVideoView(_localRenderer)),
                            Expanded(child: RTCVideoView(_remoteRenderer)),
                          ],
                        ),
                      ),
                    ),

                  // Bottom Controls Section
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60.0),
                    child: showAcceptReject && currentCall != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              CallButton(
                                icon: Icons.call,
                                color: Colors.green,
                                label: 'Accept',
                                onTap: () {
                                  context.read<CallBloc>().add(AcceptCall(currentCall!));
                                },
                              ),
                              CallButton(
                                icon: Icons.call_end,
                                color: Colors.red,
                                label: 'Reject',
                                onTap: () {
                                  context.read<CallBloc>().add(RejectCall(widget.callId));
                                },
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              CallButton(
                                icon: _isMuted ? Icons.mic_off : Icons.mic,
                                color: _isMuted ? Colors.grey : Colors.white24,
                                label: _isMuted ? 'Unmute' : 'Mute',
                                onTap: _toggleMute,
                              ),
                              CallButton(
                                icon: Icons.call_end,
                                color: Colors.red,
                                label: 'End Call',
                                onTap: () {
                                  context.read<CallBloc>().add(EndCall(widget.callId));
                                },
                              ),
                              CallButton(
                                icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                                color: _isSpeakerOn ? AppTheme.primaryColor : Colors.white24,
                                label: 'Speaker',
                                onTap: _toggleSpeaker,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
