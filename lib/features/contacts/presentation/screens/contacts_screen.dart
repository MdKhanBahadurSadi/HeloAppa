import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/contact_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../call/presentation/bloc/call_bloc.dart';
import '../../../call/presentation/bloc/call_event.dart';
import '../../../call/presentation/bloc/call_state.dart';
import '../bloc/contacts_bloc.dart';
import '../bloc/contacts_event.dart';
import '../bloc/contacts_state.dart';

class ContactsScreen extends StatefulWidget {
  final bool showAppBar;
  const ContactsScreen({super.key, this.showAppBar = true});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  ContactModel? _selectedCallContact;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<ContactsBloc>().add(LoadContacts(authState.user.id));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  void _onContactTap(ContactModel contact) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );

      try {
        final currentUserId = authState.user.id;
        final chatId = await sl<ChatRepository>().getOrCreateChat(currentUserId, contact.uid);
        
        if (mounted) {
          Navigator.of(context).pop();
          context.push('/chat/$chatId', extra: contact.name);
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _showCallBottomSheet(ContactModel contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return GlassContainer(
          borderRadius: 32,
          blur: 20,
          opacity: isDark ? 0.1 : 0.05,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: contact.photoUrl != null && contact.photoUrl!.isNotEmpty ? CachedNetworkImageProvider(contact.photoUrl!) : null,
                    child: contact.photoUrl == null || contact.photoUrl!.isEmpty ? Text(contact.name[0].toUpperCase()) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(contact.isOnline ? 'Online' : 'Offline', style: TextStyle(color: contact.isOnline ? Colors.green : Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildCallOption(Icons.call_rounded, 'Voice Call', Colors.blue, () {
                Navigator.of(ctx).pop();
                _initiateCall(contact, isVideo: false);
              }),
              const SizedBox(height: 12),
              _buildCallOption(Icons.videocam_rounded, 'Video Call', Colors.purple, () {
                Navigator.of(ctx).pop();
                _initiateCall(contact, isVideo: true);
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCallOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  void _initiateCall(ContactModel contact, {required bool isVideo}) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      setState(() { _selectedCallContact = contact; });
      context.read<CallBloc>().add(StartCall(
        callerId: authState.user.id,
        callerName: authState.user.name,
        callerPhoto: authState.user.photoUrl ?? '',
        receiverId: contact.uid,
        isVideo: isVideo,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Widget content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: GlassContainer(
            borderRadius: 24,
            blur: 10,
            opacity: isDark ? 0.08 : 0.04,
            child: TextField(
              controller: _searchController,
              onChanged: (query) => context.read<ContactsBloc>().add(SearchContacts(query)),
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        
        Expanded(
          child: BlocBuilder<ContactsBloc, ContactsState>(
            builder: (context, state) {
              if (state is ContactsLoaded) {
                final contacts = state.filtered;
                if (contacts.isEmpty) {
                  return Center(child: Text('No contacts found', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              backgroundImage: contact.photoUrl != null && contact.photoUrl!.isNotEmpty ? CachedNetworkImageProvider(contact.photoUrl!) : null,
                              child: contact.photoUrl == null || contact.photoUrl!.isEmpty ? Text(contact.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)) : null,
                            ),
                            if (contact.isOnline)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: isDark ? AppTheme.darkBg : Colors.white, width: 2)),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          contact.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          contact.isOnline ? 'Active now' : 'Seen ${_formatLastSeen(contact.lastSeen)}',
                          style: TextStyle(fontSize: 12, color: contact.isOnline ? Colors.green : theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
                        ),
                        onTap: () => _onContactTap(contact),
                        onLongPress: () => _showCallBottomSheet(contact),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert_rounded, size: 20),
                          onPressed: () => _showCallBottomSheet(contact),
                        ),
                      ),
                    );
                  },
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ],
    );

    return BlocListener<CallBloc, CallState>(
      listener: (context, state) {
        if (state is CallOutgoing && _selectedCallContact != null) {
          context.push(
            state.call.isVideo ? '/video-call/${state.call.callId}' : '/audio-call/${state.call.callId}',
            extra: {
              'otherUserName': _selectedCallContact!.name,
              'otherUserPhoto': _selectedCallContact!.photoUrl,
              'isOutgoing': true,
            },
          );
        }
      },
      child: widget.showAppBar
          ? Scaffold(
              appBar: AppBar(title: const Text('Contacts')),
              body: content,
            )
          : content,
    );
  }
}
