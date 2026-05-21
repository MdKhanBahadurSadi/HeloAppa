import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import '../../../../main.dart';

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
    if (isMockMode) {
      setState(() {
        _otherUserIsOnline = true;
        _otherUserId = '1';
      });
      return;
    }

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
    final isDark = theme.brightness == Brightness.dark;
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated ? authState.user.id : '';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              toolbarHeight: 70,
              backgroundColor: isDark ? AppTheme.darkBg.withOpacity(0.7) : Colors.white.withOpacity(0.7),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.pop(),
              ),
              titleSpacing: 0,
              title: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage: _otherUserPhotoUrl != null && _otherUserPhotoUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(_otherUserPhotoUrl!)
                            : null,
                        child: _otherUserPhotoUrl == null || _otherUserPhotoUrl!.isEmpty
                            ? Text(widget.otherUserName[0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold))
                            : null,
                      ),
                      if (_otherUserIsOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? AppTheme.darkBg : Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.otherUserName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        ),
                        Text(
                          _otherUserIsOnline ? 'Active now' : 'Offline',
                          style: TextStyle(
                            fontSize: 12,
                            color: _otherUserIsOnline ? Colors.green : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                            fontWeight: _otherUserIsOnline ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                _buildActionIcon(Icons.call_rounded, () {
                   if (_otherUserId.isNotEmpty && authState is AuthAuthenticated) {
                    context.read<CallBloc>().add(StartCall(
                      callerId: authState.user.id,
                      callerName: authState.user.name,
                      callerPhoto: authState.user.photoUrl ?? '',
                      receiverId: _otherUserId,
                      isVideo: false,
                    ));
                  }
                }),
                _buildActionIcon(Icons.videocam_rounded, () {
                  if (_otherUserId.isNotEmpty && authState is AuthAuthenticated) {
                    context.read<CallBloc>().add(StartCall(
                      callerId: authState.user.id,
                      callerName: authState.user.name,
                      callerPhoto: authState.user.photoUrl ?? '',
                      receiverId: _otherUserId,
                      isVideo: true,
                    ));
                  }
                }),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
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
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
          ),
          child: Column(
            children: [
              Expanded(
                child: BlocConsumer<ChatBloc, ChatState>(
                  listener: (context, state) {
                    if (state is MessagesLoaded) {
                      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                      if (currentUserId.isNotEmpty) {
                        context.read<ChatBloc>().add(MarkSeen(chatId: widget.chatId, userId: currentUserId));
                      }
                    }
                  },
                  builder: (context, state) {
                    if (state is MessagesLoaded) {
                      final messages = state.messages;
                      if (messages.isEmpty) {
                        return Center(
                          child: GlassContainer(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.waving_hand_rounded, size: 48, color: Colors.orangeAccent),
                                const SizedBox(height: 16),
                                Text('Say hi to ${widget.otherUserName}!', style: theme.textTheme.titleMedium),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 100, 12, 20),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMine = message.senderId == currentUserId;
                          return MessageBubble(message: message, isMine: isMine);
                        },
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
              _buildInputArea(theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.primaryColor, size: 22),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: AppTheme.primaryColor),
              onPressed: _pickAndSendImage,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GlassContainer(
              borderRadius: 28,
              blur: 10,
              opacity: isDark ? 0.08 : 0.05,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: AppTheme.premiumShadow(color: AppTheme.primaryColor),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
