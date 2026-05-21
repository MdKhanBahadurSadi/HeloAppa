import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/chat_model.dart';
import '../../domain/models/message_model.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final Uuid _uuid = const Uuid();

  StreamSubscription? _chatsSubscription;
  StreamSubscription? _messagesSubscription;

  ChatBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(ChatInitial()) {
    on<LoadChats>(_onLoadChats);
    on<LoadMessages>(_onLoadMessages);
    on<SendTextMessage>(_onSendTextMessage);
    on<SendImageMessage>(_onSendImageMessage);
    on<MarkSeen>(_onMarkSeen);
    on<_UpdateChats>(_onUpdateChats);
    on<_UpdateMessages>(_onUpdateMessages);
    on<_EmitError>(_onEmitError);
  }

  Future<void> _onLoadChats(
    LoadChats event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    await _chatsSubscription?.cancel();
    _chatsSubscription = _chatRepository.getUserChats(event.userId).listen(
      (chats) => add(_UpdateChats(chats)),
      onError: (error) => add(_EmitError(error.toString())),
    );
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    await _messagesSubscription?.cancel();
    _messagesSubscription = _chatRepository.getMessages(event.chatId).listen(
      (messages) => add(_UpdateMessages(messages)),
      onError: (error) => add(_EmitError(error.toString())),
    );
  }

  Future<void> _onSendTextMessage(
    SendTextMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final message = MessageModel(
        id: _uuid.v4(),
        chatId: event.chatId,
        senderId: event.senderId,
        text: event.text,
        type: MessageType.text,
        timestamp: DateTime.now(),
        seenBy: [event.senderId],
        mediaUrl: null,
      );
      await _chatRepository.sendMessage(message);
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onSendImageMessage(
    SendImageMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.sendImageMessage(
        event.chatId,
        event.senderId,
        event.image,
      );
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onMarkSeen(
    MarkSeen event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatRepository.markMessagesSeen(event.chatId, event.userId);
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  void _onUpdateChats(_UpdateChats event, Emitter<ChatState> emit) {
    emit(ChatsLoaded(event.chats));
  }

  void _onUpdateMessages(_UpdateMessages event, Emitter<ChatState> emit) {
    emit(MessagesLoaded(event.messages));
  }

  void _onEmitError(_EmitError event, Emitter<ChatState> emit) {
    emit(ChatError(event.message));
  }

  @override
  Future<void> close() {
    _chatsSubscription?.cancel();
    _messagesSubscription?.cancel();
    return super.close();
  }
}

// Internal events to safely emit states from listener streams
class _UpdateChats extends ChatEvent {
  final List<ChatModel> chats;
  const _UpdateChats(this.chats);

  @override
  List<Object?> get props => [chats];
}

class _UpdateMessages extends ChatEvent {
  final List<MessageModel> messages;
  const _UpdateMessages(this.messages);

  @override
  List<Object?> get props => [messages];
}

class _EmitError extends ChatEvent {
  final String message;
  const _EmitError(this.message);

  @override
  List<Object?> get props => [message];
}
