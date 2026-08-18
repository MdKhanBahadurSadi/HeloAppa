import 'package:go_router/go_router.dart';
import '../di/injection.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/splash/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/chat/presentation/screens/home_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/call/presentation/screens/audio_call_screen.dart';
import '../../features/call/presentation/screens/video_call_screen.dart';
import '../../features/contacts/presentation/screens/contacts_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/privacy_screen.dart';

class AppRoutes {
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
  static const String privacy = '/privacy';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  redirect: (context, state) async {
    final authRepository = sl<AuthRepository>();
    final user = await authRepository.getCurrentUser();
    
    final isLoggingIn = state.matchedLocation == AppRoutes.login;
    final isRegistering = state.matchedLocation == AppRoutes.register;
    final isSplash = state.matchedLocation == AppRoutes.splash;
    
    if (user == null) {
      if (!isLoggingIn && !isRegistering && !isSplash) {
        return AppRoutes.login;
      }
    } else {
      if (isLoggingIn || isRegistering || isSplash) {
        return AppRoutes.home;
      }
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.chat,
      builder: (context, state) {
        final chatId = state.pathParameters['chatId'] ?? '';
        final otherUserName = state.extra as String? ?? 'Chat';
        return ChatScreen(
          chatId: chatId,
          otherUserName: otherUserName,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.audioCall,
      builder: (context, state) {
        final callId = state.pathParameters['callId'] ?? '';
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final otherUserName = extra['otherUserName'] as String? ?? 'User';
        final otherUserPhoto = extra['otherUserPhoto'] as String?;
        final isOutgoing = extra['isOutgoing'] as bool? ?? true;
        return AudioCallScreen(
          callId: callId,
          otherUserName: otherUserName,
          otherUserPhoto: otherUserPhoto,
          isOutgoing: isOutgoing,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.videoCall,
      builder: (context, state) {
        final callId = state.pathParameters['callId'] ?? '';
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final otherUserName = extra['otherUserName'] as String? ?? 'User';
        final otherUserPhoto = extra['otherUserPhoto'] as String?;
        final isOutgoing = extra['isOutgoing'] as bool? ?? true;
        return VideoCallScreen(
          callId: callId,
          otherUserName: otherUserName,
          otherUserPhoto: otherUserPhoto,
          isOutgoing: isOutgoing,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.contacts,
      builder: (context, state) => const ContactsScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.privacy,
      builder: (context, state) => const PrivacyScreen(),
    ),
  ],
);
