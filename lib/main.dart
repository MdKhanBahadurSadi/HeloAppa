import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/di/injection.dart' as di;
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/notification_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/call/presentation/bloc/call_bloc.dart';
import 'features/contacts/presentation/bloc/contacts_bloc.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final type = message.data['type'];
  if (type == 'incoming_call') {
    final callerName = message.data['callerName'] ?? 'Unknown Caller';
    final callerPhoto = message.data['callerPhoto'] ?? '';
    final callId = message.data['callId'] ?? '';
    final isVideo = message.data['isVideo'] == 'true';

    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'HeloAppa',
      avatar: callerPhoto.isNotEmpty ? callerPhoto : null,
      handle: 'HeloAppa Call',
      type: isVideo ? 1 : 0,
      duration: 30000,
      android: const AndroidParams(
        isImportant: true,
        ringtonePath: 'system_ringtone_default',
        actionColor: '#6C63FF',
      ),
      ios: const IOSParams(
        iconName: 'CallKitIcon',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
      ),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }
}

bool isMockMode = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    isMockMode = true;
    debugPrint('Firebase initialization warning: $e. Entering Mock Mode with dummy data.');
  }

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('settings');

  // Initialize Dependency Injection (GetIt)
  await di.initDependencies();

  // Initialize Notification Service (FCM & CallKit)
  try {
    await di.sl<NotificationService>().initialize();
  } catch (e) {
    debugPrint('Notification Service initialization warning: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (isMockMode) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final firestore = FirebaseFirestore.instance;
      if (state == AppLifecycleState.paused) {
        firestore.collection(AppConstants.USERS).doc(user.uid).update({
          'isOnline': false,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
        });
      } else if (state == AppLifecycleState.resumed) {
        firestore.collection(AppConstants.USERS).doc(user.uid).update({
          'isOnline': true,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => di.sl<AuthBloc>(),
        ),
        BlocProvider(
          create: (context) => di.sl<ChatBloc>(),
        ),
        BlocProvider(
          create: (context) => di.sl<CallBloc>(),
        ),
        BlocProvider(
          create: (context) => di.sl<ContactsBloc>(),
        ),
      ],
      child: ValueListenableBuilder(
        valueListenable: Hive.box('settings').listenable(keys: ['darkMode']),
        builder: (context, Box box, _) {
          final isDarkMode = box.get('darkMode', defaultValue: false);
          return MaterialApp.router(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
