import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;

  AuthRepositoryImpl(this._remoteDatasource);

  @override
  Stream<UserModel?> get authStateChanges {
    return _remoteDatasource.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }
      return await _fetchUserModel(firebaseUser.uid);
    });
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _remoteDatasource.currentFirebaseUser;
    if (firebaseUser == null) {
      return null;
    }
    return await _fetchUserModel(firebaseUser.uid);
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    final credential = await _remoteDatasource.signInWithEmail(email, password);
    final user = credential.user!;
    return await _getOrUpdateUserDocument(
      user.uid,
      defaultName: user.displayName,
      defaultEmail: user.email,
      defaultPhoto: user.photoURL,
    );
  }

  @override
  Future<UserModel> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    final credential = await _remoteDatasource.signUpWithEmail(email, password);
    final user = credential.user!;
    final now = DateTime.now();

    final userModel = UserModel(
      id: user.uid,
      name: name,
      email: email,
      photoUrl: user.photoURL,
      fcmToken: null,
      isOnline: true,
      lastSeen: now,
    );

    await _remoteDatasource.createUserDocument(user.uid, userModel.toMap());
    return userModel;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    final credential = await _remoteDatasource.signInWithGoogle();
    final user = credential.user!;
    return await _getOrUpdateUserDocument(
      user.uid,
      defaultName: user.displayName,
      defaultEmail: user.email,
      defaultPhoto: user.photoURL,
    );
  }

  @override
  Future<void> signOut() async {
    final firebaseUser = _remoteDatasource.currentFirebaseUser;
    if (firebaseUser != null) {
      await _remoteDatasource.updateUserDocument(firebaseUser.uid, {
        'isOnline': false,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
    }
    await _remoteDatasource.signOut();
  }

  Future<UserModel> _fetchUserModel(String uid) async {
    final docData = await _remoteDatasource.getUserDocument(uid);
    if (docData != null) {
      return UserModel.fromMap(docData);
    }
    final firebaseUser = _remoteDatasource.currentFirebaseUser;
    return UserModel(
      id: uid,
      name: firebaseUser?.displayName ?? '',
      email: firebaseUser?.email ?? '',
      photoUrl: firebaseUser?.photoURL,
      fcmToken: null,
      isOnline: true,
      lastSeen: DateTime.now(),
    );
  }

  Future<UserModel> _getOrUpdateUserDocument(
    String uid, {
    String? defaultName,
    String? defaultEmail,
    String? defaultPhoto,
  }) async {
    final docData = await _remoteDatasource.getUserDocument(uid);
    final now = DateTime.now();

    if (docData == null) {
      final userModel = UserModel(
        id: uid,
        name: defaultName ?? '',
        email: defaultEmail ?? '',
        photoUrl: defaultPhoto,
        fcmToken: null,
        isOnline: true,
        lastSeen: now,
      );
      await _remoteDatasource.createUserDocument(uid, userModel.toMap());
      return userModel;
    } else {
      await _remoteDatasource.updateUserDocument(uid, {
        'isOnline': true,
        'lastSeen': now.millisecondsSinceEpoch,
      });
      final updatedData = Map<String, dynamic>.from(docData);
      updatedData['isOnline'] = true;
      updatedData['lastSeen'] = now.millisecondsSinceEpoch;
      return UserModel.fromMap(updatedData);
    }
  }
}
