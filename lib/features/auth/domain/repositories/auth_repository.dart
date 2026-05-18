import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> signInWithEmail(String email, String password);
  Future<UserModel> signUpWithEmail(String email, String password, String name);
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  Stream<UserModel?> get authStateChanges;
  Future<UserModel?> getCurrentUser();
}
