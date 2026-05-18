import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, audio }

class MessageModel extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final List<String> seenBy;
  final String? mediaUrl;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.type,
    required this.timestamp,
    required this.seenBy,
    this.mediaUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'seenBy': seenBy,
      'mediaUrl': mediaUrl,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      type: MessageType.values.byName(map['type'] ?? 'text'),
      timestamp: map['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp']) 
          : DateTime.now(),
      seenBy: List<String>.from(map['seenBy'] ?? []),
      mediaUrl: map['mediaUrl'],
    );
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    MessageType? type,
    DateTime? timestamp,
    List<String>? seenBy,
    String? mediaUrl,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      seenBy: seenBy ?? this.seenBy,
      mediaUrl: mediaUrl ?? this.mediaUrl,
    );
  }

  @override
  List<Object?> get props => [id, chatId, senderId, text, type, timestamp, seenBy, mediaUrl];
}
