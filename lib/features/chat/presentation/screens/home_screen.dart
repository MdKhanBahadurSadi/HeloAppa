import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'chat_list_screen.dart';
import '../../../contacts/presentation/screens/contacts_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../call/presentation/bloc/call_bloc.dart';
import '../../../call/presentation/bloc/call_event.dart';
import '../../../call/presentation/bloc/call_state.dart';
import '../../../call/domain/repositories/call_repository.dart';
import '../../../call/domain/models/call_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  StreamSubscription? _incomingCallSub;

  final List<Widget> _tabs = [
    const ChatListScreen(),
    const ContactsScreen(showAppBar: false),
    const SettingsScreen(showAppBar: false),
  ];

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final currentUserId = authState.user.id;
      context.read<CallBloc>().add(ListenForIncomingCalls(currentUserId));
      
      _incomingCallSub = sl<CallRepository>().listenForIncomingCall(currentUserId).listen((call) {
        if (!mounted) return;
        if (call != null && call.status == CallStatus.ringing) {
          final callBlocState = context.read<CallBloc>().state;
          if (callBlocState is! CallActive && callBlocState is! CallOutgoing && callBlocState is! CallIncoming) {
            context.push(
              call.isVideo
                  ? '/video-call/${call.callId}'
                  : '/audio-call/${call.callId}',
              extra: {
                'otherUserName': call.callerName,
                'otherUserPhoto': call.callerPhoto,
                'isOutgoing': false,
              },
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _incomingCallSub?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;

    String? photoUrl;
    String name = 'HeloAppa';
    if (authState is AuthAuthenticated) {
      photoUrl = authState.user.photoUrl;
      name = authState.user.name;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Chats'
              : (_selectedIndex == 1 ? 'Contacts' : 'Settings'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withAlpha(40),
            child: photoUrl != null && photoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: photoUrl,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  )
                : Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () {
              context.read<AuthBloc>().add(AuthSignOutRequested());
              context.go('/login');
            },
          ),
        ],
      ),
      body: BlocListener<CallBloc, CallState>(
        listener: (context, state) {
          if (state is CallIncoming) {
            context.push(
              state.call.isVideo
                  ? '/video-call/${state.call.callId}'
                  : '/audio-call/${state.call.callId}',
              extra: {
                'otherUserName': state.call.callerName,
                'otherUserPhoto': state.call.callerPhoto,
                'isOutgoing': false,
              },
            );
          }
        },
        child: _tabs[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts_outlined),
            activeIcon: Icon(Icons.contacts_rounded),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 1; // Direct user to Contacts tab to start a chat
                });
              },
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              child: const Icon(Icons.message_rounded),
            )
          : null,
    );
  }
}
