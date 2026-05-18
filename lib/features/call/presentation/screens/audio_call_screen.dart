import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../bloc/call_bloc.dart';
import '../bloc/call_event.dart';
import '../bloc/call_state.dart';
import '../widgets/call_button.dart';

class AudioCallScreen extends StatelessWidget {
  final String callId;
  final String otherUserName;
  final String? otherUserPhoto;
  final bool isOutgoing;

  const AudioCallScreen({
    super.key,
    required this.callId,
    required this.otherUserName,
    this.otherUserPhoto,
    required this.isOutgoing,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<CallBloc, CallState>(
      listener: (context, state) {
        if (state is CallEnded) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: otherUserPhoto != null
                          ? CachedNetworkImageProvider(otherUserPhoto!)
                          : null,
                      child: otherUserPhoto == null ? const Icon(Icons.person, size: 60) : null,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      otherUserName,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<CallBloc, CallState>(
                      builder: (context, state) {
                        String statusText = isOutgoing ? 'Ringing...' : 'Incoming call...';
                        if (state is CallActive) statusText = 'Connected';
                        return Text(
                          statusText,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: BlocBuilder<CallBloc, CallState>(
                  builder: (context, state) {
                    if (state is CallIncoming) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CallButton(
                            icon: Icons.call,
                            color: Colors.green,
                            label: 'Accept',
                            onTap: () => context.read<CallBloc>().add(AcceptCall(state.call)),
                          ),
                          CallButton(
                            icon: Icons.call_end,
                            color: Colors.red,
                            label: 'Reject',
                            onTap: () => context.read<CallBloc>().add(RejectCall(callId)),
                          ),
                        ],
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CallButton(
                          icon: Icons.mic_off,
                          color: Colors.white24,
                          label: 'Mute',
                          onTap: () {},
                        ),
                        CallButton(
                          icon: Icons.call_end,
                          color: Colors.red,
                          label: 'End',
                          onTap: () => context.read<CallBloc>().add(EndCall(callId)),
                        ),
                        CallButton(
                          icon: Icons.volume_up,
                          color: Colors.white24,
                          label: 'Speaker',
                          onTap: () {},
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
