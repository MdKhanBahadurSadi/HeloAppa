import 'package:equatable/equatable.dart';
import '../../domain/models/contact_model.dart';

abstract class ContactsState extends Equatable {
  const ContactsState();

  @override
  List<Object?> get props => [];
}

class ContactsInitial extends ContactsState {}

class ContactsLoading extends ContactsState {}

class ContactsLoaded extends ContactsState {
  final List<ContactModel> contacts;
  final List<ContactModel> filtered;

  const ContactsLoaded({
    required this.contacts,
    required this.filtered,
  });

  @override
  List<Object?> get props => [contacts, filtered];
}

class ContactsError extends ContactsState {
  final String message;

  const ContactsError(this.message);

  @override
  List<Object?> get props => [message];
}
