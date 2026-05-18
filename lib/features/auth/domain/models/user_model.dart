import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? fcmToken;
  final bool isOnline;
  final DateTime lastSeen;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.fcmToken,
    required this.isOnline,
    required this.lastSeen,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'isOnline': isOnline,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      fcmToken: map['fcmToken'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen']) 
          : DateTime.now(),
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? fcmToken,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  List<Object?> get props => [id, name, email, photoUrl, fcmToken, isOnline, lastSeen];
}
