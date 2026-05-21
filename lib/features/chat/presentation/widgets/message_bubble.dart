import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = DateFormat('hh:mm a').format(message.timestamp);
    final hasBeenSeen = message.seenBy.length > 1;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMine
              ? AppTheme.primaryColor
              : (theme.brightness == Brightness.dark
                  ? const Color(0xFF27272A)
                  : const Color(0xFFF4F4F5)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.type == MessageType.text)
              Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 4),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: isMine
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    fontSize: 15,
                  ),
                ),
              )
            else if (message.type == MessageType.image && message.mediaUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: message.mediaUrl!,
                  placeholder: (context, url) => Container(
                    height: 200,
                    width: 200,
                    color: Colors.black12,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                  ),
                  fit: BoxFit.cover,
                ),
              )
            else if (message.type == MessageType.audio)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.audiotrack_rounded,
                    color: isMine ? Colors.white : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Audio Message',
                    style: TextStyle(
                      color: isMine ? Colors.white : theme.colorScheme.onSurface,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    color: isMine ? Colors.white70 : Colors.black38,
                    fontSize: 10,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    hasBeenSeen ? Icons.done_all : Icons.done,
                    size: 14,
                    color: hasBeenSeen
                        ? (isMine ? Colors.white : AppTheme.primaryColor)
                        : (isMine ? Colors.white54 : Colors.grey),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
