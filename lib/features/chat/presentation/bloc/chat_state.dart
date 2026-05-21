import 'package:equatable/equatable.dart';
import '../../domain/models/chat_model.dart';
import '../../domain/models/message_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatsLoaded extends ChatState {
  final List<ChatModel> chats;

  const ChatsLoaded(this.chats);

  @override
  List<Object?> get props => [chats];
}

class MessagesLoaded extends ChatState {
  final List<MessageModel> messages;

  const MessagesLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
