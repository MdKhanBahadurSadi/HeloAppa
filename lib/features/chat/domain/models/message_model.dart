import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

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
    DateTime parseTimestamp(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    MessageType parseType(String? typeStr) {
      switch (typeStr) {
        case 'image':
          return MessageType.image;
        case 'audio':
          return MessageType.audio;
        case 'text':
        default:
          return MessageType.text;
      }
    }

    return MessageModel(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      type: parseType(map['type']),
      timestamp: parseTimestamp(map['timestamp']),
      seenBy: List<String>.from(map['seenBy'] ?? []),
      mediaUrl: map['mediaUrl'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        text,
        type,
        timestamp,
        seenBy,
        mediaUrl,
      ];
}
