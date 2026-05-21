import 'dart:async';
import 'dart:ui';
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  StreamSubscription? _incomingCallSub;
  late AnimationController _animationController;

  final List<Widget> _tabs = [
    const ChatListScreen(),
    const ContactsScreen(showAppBar: false),
    const SettingsScreen(showAppBar: false),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

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
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = context.watch<AuthBloc>().state;

    String? photoUrl;
    String name = 'HeloAppa';
    if (authState is AuthAuthenticated) {
      photoUrl = authState.user.photoUrl;
      name = authState.user.name;
    }

    return Scaffold(
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              toolbarHeight: 70,
              centerTitle: false,
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _selectedIndex == 0
                      ? 'Messages'
                      : (_selectedIndex == 1 ? 'Contacts' : 'Settings'),
                  key: ValueKey(_selectedIndex),
                  style: theme.appBarTheme.titleTextStyle,
                ),
              ),
              leading: Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.premiumShadow(color: AppTheme.primaryColor),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: photoUrl != null && photoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: CachedNetworkImage(
                                imageUrl: photoUrl,
                                placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                                errorWidget: (context, url, error) => _buildInitials(name),
                              ),
                            )
                          : _buildInitials(name),
                    ),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: IconButton(
                    icon: Icon(
                      Icons.logout_rounded,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    onPressed: () {
                      context.read<AuthBloc>().add(AuthSignOutRequested());
                      context.go('/login');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
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
        child: FadeTransition(
          opacity: _animationController,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutCubic,
            )),
            child: _tabs[_selectedIndex],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, isDark),
      floatingActionButton: _selectedIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 90.0),
              child: FloatingActionButton(
                onPressed: () => _onItemTapped(1),
                child: const Icon(Icons.add_rounded, size: 32),
              ),
            )
          : null,
    );
  }

  Widget _buildInitials(String name) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        color: AppTheme.primaryColor,
        fontSize: 18,
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      height: 70,
      child: GlassContainer(
        borderRadius: 35,
        blur: 20,
        opacity: isDark ? 0.08 : 0.05,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chats'),
            _buildNavItem(1, Icons.contacts_outlined, Icons.contacts_rounded, 'Contacts'),
            _buildNavItem(2, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppTheme.primaryColor : (Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54);

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(35),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: isSelected ? 28 : 24,
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 4,
                width: 4,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
