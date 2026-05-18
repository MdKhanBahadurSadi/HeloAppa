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
  final DateTime createdAt;

  const CallModel({
    required this.callId,
    required this.callerId,
    required this.callerName,
    this.callerPhoto,
    required this.receiverId,
    required this.status,
    required this.isVideo,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'callerId': callerId,
      'callerName': callerName,
      'callerPhoto': callerPhoto,
      'receiverId': receiverId,
      'status': status.name,
      'isVideo': isVideo,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory CallModel.fromMap(Map<String, dynamic> map) {
    return CallModel(
      callId: map['callId'] ?? '',
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerPhoto: map['callerPhoto'],
      receiverId: map['receiverId'] ?? '',
      status: CallStatus.values.byName(map['status'] ?? 'ringing'),
      isVideo: map['isVideo'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
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
      ];
}
