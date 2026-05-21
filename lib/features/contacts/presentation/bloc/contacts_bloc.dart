import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/contacts_repository.dart';
import 'contacts_event.dart';
import 'contacts_state.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  final ContactsRepository _contactsRepository;
  StreamSubscription? _contactsSubscription;

  ContactsBloc({required ContactsRepository contactsRepository})
      : _contactsRepository = contactsRepository,
        super(ContactsInitial()) {
    on<LoadContacts>(_onLoadContacts);
    on<SearchContacts>(_onSearchContacts);
  }

  Future<void> _onLoadContacts(
    LoadContacts event,
    Emitter<ContactsState> emit,
  ) async {
    emit(ContactsLoading());
    await _contactsSubscription?.cancel();
    _contactsSubscription = _contactsRepository
        .getAllUsers(event.currentUserId)
        .listen(
      (contactsList) {
        // Emit loaded state
        // If current state is ContactsLoaded, keep query? No, just emit with full list
        add(SearchContacts('')); 
        // Wait, to avoid dispatching search during load, we can emit directly, or let search handle it.
        // Let's store the raw contacts list in state or emit ContactsLoaded directly.
        // Actually, we can check if we should do filtering on the new list.
        emit(ContactsLoaded(
          contacts: contactsList,
          filtered: contactsList,
        ));
      },
      onError: (error) {
        emit(ContactsError(error.toString()));
      },
    );
  }

  void _onSearchContacts(
    SearchContacts event,
    Emitter<ContactsState> emit,
  ) {
    final currentState = state;
    if (currentState is ContactsLoaded) {
      if (event.query.isEmpty) {
        emit(ContactsLoaded(
          contacts: currentState.contacts,
          filtered: currentState.contacts,
        ));
      } else {
        final filteredList = currentState.contacts.where((contact) {
          return contact.name.toLowerCase().contains(event.query.toLowerCase());
        }).toList();
        emit(ContactsLoaded(
          contacts: currentState.contacts,
          filtered: filteredList,
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _contactsSubscription?.cancel();
    return super.close();
  }
}
