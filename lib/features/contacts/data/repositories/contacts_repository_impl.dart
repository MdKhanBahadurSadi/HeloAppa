import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/contact_model.dart';
import '../../domain/repositories/contacts_repository.dart';
import '../../../../core/constants/app_constants.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<ContactModel>> getAllUsers(String currentUserId) {
    return _firestore
        .collection(AppConstants.USERS)
        .snapshots()
        .map((snapshot) {
      final users = snapshot.docs
          .map((doc) => ContactModel.fromMap(doc.data()))
          .where((user) => user.uid != currentUserId)
          .toList();
      
      // Sort by isOnline desc then name asc
      users.sort((a, b) {
        if (a.isOnline != b.isOnline) {
          return a.isOnline ? -1 : 1;
        }
        return a.name.compareTo(b.name);
      });
      
      return users;
    });
  }

  @override
  Future<ContactModel?> getUserById(String uid) async {
    final doc = await _firestore.collection(AppConstants.USERS).doc(uid).get();
    if (!doc.exists) return null;
    return ContactModel.fromMap(doc.data()!);
  }
}
