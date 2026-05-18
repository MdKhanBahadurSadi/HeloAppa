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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserPhotoUrl': otherUserPhotoUrl,
      'otherUserIsOnline': otherUserIsOnline,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime']) 
          : DateTime.now(),
      unreadCount: map['unreadCount'] ?? 0,
      otherUserId: map['otherUserId'] ?? '',
      otherUserName: map['otherUserName'] ?? '',
      otherUserPhotoUrl: map['otherUserPhotoUrl'],
      otherUserIsOnline: map['otherUserIsOnline'] ?? false,
    );
  }

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
