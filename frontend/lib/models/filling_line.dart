import 'package:flutter/material.dart';
import 'user.dart';
import 'cylinder.dart';

// FillingLine model
class FillingLine {
  final int id;
  final String name;
  final int capacity;
  final FillingLineStatus status;
  final CylinderType cylinderType;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final FillingSession? activeSession; // For displaying active session

  const FillingLine({
    required this.id,
    required this.name,
    required this.capacity,
    required this.status,
    required this.cylinderType,
    required this.isActive,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.activeSession,
  });

  // Factory constructor to create FillingLine from JSON
  factory FillingLine.fromJson(Map<String, dynamic> json) {
    // Handle the case where activeSession is included in the response
    final activeSessionJson = json['activeSession'];
    final activeSession = activeSessionJson != null 
        ? FillingSession.fromJson(activeSessionJson) 
        : null;

    return FillingLine(
      id: json['id'],
      name: json['name'],
      capacity: json['capacity'],
      status: _parseFillingLineStatus(json['status']),
      cylinderType: _parseCylinderType(json['cylinderType']),
      isActive: json['isActive'] ?? true,
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      activeSession: activeSession,
    );
  }

  // Convert FillingLine to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'status': status.name,
      'cylinderType': cylinderType.name,
      'isActive': isActive,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy of the filling line with updated fields
  FillingLine copyWith({
    int? id,
    String? name,
    int? capacity,
    FillingLineStatus? status,
    CylinderType? cylinderType,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    FillingSession? activeSession,
  }) {
    return FillingLine(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      cylinderType: cylinderType ?? this.cylinderType,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      activeSession: activeSession ?? this.activeSession,
    );
  }

  // Parse filling line status from string
  static FillingLineStatus _parseFillingLineStatus(String status) {
    switch (status) {
      case 'idle':
        return FillingLineStatus.idle;
      case 'active':
        return FillingLineStatus.active;
      case 'maintenance':
        return FillingLineStatus.maintenance;
      default:
        return FillingLineStatus.idle;
    }
  }

  // Parse cylinder type from string
  static CylinderType _parseCylinderType(String type) {
    switch (type) {
      case 'medical':
        return CylinderType.medical;
      case 'industrial':
        return CylinderType.industrial;
      default:
        return CylinderType.industrial;
    }
  }
}

// Enum for filling line statuses
enum FillingLineStatus {
  idle,
  active,
  maintenance
}

// Extension to get string representation of the status
extension FillingLineStatusExtension on FillingLineStatus {
  String get name {
    switch (this) {
      case FillingLineStatus.idle:
        return 'idle';
      case FillingLineStatus.active:
        return 'active';
      case FillingLineStatus.maintenance:
        return 'maintenance';
    }
  }

  String get displayName {
    switch (this) {
      case FillingLineStatus.idle:
        return 'Idle';
      case FillingLineStatus.active:
        return 'Active';
      case FillingLineStatus.maintenance:
        return 'Maintenance';
    }
  }

  // Get color associated with the status
  Color get color {
    switch (this) {
      case FillingLineStatus.idle:
        return Colors.grey;
      case FillingLineStatus.active:
        return Colors.green;
      case FillingLineStatus.maintenance:
        return Colors.orange;
    }
  }
}

// FillingSession model
class FillingSession {
  final int id;
  final DateTime startTime;
  final DateTime? endTime;
  final int fillingLineId;
  final FillingLine? fillingLine; // For displaying filling line info
  final int startedById;
  final User? startedBy; // For displaying user info
  final int? endedById;
  final User? endedBy; // For displaying user info
  final String? notes;
  final List<FillingSessionCylinder> cylinders; // For displaying cylinders in session
  final SessionStats? stats; // For displaying session statistics

  const FillingSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.fillingLineId,
    this.fillingLine,
    required this.startedById,
    this.startedBy,
    this.endedById,
    this.endedBy,
    this.notes,
    this.cylinders = const [],
    this.stats,
  });

  // Factory constructor to create FillingSession from JSON
  factory FillingSession.fromJson(Map<String, dynamic> json) {
    // Handle the case where related entities are included in the response
    final fillingLineJson = json['fillingLine'];
    final fillingLine = fillingLineJson != null 
        ? FillingLine.fromJson(fillingLineJson) 
        : null;

    final startedByJson = json['startedBy'];
    final startedBy = startedByJson != null 
        ? User.fromJson(startedByJson) 
        : null;

    final endedByJson = json['endedBy'];
    final endedBy = endedByJson != null 
        ? User.fromJson(endedByJson) 
        : null;

    final cylindersJson = json['cylinders'] as List<dynamic>?;
    final cylinders = cylindersJson != null 
        ? cylindersJson.map((c) => FillingSessionCylinder.fromJson(c)).toList() 
        : <FillingSessionCylinder>[];

    final statsJson = json['stats'];
    final stats = statsJson != null 
        ? SessionStats.fromJson(statsJson) 
        : null;

    return FillingSession(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      fillingLineId: json['fillingLineId'],
      fillingLine: fillingLine,
      startedById: json['startedById'],
      startedBy: startedBy,
      endedById: json['endedById'],
      endedBy: endedBy,
      notes: json['notes'],
      cylinders: cylinders,
      stats: stats,
    );
  }

  // Convert FillingSession to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'fillingLineId': fillingLineId,
      'startedById': startedById,
      'endedById': endedById,
      'notes': notes,
    };
  }
}

