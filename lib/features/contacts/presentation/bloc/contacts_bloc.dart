import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/contact_model.dart';
import '../../domain/repositories/contacts_repository.dart';
import '../../../../core/utils/error_handler.dart';
import 'contacts_event.dart';
import 'contacts_state.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  final ContactsRepository contactsRepository;
  StreamSubscription? _contactsSubscription;

  ContactsBloc({required this.contactsRepository}) : super(ContactsInitial()) {
    on<LoadContacts>(_onLoadContacts);
    on<SearchContacts>(_onSearchContacts);
    on<_UpdateContacts>(_onUpdateContactsInternal);
  }

  Future<void> _onLoadContacts(LoadContacts event, Emitter<ContactsState> emit) async {
    emit(ContactsLoading());
    await _contactsSubscription?.cancel();
    _contactsSubscription = contactsRepository.getAllUsers(event.currentUserId).listen(
      (contacts) => add(_UpdateContacts(contacts)),
      onError: (e) => emit(ContactsError(ErrorHandler.getMessage(e))),
    );
  }

  void _onUpdateContactsInternal(_UpdateContacts event, Emitter<ContactsState> emit) {
    emit(ContactsLoaded(
      List<ContactModel>.from(event.contacts),
      List<ContactModel>.from(event.contacts),
    ));
  }

  void _onSearchContacts(SearchContacts event, Emitter<ContactsState> emit) {
    if (state is ContactsLoaded) {
      final currentState = state as ContactsLoaded;
      final filtered = currentState.contacts
          .where((c) => c.name.toLowerCase().contains(event.query.toLowerCase()))
          .toList();
      emit(ContactsLoaded(currentState.contacts, filtered));
    }
  }

  @override
  Future<void> close() {
    _contactsSubscription?.cancel();
    return super.close();
  }
}

class _UpdateContacts extends ContactsEvent {
  final List<dynamic> contacts;
  const _UpdateContacts(this.contacts);
}
