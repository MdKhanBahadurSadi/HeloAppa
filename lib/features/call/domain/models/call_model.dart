import 'package:equatable/equatable.dart';

enum CallStatus { ringing, active, ended, rejected }

class CallModel extends Equatable {
  final String callId;
  final String callerId;
  final String callerName;
  final String? callerPhoto;
  final String receiverId;
  final CallStatus status;
  final bool isVideo;
  final int createdAt;
  final Map<String, dynamic>? offer;

  const CallModel({
    required this.callId,
    required this.callerId,
    required this.callerName,
    this.callerPhoto,
    required this.receiverId,
    required this.status,
    required this.isVideo,
    required this.createdAt,
    this.offer,
  });

  CallModel copyWith({
    String? callId,
    String? callerId,
    String? callerName,
    String? callerPhoto,
    String? receiverId,
    CallStatus? status,
    bool? isVideo,
    int? createdAt,
    Map<String, dynamic>? offer,
  }) {
    return CallModel(
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerPhoto: callerPhoto ?? this.callerPhoto,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      isVideo: isVideo ?? this.isVideo,
      createdAt: createdAt ?? this.createdAt,
      offer: offer ?? this.offer,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'callerId': callerId,
      'callerName': callerName,
      'callerPhoto': callerPhoto,
      'receiverId': receiverId,
      'status': status.name,
      'isVideo': isVideo,
      'createdAt': createdAt,
      if (offer != null) 'offer': offer,
    };
  }

  factory CallModel.fromMap(Map<String, dynamic> map) {
    CallStatus parseStatus(String? statusStr) {
      switch (statusStr) {
        case 'active':
          return CallStatus.active;
        case 'ended':
          return CallStatus.ended;
        case 'rejected':
          return CallStatus.rejected;
        case 'ringing':
        default:
          return CallStatus.ringing;
      }
    }

    return CallModel(
      callId: map['callId'] ?? '',
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerPhoto: map['callerPhoto'],
      receiverId: map['receiverId'] ?? '',
      status: parseStatus(map['status']),
      isVideo: map['isVideo'] ?? false,
      createdAt: map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      offer: map['offer'] != null ? Map<String, dynamic>.from(map['offer'] as Map) : null,
    );
  }

  @override
  List<Object?> get props => [
        callId,
        callerId,
        callerName,
        callerPhoto,
        receiverId,
        status,
        isVideo,
        createdAt,
        offer,
      ];
}