// FillingSessionCylinder model
class FillingSessionCylinder {
  final int id;
  final int fillingSessionId;
  final int cylinderId;
  final Cylinder? cylinder; // For displaying cylinder info
  final FillingSessionCylinderStatus status;
  final DateTime? filledAt;
  final double? pressureBeforeFilling;
  final double? pressureAfterFilling;
  final String? notes;

  const FillingSessionCylinder({
    required this.id,
    required this.fillingSessionId,
    required this.cylinderId,
    this.cylinder,
    required this.status,
    this.filledAt,
    this.pressureBeforeFilling,
    this.pressureAfterFilling,
    this.notes,
  });

  // Factory constructor to create FillingSessionCylinder from JSON
  factory FillingSessionCylinder.fromJson(Map<String, dynamic> json) {
    // Handle the case where cylinder is included in the response
    final cylinderJson = json['cylinder'];
    final cylinder = cylinderJson != null 
        ? Cylinder.fromJson(cylinderJson) 
        : null;

    return FillingSessionCylinder(
      id: json['id'],
      fillingSessionId: json['fillingSessionId'],
      cylinderId: json['cylinderId'],
      cylinder: cylinder,
      status: _parseFillingSessionCylinderStatus(json['status']),
      filledAt: json['filledAt'] != null ? DateTime.parse(json['filledAt']) : null,
      pressureBeforeFilling: json['pressureBeforeFilling'] is int 
          ? json['pressureBeforeFilling'].toDouble() 
          : json['pressureBeforeFilling'],
      pressureAfterFilling: json['pressureAfterFilling'] is int 
          ? json['pressureAfterFilling'].toDouble() 
          : json['pressureAfterFilling'],
      notes: json['notes'],
    );
  }

  // Convert FillingSessionCylinder to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fillingSessionId': fillingSessionId,
      'cylinderId': cylinderId,
      'status': status.name,
      'filledAt': filledAt?.toIso8601String(),
      'pressureBeforeFilling': pressureBeforeFilling,
      'pressureAfterFilling': pressureAfterFilling,
      'notes': notes,
    };
  }

  // Parse filling session cylinder status from string
  static FillingSessionCylinderStatus _parseFillingSessionCylinderStatus(String status) {
    switch (status) {
      case 'pending':
        return FillingSessionCylinderStatus.pending;
      case 'filling':
        return FillingSessionCylinderStatus.filling;
      case 'success':
        return FillingSessionCylinderStatus.success;
      case 'failed':
        return FillingSessionCylinderStatus.failed;
      default:
        return FillingSessionCylinderStatus.pending;
    }
  }
}

// Enum for filling session cylinder statuses
enum FillingSessionCylinderStatus {
  pending,
  filling,
  success,
  failed
}

// Extension to get string representation of the status
extension FillingSessionCylinderStatusExtension on FillingSessionCylinderStatus {
  String get name {
    switch (this) {
      case FillingSessionCylinderStatus.pending:
        return 'pending';
      case FillingSessionCylinderStatus.filling:
        return 'filling';
      case FillingSessionCylinderStatus.success:
        return 'success';
      case FillingSessionCylinderStatus.failed:
        return 'failed';
    }
  }

  String get displayName {
    switch (this) {
      case FillingSessionCylinderStatus.pending:
        return 'Pending';
      case FillingSessionCylinderStatus.filling:
        return 'Filling';
      case FillingSessionCylinderStatus.success:
        return 'Success';
      case FillingSessionCylinderStatus.failed:
        return 'Failed';
    }
  }

  // Get color associated with the status
  Color get color {
    switch (this) {
      case FillingSessionCylinderStatus.pending:
        return Colors.grey;
      case FillingSessionCylinderStatus.filling:
        return Colors.blue;
      case FillingSessionCylinderStatus.success:
        return Colors.green;
      case FillingSessionCylinderStatus.failed:
        return Colors.red;
    }
  }
}

// Model for session statistics
class SessionStats {
  final int total;
  final int pending;
  final int filling;
  final int success;
  final int failed;

  const SessionStats({
    required this.total,
    required this.pending,
    required this.filling,
    required this.success,
    required this.failed,
  });

  // Factory constructor to create SessionStats from JSON
  factory SessionStats.fromJson(Map<String, dynamic> json) {
    return SessionStats(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      filling: json['filling'] ?? 0,
      success: json['success'] ?? 0,
      failed: json['failed'] ?? 0,
    );
  }
}
