import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/message_bubble.dart';
import '../../../call/presentation/bloc/call_bloc.dart';
import '../../../call/presentation/bloc/call_event.dart';
import '../../../call/presentation/bloc/call_state.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  StreamSubscription? _chatDocSubscription;
  StreamSubscription? _otherUserSubscription;
  bool _otherUserIsOnline = false;
  String _otherUserId = '';
  String? _otherUserPhotoUrl;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final userId = authState.user.id;
      context.read<ChatBloc>().add(LoadMessages(widget.chatId));
      context.read<ChatBloc>().add(MarkSeen(chatId: widget.chatId, userId: userId));
      _listenToPresence(userId);
    }
  }

  void _listenToPresence(String currentUserId) {
    _chatDocSubscription = FirebaseFirestore.instance
        .collection('CHATS')
        .doc(widget.chatId)
        .snapshots()
        .listen((chatSnapshot) {
      if (chatSnapshot.exists && chatSnapshot.data() != null) {
        final participants = List<String>.from(chatSnapshot.data()!['participants'] ?? []);
        final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );

        if (otherUserId.isNotEmpty) {
          _otherUserId = otherUserId;
          _otherUserSubscription?.cancel();
          _otherUserSubscription = FirebaseFirestore.instance
              .collection('USERS')
              .doc(otherUserId)
              .snapshots()
              .listen((userSnapshot) {
            if (userSnapshot.exists && userSnapshot.data() != null) {
              if (mounted) {
                setState(() {
                  _otherUserIsOnline = userSnapshot.data()!['isOnline'] as bool? ?? false;
                  _otherUserPhotoUrl = userSnapshot.data()!['photoUrl'] as String?;
                });
              }
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatDocSubscription?.cancel();
    _otherUserSubscription?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<ChatBloc>().add(
            SendTextMessage(
              chatId: widget.chatId,
              senderId: authState.user.id,
              text: text,
            ),
          );
      _messageController.clear();
      context.read<ChatBloc>().add(MarkSeen(chatId: widget.chatId, userId: authState.user.id));
    }
  }

  Future<void> _pickAndSendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null || !mounted) return;
    final file = File(image.path);
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<ChatBloc>().add(
            SendImageMessage(
              chatId: widget.chatId,
              senderId: authState.user.id,
              image: file,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated ? authState.user.id : '';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _otherUserIsOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _otherUserIsOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        color: _otherUserIsOnline ? Colors.green : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            onPressed: () {
              if (_otherUserId.isNotEmpty && authState is AuthAuthenticated) {
                context.read<CallBloc>().add(StartCall(
                  callerId: authState.user.id,
                  callerName: authState.user.name,
                  callerPhoto: authState.user.photoUrl ?? '',
                  receiverId: _otherUserId,
                  isVideo: false,
                ));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {
              if (_otherUserId.isNotEmpty && authState is AuthAuthenticated) {
                context.read<CallBloc>().add(StartCall(
                  callerId: authState.user.id,
                  callerName: authState.user.name,
                  callerPhoto: authState.user.photoUrl ?? '',
                  receiverId: _otherUserId,
                  isVideo: true,
                ));
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocListener<CallBloc, CallState>(
        listener: (context, state) {
          if (state is CallOutgoing) {
            context.push(
              state.call.isVideo
                  ? '/video-call/${state.call.callId}'
                  : '/audio-call/${state.call.callId}',
              extra: {
                'otherUserName': widget.otherUserName,
                'otherUserPhoto': _otherUserPhotoUrl,
                'isOutgoing': true,
              },
            );
          }
        },
        child: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is MessagesLoaded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                  // Also mark seen when new messages arrive
                  if (currentUserId.isNotEmpty) {
                    context.read<ChatBloc>().add(MarkSeen(chatId: widget.chatId, userId: currentUserId));
                  }
                }
              },
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  );
                }

                if (state is ChatError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Failed to load messages: ${state.message}',
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (state is MessagesLoaded) {
                  final messages = state.messages;

                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet. Say hi!',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMine = message.senderId == currentUserId;

                      return MessageBubble(
                        message: message,
                        isMine: isMine,
                      );
                    },
                  );
                }

                return const Center(child: Text('Connecting to conversation...'));
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF27272A)
                      : const Color(0xFFE4E4E7),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined, color: AppTheme.primaryColor),
                    onPressed: _pickAndSendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.brightness == Brightness.dark
                            ? const Color(0xFF18181B)
                            : const Color(0xFFF4F4F5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
