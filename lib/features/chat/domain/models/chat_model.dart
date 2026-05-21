import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ChatModel extends Equatable {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final bool otherUserIsOnline;

  const ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
    required this.otherUserIsOnline,
  });

  ChatModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    String? otherUserId,
    String? otherUserName,
    String? otherUserPhotoUrl,
    bool? otherUserIsOnline,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserPhotoUrl: otherUserPhotoUrl ?? this.otherUserPhotoUrl,
      otherUserIsOnline: otherUserIsOnline ?? this.otherUserIsOnline,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
    };
  }

  factory ChatModel.fromMap(
    Map<String, dynamic> map, {
    String? id,
    String? otherUserId,
    String? otherUserName,
    String? otherUserPhotoUrl,
    bool? otherUserIsOnline,
    int? unreadCount,
  }) {
    DateTime parseTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    return ChatModel(
      id: id ?? map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: parseTime(map['lastMessageTime']),
      unreadCount: unreadCount ?? 0,
      otherUserId: otherUserId ?? '',
      otherUserName: otherUserName ?? '',
      otherUserPhotoUrl: otherUserPhotoUrl,
      otherUserIsOnline: otherUserIsOnline ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        participants,
        lastMessage,
        lastMessageTime,
        unreadCount,
        otherUserId,
        otherUserName,
        otherUserPhotoUrl,
        otherUserIsOnline,
      ];
}
