import 'dart:io';
import '../models/chat_model.dart';
import '../models/message_model.dart';

abstract class ChatRepository {
  Future<String> getOrCreateChat(String currentUserId, String otherUserId);
  Stream<List<ChatModel>> getUserChats(String currentUserId);
  Stream<List<MessageModel>> getMessages(String chatId);
  Future<void> sendMessage(MessageModel message);
  Future<void> markMessagesSeen(String chatId, String userId);
  Future<void> sendImageMessage(String chatId, String senderId, File imageFile);
}
