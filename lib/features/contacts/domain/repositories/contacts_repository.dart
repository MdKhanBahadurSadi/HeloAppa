import '../models/contact_model.dart';

abstract class ContactsRepository {
  Stream<List<ContactModel>> getAllUsers(String currentUserId);
  Future<ContactModel?> getUserById(String uid);
}
