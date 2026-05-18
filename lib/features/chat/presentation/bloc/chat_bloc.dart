import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/chat_model.dart';
import '../../domain/models/message_model.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../../../core/utils/error_handler.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  StreamSubscription? _chatsSubscription;
  StreamSubscription? _messagesSubscription;

  ChatBloc({required this.chatRepository}) : super(ChatInitial()) {
    on<LoadChats>(_onLoadChats);
    on<LoadMessages>(_onLoadMessages);
    on<SendTextMessage>(_onSendTextMessage);
    on<SendImageMessage>(_onSendImageMessage);
    on<MarkSeen>(_onMarkSeen);
    on<_UpdateChats>(_onUpdateChatsInternal);
    on<_UpdateMessages>(_onUpdateMessagesInternal);
  }

  Future<void> _onLoadChats(LoadChats event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    await _chatsSubscription?.cancel();
    _chatsSubscription = chatRepository.getUserChats(event.userId).listen(
      (chats) => add(_UpdateChats(chats)),
      onError: (e) => emit(ChatError(ErrorHandler.getMessage(e))),
    );
  }

  void _onUpdateChatsInternal(_UpdateChats event, Emitter<ChatState> emit) {
    emit(ChatsLoaded(List<ChatModel>.from(event.chats)));
  }

  Future<void> _onLoadMessages(LoadMessages event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    await _messagesSubscription?.cancel();
    _messagesSubscription = chatRepository.getMessages(event.chatId).listen(
      (messages) => add(_UpdateMessages(messages)),
      onError: (e) => emit(ChatError(ErrorHandler.getMessage(e))),
    );
  }

  void _onUpdateMessagesInternal(_UpdateMessages event, Emitter<ChatState> emit) {
    emit(MessagesLoaded(List<MessageModel>.from(event.messages)));
  }

  Future<void> _onSendTextMessage(SendTextMessage event, Emitter<ChatState> emit) async {
    try {
      final message = MessageModel(
        id: const Uuid().v4(),
        chatId: event.chatId,
        senderId: event.senderId,
        text: event.text,
        type: MessageType.text,
        timestamp: DateTime.now(),
        seenBy: [event.senderId],
      );
      await chatRepository.sendMessage(message);
    } catch (e) {
      emit(ChatError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> _onSendImageMessage(SendImageMessage event, Emitter<ChatState> emit) async {
    try {
      await chatRepository.sendImageMessage(event.chatId, event.senderId, event.image);
    } catch (e) {
      emit(ChatError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> _onMarkSeen(MarkSeen event, Emitter<ChatState> emit) async {
    try {
      await chatRepository.markMessagesSeen(event.chatId, event.userId);
    } catch (e) {
      // Silently fail for seen status
    }
  }

  @override
  Future<void> close() {
    _chatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    return super.close();
  }
}

class _UpdateChats extends ChatEvent {
  final List<dynamic> chats;
  const _UpdateChats(this.chats);
}

class _UpdateMessages extends ChatEvent {
  final List<dynamic> messages;
  const _UpdateMessages(this.messages);
}
