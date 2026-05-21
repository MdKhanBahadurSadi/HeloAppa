import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/chat_model.dart';
import '../../domain/models/message_model.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  @override
  Future<String> getOrCreateChat(String currentUserId, String otherUserId) async {
    final chatsRef = _firestore.collection(AppConstants.CHATS);

    // Query chats where participants list contains currentUserId
    final querySnapshot = await chatsRef
        .where('participants', arrayContains: currentUserId)
        .get();

    // Check in-memory if otherUserId is in the participants list
    for (final doc in querySnapshot.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    // Chat not found, create new chat doc
    final newChatRef = chatsRef.doc();
    await newChatRef.set({
      'id': newChatRef.id,
      'participants': [currentUserId, otherUserId],
      'lastMessage': '',
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      'unreadCount': {
        currentUserId: 0,
        otherUserId: 0,
      },
    });

    return newChatRef.id;
  }

  @override
  Stream<List<ChatModel>> getUserChats(String currentUserId) {
    return _firestore
        .collection(AppConstants.CHATS)
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((chatsSnapshot) async {
      final chatModels = <ChatModel>[];

      for (final doc in chatsSnapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );

        String otherUserName = '';
        String? otherUserPhotoUrl;
        bool otherUserIsOnline = false;

        if (otherUserId.isNotEmpty) {
          final userDoc = await _firestore
              .collection(AppConstants.USERS)
              .doc(otherUserId)
              .get();
          if (userDoc.exists && userDoc.data() != null) {
            final userData = userDoc.data()!;
            otherUserName = userData['name'] ?? '';
            otherUserPhotoUrl = userData['photoUrl'];
            otherUserIsOnline = userData['isOnline'] ?? false;
          }
        }

        int unread = 0;
        final unreadMap = data['unreadCount'];
        if (unreadMap is Map) {
          unread = unreadMap[currentUserId] as int? ?? 0;
        } else if (unreadMap is int) {
          unread = unreadMap;
        }

        chatModels.add(ChatModel.fromMap(
          data,
          id: doc.id,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          otherUserPhotoUrl: otherUserPhotoUrl,
          otherUserIsOnline: otherUserIsOnline,
          unreadCount: unread,
        ));
      }

      // Sort by lastMessageTime desc
      chatModels.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return chatModels;
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
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .toList();
    });
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    final chatDocRef = _firestore.collection(AppConstants.CHATS).doc(message.chatId);

    // Save message in subcollection
    final messageDocRef = chatDocRef.collection(AppConstants.MESSAGES).doc(message.id);
    await messageDocRef.set(message.toMap());

    // Retrieve participants to increment unreadCount
    final chatDoc = await chatDocRef.get();
    if (chatDoc.exists && chatDoc.data() != null) {
      final data = chatDoc.data()!;
      final participants = List<String>.from(data['participants'] ?? []);
      final unreadMap = Map<String, dynamic>.from(data['unreadCount'] ?? {});

      for (final participant in participants) {
        if (participant != message.senderId) {
          unreadMap[participant] = (unreadMap[participant] as int? ?? 0) + 1;
        }
      }

      await chatDocRef.update({
        'lastMessage': message.text.isNotEmpty ? message.text : '[Media]',
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
        'unreadCount': unreadMap,
      });
    } else {
      await chatDocRef.update({
        'lastMessage': message.text.isNotEmpty ? message.text : '[Media]',
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
      });
    }
  }

  @override
  Future<void> markMessagesSeen(String chatId, String userId) async {
    final chatDocRef = _firestore.collection(AppConstants.CHATS).doc(chatId);
    final messagesRef = chatDocRef.collection(AppConstants.MESSAGES);

    final querySnapshot = await messagesRef.get();
    final batch = _firestore.batch();
    bool needsCommit = false;

    for (final doc in querySnapshot.docs) {
      final seenBy = List<String>.from(doc.data()['seenBy'] ?? []);
      if (!seenBy.contains(userId)) {
        seenBy.add(userId);
        batch.update(doc.reference, {'seenBy': seenBy});
        needsCommit = true;
      }
    }

    if (needsCommit) {
      await batch.commit();
    }

    // Reset unread count for current user
    final chatDoc = await chatDocRef.get();
    if (chatDoc.exists && chatDoc.data() != null) {
      final unreadMap = Map<String, dynamic>.from(chatDoc.data()!['unreadCount'] ?? {});
      unreadMap[userId] = 0;
      await chatDocRef.update({'unreadCount': unreadMap});
    }
  }

  @override
  Future<void> sendImageMessage(String chatId, String senderId, File imageFile) async {
    final uuidName = _uuid.v4();
    final storageRef = _storage
        .ref()
        .child('chat_media')
        .child(chatId)
        .child('$uuidName.jpg');

    final uploadTask = storageRef.putFile(imageFile);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    final message = MessageModel(
      id: _uuid.v4(),
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
