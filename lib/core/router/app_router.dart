import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/chat/presentation/screens/home_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/call/presentation/screens/audio_call_screen.dart';
import '../../features/call/presentation/screens/video_call_screen.dart';
import '../../features/settings/presentation/screens/profile_screen.dart';

class AppRouter {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String chat = '/chat/:chatId';
  static const String audioCall = '/audio-call/:callId';
  static const String videoCall = '/video-call/:callId';
  static const String contacts = '/contacts';
  static const String settings = '/settings';
  static const String profile = '/profile';

  static final router = GoRouter(
    initialLocation: splash,
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggingIn = state.matchedLocation == login || state.matchedLocation == register || state.matchedLocation == splash;

      if (user == null && !isLoggingIn) {
        return login;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: chat,
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          final otherUserName = state.extra as String? ?? 'Chat';
          return ChatScreen(chatId: chatId, otherUserName: otherUserName);
        },
      ),
      GoRoute(
        path: audioCall,
        builder: (context, state) {
          final callId = state.pathParameters['callId']!;
          final extra = state.extra as Map<String, dynamic>;
          return AudioCallScreen(
            callId: callId,
            otherUserName: extra['otherUserName'],
            otherUserPhoto: extra['otherUserPhoto'],
            isOutgoing: extra['isOutgoing'],
          );
        },
      ),
      GoRoute(
        path: videoCall,
        builder: (context, state) {
          final callId = state.pathParameters['callId']!;
          final extra = state.extra as Map<String, dynamic>;
          return VideoCallScreen(
            callId: callId,
            otherUserName: extra['otherUserName'],
          );
        },
      ),
    ],
  );
}
