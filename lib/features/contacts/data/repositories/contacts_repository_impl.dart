import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/contact_model.dart';
import '../../domain/repositories/contacts_repository.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<ContactModel>> getAllUsers(String currentUserId) {
    return _firestore
        .collection(AppConstants.USERS)
        .snapshots()
        .map((snapshot) {
      final contacts = snapshot.docs
          .map((doc) => ContactModel.fromMap(doc.data()))
          .where((contact) => contact.uid != currentUserId)
          .toList();

      // Sort: isOnline desc (online first), then name asc
      contacts.sort((a, b) {
        if (a.isOnline != b.isOnline) {
          return a.isOnline ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return contacts;
    });
  }

  @override
  Future<ContactModel?> getUserById(String uid) async {
    final doc = await _firestore.collection(AppConstants.USERS).doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return ContactModel.fromMap(doc.data()!);
    }
    return null;
  }
}
