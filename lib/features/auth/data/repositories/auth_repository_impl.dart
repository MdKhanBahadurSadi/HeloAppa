import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;

  AuthRepositoryImpl(this.remoteDatasource);

  @override
  Stream<UserModel?> get authStateChanges {
    return remoteDatasource.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return await _getUserModel(firebaseUser.uid);
    });
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await _getUserModel(user.uid);
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    final credential = await remoteDatasource.signInWithEmail(email, password);
    final userModel = await _getUserModel(credential.user!.uid);
    
    // Update online status
    final updatedUser = userModel!.copyWith(isOnline: true, lastSeen: DateTime.now());
    await remoteDatasource.updateUserDoc(updatedUser.id, updatedUser.toMap());
    
    return updatedUser;
  }

  @override
  Future<UserModel> signUpWithEmail(String email, String password, String name) async {
    final credential = await remoteDatasource.signUpWithEmail(email, password);
    final user = credential.user!;
    
    final newUser = UserModel(
      id: user.uid,
      name: name,
      email: email,
      photoUrl: user.photoURL,
      isOnline: true,
      lastSeen: DateTime.now(),
    );

    await remoteDatasource.createUserDoc(newUser.toMap());
    return newUser;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    final credential = await remoteDatasource.signInWithGoogle();
    final user = credential.user!;
    
    final doc = await remoteDatasource.getUserDoc(user.uid);
    
    UserModel userModel;
    if (!doc.exists) {
      userModel = UserModel(
        id: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        isOnline: true,
        lastSeen: DateTime.now(),
      );
      await remoteDatasource.createUserDoc(userModel.toMap());
    } else {
      userModel = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      userModel = userModel.copyWith(isOnline: true, lastSeen: DateTime.now());
      await remoteDatasource.updateUserDoc(userModel.id, userModel.toMap());
    }
    
    return userModel;
  }

  @override
  Future<void> signOut() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await remoteDatasource.updateUserDoc(user.uid, {
        'isOnline': false,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
    }
    await remoteDatasource.signOut();
  }

  Future<UserModel?> _getUserModel(String uid) async {
    final doc = await remoteDatasource.getUserDoc(uid);
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}
