import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  
  // Track selected contact for navigation inside CallBloc listener
  ContactModel? _selectedCallContact;

  @override
  void initState() {
    super.initState();
    // Dispatch LoadContacts event
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
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _onContactTap(ContactModel contact) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );

      try {
        final currentUserId = authState.user.id;
        final chatId = await sl<ChatRepository>().getOrCreateChat(currentUserId, contact.uid);
        
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          context.push('/chat/$chatId', extra: contact.name);
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open chat: $e')),
          );
        }
      }
    }
  }

  void _showCallBottomSheet(ContactModel contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                contact.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.phone_outlined, color: AppTheme.primaryColor),
                title: const Text('Audio Call'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _initiateCall(contact, isVideo: false);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.videocam_outlined, color: AppTheme.primaryColor),
                title: const Text('Video Call'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _initiateCall(contact, isVideo: true);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _initiateCall(ContactModel contact, {required bool isVideo}) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      setState(() {
        _selectedCallContact = contact;
      });

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

    final Widget content = Column(
      children: [
        // Premium Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: (query) {
              context.read<ContactsBloc>().add(SearchContacts(query));
            },
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        context.read<ContactsBloc>().add(const SearchContacts(''));
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        
        // Contacts List
        Expanded(
          child: BlocBuilder<ContactsBloc, ContactsState>(
            builder: (context, state) {
              if (state is ContactsLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                );
              } else if (state is ContactsLoaded) {
                final contacts = state.filtered;
                if (contacts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No contacts found',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: contacts.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            backgroundImage: contact.photoUrl != null && contact.photoUrl!.isNotEmpty
                                ? NetworkImage(contact.photoUrl!)
                                : null,
                            child: contact.photoUrl == null || contact.photoUrl!.isEmpty
                                ? Text(
                                    contact.name.isNotEmpty ? contact.name[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: contact.isOnline ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.surface,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        contact.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        contact.isOnline ? 'Online' : 'Last seen ${_formatLastSeen(contact.lastSeen)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: contact.isOnline
                              ? AppTheme.primaryColor
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: () => _onContactTap(contact),
                      onLongPress: () => _showCallBottomSheet(contact),
                    );
                  },
                );
              } else if (state is ContactsError) {
                return Center(
                  child: Text('Error loading contacts: ${state.message}'),
                );
              }

              return const Center(child: Text('Select or search contacts'));
            },
          ),
        ),
      ],
    );

    return BlocListener<CallBloc, CallState>(
      listener: (context, state) {
        if (state is CallOutgoing && _selectedCallContact != null) {
          context.push(
            state.call.isVideo
                ? '/video-call/${state.call.callId}'
                : '/audio-call/${state.call.callId}',
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
              appBar: AppBar(
                title: const Text(
                  'Contacts',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                elevation: 0,
              ),
              body: content,
            )
          : content,
    );
  }
}
