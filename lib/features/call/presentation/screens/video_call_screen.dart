import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/call_bloc.dart';
import '../bloc/call_event.dart';
import '../bloc/call_state.dart';

class VideoCallScreen extends StatefulWidget {
  final String callId;
  final String otherUserName;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.otherUserName,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CallBloc, CallState>(
      listener: (context, state) {
        if (state is CallEnded) {
          context.pop();
        }
        if (state is CallActive) {
          if (state.localStream != null) {
            _localRenderer.srcObject = state.localStream;
          }
          if (state.remoteStream != null) {
            _remoteRenderer.srcObject = state.remoteStream;
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () {
            setState(() => _showControls = !_showControls);
            if (_showControls) {
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) setState(() => _showControls = false);
              });
            }
          },
          child: Stack(
            children: [
              // Remote stream
              RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
              
              // Local stream PiP
              Positioned(
                right: 20,
                bottom: 100,
                child: SizedBox(
                  width: 120,
                  height: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: RTCVideoView(
                      _localRenderer,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),

              // Controls Overlay
              if (_showControls)
                _buildControls(),
              
              // Back button / Other name
              Positioned(
                top: 40,
                left: 20,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      widget.otherUserName,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlButton(Icons.mic, Colors.white24, () {}),
          _controlButton(Icons.call_end, Colors.red, () {
            context.read<CallBloc>().add(EndCall(widget.callId));
          }),
          _controlButton(Icons.videocam, Colors.white24, () {}),
          _controlButton(Icons.cameraswitch, Colors.white24, () {}),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, Color color, VoidCallback onTap) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: color,
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }
}
