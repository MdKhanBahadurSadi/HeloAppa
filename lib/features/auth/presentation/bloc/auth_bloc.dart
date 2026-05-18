import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../../../core/services/presence_service.dart';
import '../../../../core/utils/error_handler.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final PresenceService presenceService;
  StreamSubscription? _authSubscription;

  AuthBloc({
    required this.authRepository,
    required this.presenceService,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthGoogleSignInRequested>(_onAuthGoogleSignInRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    _authSubscription?.cancel();
    await emit.forEach(
      authRepository.authStateChanges,
      onData: (user) {
        if (user != null) {
          presenceService.initialize(user.id);
          return AuthAuthenticated(user);
        } else {
          return AuthUnauthenticated();
        }
      },
    );
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithEmail(event.email, event.password);
      presenceService.initialize(user.id);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signUpWithEmail(
        event.email,
        event.password,
        event.name,
      );
      presenceService.initialize(user.id);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> _onAuthGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithGoogle();
      presenceService.initialize(user.id);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      await presenceService.setOffline(currentState.user.id);
    }
    emit(AuthLoading());
    try {
      await authRepository.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(ErrorHandler.getMessage(e)));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
