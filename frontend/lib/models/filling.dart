import 'user.dart';
import 'cylinder.dart';

class FillingLine {
  final int id;
  final String name;
  final int capacity;
  final String gasType;
  final String status;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  FillingLine({
    required this.id,
    required this.name,
    required this.capacity,
    required this.gasType,
    required this.status,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FillingLine.fromJson(Map<String, dynamic> json) {
    return FillingLine(
      id: json['id'],
      name: json['name'],
      capacity: json['capacity'],
      gasType: json['gasType'],
      status: json['status'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'gasType': gasType,
      'status': status,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // For creating a new filling line
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'capacity': capacity,
      'gasType': gasType,
    };
  }

  FillingLine copyWith({
    int? id,
    String? name,
    int? capacity,
    String? gasType,
    String? status,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FillingLine(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      gasType: gasType ?? this.gasType,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FillingBatch {
  final int id;
  final String batchNumber;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final int fillingLineId;
  final int startedById;
  final int? endedById;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final FillingLine? fillingLine;
  final User? startedBy;
  final User? endedBy;
  final List<FillingDetail>? details;

  FillingBatch({
    required this.id,
    required this.batchNumber,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.fillingLineId,
    required this.startedById,
    this.endedById,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.fillingLine,
    this.startedBy,
    this.endedBy,
    this.details,
  });

  factory FillingBatch.fromJson(Map<String, dynamic> json) {
    return FillingBatch(
      id: json['id'],
      batchNumber: json['batchNumber'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      status: json['status'],
      fillingLineId: json['fillingLineId'],
      startedById: json['startedById'],
      endedById: json['endedById'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      fillingLine: json['FillingLine'] != null ? FillingLine.fromJson(json['FillingLine']) : null,
      startedBy: json['StartedBy'] != null ? User.fromJson(json['StartedBy']) : null,
      endedBy: json['EndedBy'] != null ? User.fromJson(json['EndedBy']) : null,
      details: json['FillingDetails'] != null
          ? (json['FillingDetails'] as List).map((e) => FillingDetail.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batchNumber': batchNumber,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status,
      'fillingLineId': fillingLineId,
      'startedById': startedById,
      'endedById': endedById,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // For starting a new filling batch
  Map<String, dynamic> toStartBatchJson() {
    return {
      'fillingLineId': fillingLineId,
      'cylinderIds': details?.map((d) => d.cylinderId).toList() ?? [],
      'notes': notes,
    };
  }

  // For completing a filling batch
  Map<String, dynamic> toCompleteBatchJson() {
    return {
      'cylinderResults': details?.map((d) => {
        'cylinderId': d.cylinderId,
        'finalPressure': d.finalPressure,
        'status': d.status,
        'notes': d.notes,
      }).toList() ?? [],
      'notes': notes,
    };
  }
}

class FillingDetail {
  final int id;
  final int fillingBatchId;
  final int cylinderId;
  final double initialPressure;
  final double? finalPressure;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Cylinder? cylinder;

  FillingDetail({
    required this.id,
    required this.fillingBatchId,
    required this.cylinderId,
    required this.initialPressure,
    this.finalPressure,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.cylinder,
  });

  factory FillingDetail.fromJson(Map<String, dynamic> json) {
    return FillingDetail(
      id: json['id'],
      fillingBatchId: json['fillingBatchId'],
      cylinderId: json['cylinderId'],
      initialPressure: json['initialPressure'].toDouble(),
      finalPressure: json['finalPressure'] != null ? json['finalPressure'].toDouble() : null,
      status: json['status'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      cylinder: json['Cylinder'] != null ? Cylinder.fromJson(json['Cylinder']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fillingBatchId': fillingBatchId,
      'cylinderId': cylinderId,
      'initialPressure': initialPressure,
      'finalPressure': finalPressure,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  FillingDetail copyWith({
    int? id,
    int? fillingBatchId,
    int? cylinderId,
    double? initialPressure,
    double? finalPressure,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Cylinder? cylinder,
  }) {
    return FillingDetail(
      id: id ?? this.id,
      fillingBatchId: fillingBatchId ?? this.fillingBatchId,
      cylinderId: cylinderId ?? this.cylinderId,
      initialPressure: initialPressure ?? this.initialPressure,
      finalPressure: finalPressure ?? this.finalPressure,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cylinder: cylinder ?? this.cylinder,
    );
  }
}
