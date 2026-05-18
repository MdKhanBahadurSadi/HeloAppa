import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:rxdart/rxdart.dart';
import '../../../core/constants/app_constants.dart';
import '../../domain/models/chat_model.dart';
import '../../domain/models/message_model.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  @override
  Future<String> getOrCreateChat(String currentUserId, String otherUserId) async {
    final query = await _firestore
        .collection(AppConstants.CHATS)
        .where('participants', arrayContains: currentUserId)
        .get();

    for (var doc in query.docs) {
      List participants = doc.data()['participants'];
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    final newChatDoc = _firestore.collection(AppConstants.CHATS).doc();
    await newChatDoc.set({
      'id': newChatDoc.id,
      'participants': [currentUserId, otherUserId],
      'lastMessage': '',
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
    });

    return newChatDoc.id;
  }

  @override
  Stream<List<ChatModel>> getUserChats(String currentUserId) {
    return _firestore
        .collection(AppConstants.CHATS)
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .switchMap((snapshot) {
      if (snapshot.docs.isEmpty) return Stream.value([]);

      final chatStreams = snapshot.docs.map((doc) {
        final data = doc.data();
        final participants = List<String>.from(data['participants']);
        final otherUserId = participants.firstWhere((id) => id != currentUserId);

        return _firestore
            .collection(AppConstants.USERS)
            .doc(otherUserId)
            .snapshots()
            .map((userDoc) {
          final userData = userDoc.data() ?? {};
          return ChatModel.fromMap({
            ...data,
            'otherUserId': otherUserId,
            'otherUserName': userData['name'] ?? 'Unknown',
            'otherUserPhotoUrl': userData['photoUrl'],
            'otherUserIsOnline': userData['isOnline'] ?? false,
          });
        });
      }).toList();

      return CombineLatestStream.list(chatStreams).map((chats) {
        return chats..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      });
    });
  }

  @override
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection(AppConstants.CHATS)
        .doc(chatId)
        .collection(AppConstants.MESSAGES)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    final messageRef = _firestore
        .collection(AppConstants.CHATS)
        .doc(message.chatId)
        .collection(AppConstants.MESSAGES)
        .doc(message.id);

    await _firestore.runTransaction((transaction) async {
      transaction.set(messageRef, message.toMap());
      transaction.update(_firestore.collection(AppConstants.CHATS).doc(message.chatId), {
        'lastMessage': message.type == MessageType.text ? message.text : 'Image',
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
      });
    });
  }

  @override
  Future<void> markMessagesSeen(String chatId, String userId) async {
    final query = await _firestore
        .collection(AppConstants.CHATS)
        .doc(chatId)
        .collection(AppConstants.MESSAGES)
        .where('senderId', isNotEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (var doc in query.docs) {
      final seenBy = List<String>.from(doc.data()['seenBy'] ?? []);
      if (!seenBy.contains(userId)) {
        seenBy.add(userId);
        batch.update(doc.reference, {'seenBy': seenBy});
      }
    }
    await batch.commit();
  }

  @override
  Future<void> sendImageMessage(String chatId, String senderId, File imageFile) async {
    final messageId = _uuid.v4();
    final ref = _storage.ref().child('chat_media/$chatId/$messageId.jpg');
    
    final uploadTask = await ref.putFile(imageFile);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    final message = MessageModel(
      id: messageId,
      chatId: chatId,
      senderId: senderId,
      text: '',
      type: MessageType.image,
      timestamp: DateTime.now(),
      seenBy: [senderId],
      mediaUrl: downloadUrl,
    );

    await sendMessage(message);
  }
}
