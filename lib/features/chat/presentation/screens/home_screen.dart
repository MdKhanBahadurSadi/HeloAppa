import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../call/presentation/bloc/call_bloc.dart';
import '../../call/presentation/bloc/call_state.dart';
import '../../call/domain/repositories/call_repository.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/di/injection.dart';
import 'chat_list_tab.dart';
import '../../contacts/presentation/screens/contacts_tab.dart';
import '../../settings/presentation/screens/settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const ChatListTab(),
    const ContactsTab(),
    const SettingsTab(),
  ];

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<CallBloc>().listenForIncomingCalls(authState.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CallBloc, CallState>(
      listener: (context, state) {
        if (state is CallIncoming) {
          final route = state.call.isVideo ? AppRouter.videoCall : AppRouter.audioCall;
          context.push(
            route.replaceAll(':callId', state.call.callId),
            extra: {
              'otherUserName': state.call.callerName,
              'otherUserPhoto': state.call.callerPhoto,
              'isOutgoing': false,
            },
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('HeloAppa'),
          actions: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: state.user.photoUrl != null
                          ? CachedNetworkImageProvider(state.user.photoUrl!)
                          : null,
                      child: state.user.photoUrl == null ? const Icon(Icons.person) : null,
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ),
        body: _tabs[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
            BottomNavigationBarItem(icon: Icon(Icons.contacts), label: 'Contacts'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
