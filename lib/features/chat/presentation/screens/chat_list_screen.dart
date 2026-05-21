import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<ChatBloc>().add(LoadChats(authState.user.id));
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays == 0) {
      return DateFormat('hh:mm a').format(time);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state is ChatLoading) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor.withOpacity(0.5)),
            ),
          );
        }

        if (state is ChatError) {
          return Center(
            child: GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error: ${state.message}',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          );
        }

        if (state is ChatsLoaded) {
          final chats = state.chats;

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 40,
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 64,
                      color: AppTheme.primaryColor.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No active chats yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start chatting with your contacts',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final hasUnread = chat.unreadCount > 0;

              return TweenAnimationBuilder(
                duration: Duration(milliseconds: 400 + (index * 100)),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.push(
                          '/chat/${chat.id}',
                          extra: chat.otherUserName,
                        );
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasUnread 
                              ? AppTheme.primaryColor.withOpacity(0.05)
                              : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: hasUnread 
                                ? AppTheme.primaryColor.withOpacity(0.2)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: chat.otherUserIsOnline 
                                      ? [BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 10)]
                                      : null,
                                  ),
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                    child: chat.otherUserPhotoUrl != null &&
                                            chat.otherUserPhotoUrl!.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(30),
                                            child: CachedNetworkImage(
                                              imageUrl: chat.otherUserPhotoUrl!,
                                              placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                                              errorWidget: (context, url, error) => _buildInitials(chat.otherUserName),
                                            ),
                                          )
                                        : _buildInitials(chat.otherUserName),
                                  ),
                                ),
                                if (chat.otherUserIsOnline)
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark ? AppTheme.darkBg : Colors.white,
                                          width: 2.5,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          chat.otherUserName.isNotEmpty ? chat.otherUserName : 'Unknown User',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                                            fontSize: 17,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatTime(chat.lastMessageTime),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: hasUnread ? AppTheme.primaryColor : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          chat.lastMessage.isNotEmpty ? chat.lastMessage : 'Start conversation...',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: hasUnread
                                                ? theme.colorScheme.onSurface
                                                : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      if (hasUnread)
                                        Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: AppTheme.premiumShadow(color: AppTheme.primaryColor),
                                          ),
                                          child: Text(
                                            '${chat.unreadCount}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }

        return const Center(child: Text('Loading...'));
      },
    );
  }

  Widget _buildInitials(String name) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: AppTheme.primaryColor,
      ),
    );
  }
}
