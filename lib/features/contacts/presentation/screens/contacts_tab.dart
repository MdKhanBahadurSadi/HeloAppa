import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../bloc/contacts_bloc.dart';
import '../bloc/contacts_event.dart';
import '../bloc/contacts_state.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../chat/domain/repositories/chat_repository.dart';
import '../../call/presentation/bloc/call_bloc.dart';
import '../../call/presentation/bloc/call_event.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/di/injection.dart';

class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  final TextEditingController _searchController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            onChanged: (query) => context.read<ContactsBloc>().add(SearchContacts(query)),
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<ContactsBloc, ContactsState>(
            builder: (context, state) {
              if (state is ContactsLoading) return const Center(child: CircularProgressIndicator());
              if (state is ContactsLoaded) {
                return ListView.builder(
                  itemCount: state.filtered.length,
                  itemBuilder: (context, index) {
                    final contact = state.filtered[index];
                    return ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundImage: contact.photoUrl != null
                                ? CachedNetworkImageProvider(contact.photoUrl!)
                                : null,
                            child: contact.photoUrl == null ? const Icon(Icons.person) : null,
                          ),
                          if (contact.isOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(contact.name),
                      subtitle: Text(
                        contact.isOnline ? 'Online' : 'Last seen ${timeago.format(contact.lastSeen)}',
                      ),
                      onTap: () async {
                        final authState = context.read<AuthBloc>().state as AuthAuthenticated;
                        final chatId = await sl<ChatRepository>().getOrCreateChat(
                          authState.user.id,
                          contact.uid,
                        );
                        if (mounted) {
                          context.push(
                            AppRouter.chat.replaceAll(':chatId', chatId),
                            extra: contact.name,
                          );
                        }
                      },
                      onLongPress: () => _showCallSheet(context, contact),
                    );
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  void _showCallSheet(BuildContext context, dynamic contact) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.call, color: Colors.green),
            title: const Text('Audio Call'),
            onTap: () {
              Navigator.pop(context);
              final authState = BlocProvider.of<AuthBloc>(context).state as AuthAuthenticated;
              context.read<CallBloc>().add(StartCall(
                    callerId: authState.user.id,
                    callerName: authState.user.name,
                    callerPhoto: authState.user.photoUrl,
                    receiverId: contact.uid,
                    isVideo: false,
                  ));
              context.push(
                AppRouter.audioCall.replaceAll(':callId', 'new_call'),
                extra: {
                  'otherUserName': contact.name,
                  'otherUserPhoto': contact.photoUrl,
                  'isOutgoing': true,
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam, color: Colors.purple),
            title: const Text('Video Call'),
            onTap: () {
              Navigator.pop(context);
              final authState = BlocProvider.of<AuthBloc>(context).state as AuthAuthenticated;
              context.read<CallBloc>().add(StartCall(
                    callerId: authState.user.id,
                    callerName: authState.user.name,
                    callerPhoto: authState.user.photoUrl,
                    receiverId: contact.uid,
                    isVideo: true,
                  ));
              context.push(
                AppRouter.videoCall.replaceAll(':callId', 'new_call'),
                extra: {
                  'otherUserName': contact.name,
                  'otherUserPhoto': contact.photoUrl,
                  'isOutgoing': true,
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
