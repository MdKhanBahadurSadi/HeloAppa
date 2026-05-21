import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ContactModel extends Equatable {
  final String uid;
  final String name;
  final String? photoUrl;
  final bool isOnline;
  final DateTime lastSeen;

  const ContactModel({
    required this.uid,
    required this.name,
    this.photoUrl,
    required this.isOnline,
    required this.lastSeen,
  });

  ContactModel copyWith({
    String? uid,
    String? name,
    String? photoUrl,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return ContactModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid, // We can store as 'id' or 'uid', let's supply 'id' as in UserModel
      'name': name,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
    };
  }

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    DateTime parseLastSeen(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    // Handle both 'id' or 'uid' fields that might come from Firestore
    final id = map['id'] ?? map['uid'] ?? '';

    return ContactModel(
      uid: id,
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: parseLastSeen(map['lastSeen']),
    );
  }

  @override
  List<Object?> get props => [uid, name, photoUrl, isOnline, lastSeen];
}
