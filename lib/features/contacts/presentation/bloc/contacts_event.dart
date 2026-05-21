import 'package:equatable/equatable.dart';

abstract class ContactsEvent extends Equatable {
  const ContactsEvent();

  @override
  List<Object?> get props => [];
}

class LoadContacts extends ContactsEvent {
  final String currentUserId;

  const LoadContacts(this.currentUserId);

  @override
  List<Object?> get props => [currentUserId];
}

class SearchContacts extends ContactsEvent {
  final String query;

  const SearchContacts(this.query);

  @override
  List<Object?> get props => [query];
}
