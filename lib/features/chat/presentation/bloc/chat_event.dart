import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadChats extends ChatEvent {
  final String userId;

  const LoadChats(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadMessages extends ChatEvent {
  final String chatId;

  const LoadMessages(this.chatId);

  @override
  List<Object?> get props => [chatId];
}

class SendTextMessage extends ChatEvent {
  final String chatId;
  final String senderId;
  final String text;

  const SendTextMessage({
    required this.chatId,
    required this.senderId,
    required this.text,
  });

  @override
  List<Object?> get props => [chatId, senderId, text];
}

class SendImageMessage extends ChatEvent {
  final String chatId;
  final String senderId;
  final File image;

  const SendImageMessage({
    required this.chatId,
    required this.senderId,
    required this.image,
  });

  @override
  List<Object?> get props => [chatId, senderId, image];
}

class MarkSeen extends ChatEvent {
  final String chatId;
  final String userId;

  const MarkSeen({
    required this.chatId,
    required this.userId,
  });

  @override
  List<Object?> get props => [chatId, userId];
}
