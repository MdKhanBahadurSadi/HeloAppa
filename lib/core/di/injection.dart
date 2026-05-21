import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../main.dart';
import '../services/presence_service.dart';
import '../services/notification_service.dart';
import '../services/fcm_sender_service.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/contacts/domain/repositories/contacts_repository.dart';
import '../../features/contacts/data/repositories/contacts_repository_impl.dart';
import '../../features/contacts/domain/models/contact_model.dart';
import '../../features/contacts/presentation/bloc/contacts_bloc.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/models/chat_model.dart';
import '../../features/chat/domain/models/message_model.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/call/domain/repositories/call_repository.dart';
import '../../features/call/data/repositories/call_repository_impl.dart';
import '../../features/call/domain/models/call_model.dart';
import '../../features/call/data/services/webrtc_service.dart';
import '../../features/call/presentation/bloc/call_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // Services
  sl.registerLazySingleton<PresenceService>(() => PresenceService());
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<FcmSenderService>(() => FcmSenderService());
  sl.registerFactory<WebRTCService>(() => WebRTCService());

  // Remote Datasources
  sl.registerLazySingleton<AuthRemoteDatasource>(() => AuthRemoteDatasource());

  // Repositories
  if (isMockMode) {
    sl.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
    sl.registerLazySingleton<ContactsRepository>(() => MockContactsRepository());
    sl.registerLazySingleton<ChatRepository>(() => MockChatRepository());
    sl.registerLazySingleton<CallRepository>(() => MockCallRepository());
  } else {
    sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
    sl.registerLazySingleton<ContactsRepository>(() => ContactsRepositoryImpl());
    sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl());
    sl.registerLazySingleton<CallRepository>(() => CallRepositoryImpl());
  }
  
  // Blocs
  sl.registerFactory<AuthBloc>(() => AuthBloc(
        authRepository: sl(),
        presenceService: sl(),
      ));
  sl.registerFactory<ChatBloc>(() => ChatBloc(chatRepository: sl()));
  sl.registerFactory<CallBloc>(() => CallBloc(callRepository: sl()));
  sl.registerFactory<ContactsBloc>(() => ContactsBloc(contactsRepository: sl()));
}

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;
  final _controller = StreamController<UserModel?>.broadcast();

  MockAuthRepository() {
    // Initial state is unauthenticated
    _controller.add(null);
  }

  @override
  Stream<UserModel?> get authStateChanges {
    // Return a stream that starts with the current status
    return _controller.stream;
  }

  @override
  Future<UserModel?> getCurrentUser() async => _currentUser;

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    _currentUser = UserModel(
      id: 'mock_user_id',
      name: 'Dummy User',
      email: email,
      isOnline: true,
      lastSeen: DateTime.now(),
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserModel> signUpWithEmail(String email, String password, String name) async {
    _currentUser = UserModel(
      id: 'mock_user_id',
      name: name,
      email: email,
      isOnline: true,
      lastSeen: DateTime.now(),
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    _currentUser = UserModel(
      id: 'mock_user_id',
      name: 'Google User',
      email: 'google@mock.com',
      isOnline: true,
      lastSeen: DateTime.now(),
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }
}

class MockContactsRepository implements ContactsRepository {
  @override
  Stream<List<ContactModel>> getAllUsers(String currentUserId) {
    return Stream.value([
      ContactModel(uid: '1', name: 'Sadi', isOnline: true, lastSeen: DateTime.now()),
      ContactModel(uid: '2', name: 'John Doe', isOnline: false, lastSeen: DateTime.now()),
      ContactModel(uid: '3', name: 'Jane Smith', isOnline: true, lastSeen: DateTime.now()),
    ]);
  }

  @override
  Future<ContactModel?> getUserById(String uid) async {
    return ContactModel(uid: uid, name: 'Mock User', isOnline: true, lastSeen: DateTime.now());
  }
}

class MockChatRepository implements ChatRepository {
  @override
  Future<String> getOrCreateChat(String currentUserId, String otherUserId) async => 'mock_chat_id';

  @override
  Stream<List<ChatModel>> getUserChats(String currentUserId) {
    return Stream.periodic(const Duration(seconds: 1), (_) {
      return [
        ChatModel(
          id: 'c1',
          participants: [currentUserId, '1'],
          lastMessage: 'Hey Sadi, how are you?',
          lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
          unreadCount: 1,
          otherUserId: '1',
          otherUserName: 'Sadi',
          otherUserIsOnline: true,
        ),
        ChatModel(
          id: 'c2',
          participants: [currentUserId, '2'],
          lastMessage: 'See you tomorrow!',
          lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
          unreadCount: 0,
          otherUserId: '2',
          otherUserName: 'John Doe',
          otherUserIsOnline: false,
        ),
      ];
    });
  }

  @override
  Stream<List<MessageModel>> getMessages(String chatId) => Stream.value([]);

  @override
  Future<void> sendMessage(MessageModel message) async {}

  @override
  Future<void> markMessagesSeen(String chatId, String userId) async {}

  @override
  Future<void> sendImageMessage(String chatId, String senderId, File imageFile) async {}
}

class MockCallRepository implements CallRepository {
  @override
  Future<String> initiateCall(CallModel call) async => call.callId;
  @override
  Future<void> answerCall(String callId, RTCSessionDescription answer) async {}
  @override
  Future<void> rejectCall(String callId) async {}
  @override
  Future<void> endCall(String callId) async {}
  @override
  Future<void> sendIceCandidate(String callId, String senderId, RTCIceCandidate candidate) async {}
  @override
  Stream<CallModel?> listenForIncomingCall(String userId) => Stream.value(null);
  @override
  Stream<Map<String, dynamic>?> listenForAnswer(String callId) => Stream.value(null);
  @override
  Stream<List<Map<String, dynamic>>> listenForIceCandidates(String callId, String senderId) => Stream.value([]);
}
