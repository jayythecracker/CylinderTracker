import 'package:cylinder_management/models/cylinder.dart';
import 'package:cylinder_management/models/user.dart';

class Filling {
  final int id;
  final int cylinderId;
  final int startedById;
  final int? endedById;
  final int lineNumber;
  final DateTime startTime;
  final DateTime? endTime;
  final double initialPressure;
  final double? finalPressure;
  final double targetPressure;
  final String gasType;
  final String status; // InProgress, Completed, Failed
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Optional nested objects
  final Cylinder? cylinder;
  final User? startedBy;
  final User? endedBy;

  Filling({
    required this.id,
    required this.cylinderId,
    required this.startedById,
    this.endedById,
    required this.lineNumber,
    required this.startTime,
    this.endTime,
    required this.initialPressure,
    this.finalPressure,
    required this.targetPressure,
    required this.gasType,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.cylinder,
    this.startedBy,
    this.endedBy,
  });

  // Factory method to create a Filling from JSON
  factory Filling.fromJson(Map<String, dynamic> json) {
    return Filling(
      id: json['id'],
      cylinderId: json['cylinderId'],
      startedById: json['startedById'],
      endedById: json['endedById'],
      lineNumber: json['lineNumber'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      initialPressure: json['initialPressure'] is int 
        ? json['initialPressure'].toDouble() 
        : json['initialPressure'],
      finalPressure: json['finalPressure'] != null 
        ? (json['finalPressure'] is int 
          ? json['finalPressure'].toDouble() 
          : json['finalPressure']) 
        : null,
      targetPressure: json['targetPressure'] is int 
        ? json['targetPressure'].toDouble() 
        : json['targetPressure'],
      gasType: json['gasType'],
      status: json['status'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt']) 
        : DateTime.now(),
      cylinder: json['cylinder'] != null ? Cylinder.fromJson(json['cylinder']) : null,
      startedBy: json['startedBy'] != null ? User.fromJson(json['startedBy']) : null,
      endedBy: json['endedBy'] != null ? User.fromJson(json['endedBy']) : null,
    );
  }

  // Convert Filling to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cylinderId': cylinderId,
      'startedById': startedById,
      'endedById': endedById,
      'lineNumber': lineNumber,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'initialPressure': initialPressure,
      'finalPressure': finalPressure,
      'targetPressure': targetPressure,
      'gasType': gasType,
      'status': status,
      'notes': notes,
    };
  }

  // Create a copy of this Filling with the given fields replaced
  Filling copyWith({
    int? id,
    int? cylinderId,
    int? startedById,
    int? endedById,
    int? lineNumber,
    DateTime? startTime,
    DateTime? endTime,
    double? initialPressure,
    double? finalPressure,
    double? targetPressure,
    String? gasType,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Cylinder? cylinder,
    User? startedBy,
    User? endedBy,
  }) {
    return Filling(
      id: id ?? this.id,
      cylinderId: cylinderId ?? this.cylinderId,
      startedById: startedById ?? this.startedById,
      endedById: endedById ?? this.endedById,
      lineNumber: lineNumber ?? this.lineNumber,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      initialPressure: initialPressure ?? this.initialPressure,
      finalPressure: finalPressure ?? this.finalPressure,
      targetPressure: targetPressure ?? this.targetPressure,
      gasType: gasType ?? this.gasType,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cylinder: cylinder ?? this.cylinder,
      startedBy: startedBy ?? this.startedBy,
      endedBy: endedBy ?? this.endedBy,
    );
  }

  // Create a Filling for new Filling form (for create operation)
  factory Filling.empty() {
    return Filling(
      id: 0,
      cylinderId: 0,
      startedById: 0,
      lineNumber: 1,
      startTime: DateTime.now(),
      initialPressure: 0.0,
      targetPressure: 0.0,
      gasType: '',
      status: 'InProgress',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Helper method to check if filling is in progress
  bool get isInProgress => status == 'InProgress';

  // Helper method to check if filling is completed
  bool get isCompleted => status == 'Completed';

  // Helper method to check if filling failed
  bool get isFailed => status == 'Failed';

  // Helper method to calculate filling duration
  Duration get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    } else {
      return DateTime.now().difference(startTime);
    }
  }

  // Helper method to format duration as string
  String get durationFormatted {
    final duration = this.duration;
    
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
