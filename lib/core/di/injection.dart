import 'package:get_it/get_it.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/contacts/domain/repositories/contacts_repository.dart';
import '../../features/contacts/data/repositories/contacts_repository_impl.dart';
import '../../features/contacts/presentation/bloc/contacts_bloc.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/call/domain/repositories/call_repository.dart';
import '../../features/call/data/repositories/call_repository_impl.dart';
import '../../features/call/data/services/webrtc_service.dart';
import '../../features/call/presentation/bloc/call_bloc.dart';
import '../services/presence_service.dart';
import '../services/notification_service.dart';
import '../services/fcm_sender_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Services
  sl.registerLazySingleton(() => PresenceService());
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => FcmSenderService());
  sl.registerFactory(() => WebRTCService());

  // Data sources
  sl.registerLazySingleton(() => AuthRemoteDatasource());

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ContactsRepository>(
    () => ContactsRepositoryImpl(),
  );
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(),
  );
  sl.registerLazySingleton<CallRepository>(
    () => CallRepositoryImpl(),
  );

  // Blocs
  sl.registerFactory(() => AuthBloc(
        authRepository: sl(),
        presenceService: sl(),
      ));
  sl.registerFactory(() => ChatBloc(chatRepository: sl()));
  sl.registerFactory(() => ContactsBloc(contactsRepository: sl()));
  sl.registerFactory(() => CallBloc(
        callRepository: sl(),
        contactsRepository: sl(),
        fcmSenderService: sl(),
        webRTCServiceFactory: () => sl<WebRTCService>(),
      ));
}
