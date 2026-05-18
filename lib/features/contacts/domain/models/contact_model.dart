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

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      uid: map['id'] ?? map['uid'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null 
          ? (map['lastSeen'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen']) 
              : (map['lastSeen'] as Timestamp).toDate())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'photoUrl': photoUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
    };
  }

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

  @override
  List<Object?> get props => [uid, name, photoUrl, isOnline, lastSeen];
}

// Note: Using Timestamp from cloud_firestore
import 'package:cloud_firestore/cloud_firestore.dart';
