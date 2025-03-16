// Cylinder model
class Cylinder {
  final int id;
  final String serialNumber;
  final double size;
  final DateTime? importDate;
  final DateTime? productionDate;
  final String? originalNumber;
  final double workingPressure;
  final double designPressure;
  final CylinderType type;
  final CylinderStatus status;
  final DateTime? lastFilled;
  final DateTime? lastInspected;
  final int factoryId;
  final String? factoryName;  // For displaying factory info
  final bool isActive;
  final String? notes;
  final String qrCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Cylinder({
    required this.id,
    required this.serialNumber,
    required this.size,
    this.importDate,
    this.productionDate,
    this.originalNumber,
    required this.workingPressure,
    required this.designPressure,
    required this.type,
    required this.status,
    this.lastFilled,
    this.lastInspected,
    required this.factoryId,
    this.factoryName,
    required this.isActive,
    this.notes,
    required this.qrCode,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create Cylinder from JSON
  factory Cylinder.fromJson(Map<String, dynamic> json) {
    // Handle the case where factory is included in the response
    final factory = json['factory'];
    final factoryName = factory != null ? factory['name'] : null;

    return Cylinder(
      id: json['id'],
      serialNumber: json['serialNumber'],
      size: json['size'] is int ? json['size'].toDouble() : json['size'],
      importDate: json['importDate'] != null ? DateTime.parse(json['importDate']) : null,
      productionDate: json['productionDate'] != null ? DateTime.parse(json['productionDate']) : null,
      originalNumber: json['originalNumber'],
      workingPressure: json['workingPressure'] is int ? json['workingPressure'].toDouble() : json['workingPressure'],
      designPressure: json['designPressure'] is int ? json['designPressure'].toDouble() : json['designPressure'],
      type: _parseCylinderType(json['type']),
      status: _parseCylinderStatus(json['status']),
      lastFilled: json['lastFilled'] != null ? DateTime.parse(json['lastFilled']) : null,
      lastInspected: json['lastInspected'] != null ? DateTime.parse(json['lastInspected']) : null,
      factoryId: json['factoryId'],
      factoryName: factoryName,
      isActive: json['isActive'] ?? true,
      notes: json['notes'],
      qrCode: json['qrCode'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Convert Cylinder to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serialNumber': serialNumber,
      'size': size,
      'importDate': importDate?.toIso8601String(),
      'productionDate': productionDate?.toIso8601String(),
      'originalNumber': originalNumber,
      'workingPressure': workingPressure,
      'designPressure': designPressure,
      'type': type.name,
      'status': status.name,
      'lastFilled': lastFilled?.toIso8601String(),
      'lastInspected': lastInspected?.toIso8601String(),
      'factoryId': factoryId,
      'isActive': isActive,
      'notes': notes,
      'qrCode': qrCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy of the cylinder with updated fields
  Cylinder copyWith({
    int? id,
    String? serialNumber,
    double? size,
    DateTime? importDate,
    DateTime? productionDate,
    String? originalNumber,
    double? workingPressure,
    double? designPressure,
    CylinderType? type,
    CylinderStatus? status,
    DateTime? lastFilled,
    DateTime? lastInspected,
    int? factoryId,
    String? factoryName,
    bool? isActive,
    String? notes,
    String? qrCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cylinder(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      size: size ?? this.size,
      importDate: importDate ?? this.importDate,
      productionDate: productionDate ?? this.productionDate,
      originalNumber: originalNumber ?? this.originalNumber,
      workingPressure: workingPressure ?? this.workingPressure,
      designPressure: designPressure ?? this.designPressure,
      type: type ?? this.type,
      status: status ?? this.status,
      lastFilled: lastFilled ?? this.lastFilled,
      lastInspected: lastInspected ?? this.lastInspected,
      factoryId: factoryId ?? this.factoryId,
      factoryName: factoryName ?? this.factoryName,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      qrCode: qrCode ?? this.qrCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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

  // Parse cylinder status from string
  static CylinderStatus _parseCylinderStatus(String status) {
    switch (status) {
      case 'empty':
        return CylinderStatus.empty;
      case 'filled':
        return CylinderStatus.filled;
      case 'inspection':
        return CylinderStatus.inspection;
      case 'error':
        return CylinderStatus.error;
      case 'maintenance':
        return CylinderStatus.maintenance;
      default:
        return CylinderStatus.empty;
    }
  }
}

// Enum for cylinder types
enum CylinderType {
  medical,
  industrial
}

// Extension to get string representation of the type
extension CylinderTypeExtension on CylinderType {
  String get name {
    switch (this) {
      case CylinderType.medical:
        return 'medical';
      case CylinderType.industrial:
        return 'industrial';
    }
  }

  String get displayName {
    switch (this) {
      case CylinderType.medical:
        return 'Medical';
      case CylinderType.industrial:
        return 'Industrial';
    }
  }
}

// Enum for cylinder statuses
enum CylinderStatus {
  empty,
  filled,
  inspection,
  error,
  maintenance
}

// Extension to get string representation of the status
extension CylinderStatusExtension on CylinderStatus {
  String get name {
    switch (this) {
      case CylinderStatus.empty:
        return 'empty';
      case CylinderStatus.filled:
        return 'filled';
      case CylinderStatus.inspection:
        return 'inspection';
      case CylinderStatus.error:
        return 'error';
      case CylinderStatus.maintenance:
        return 'maintenance';
    }
  }

  String get displayName {
    switch (this) {
      case CylinderStatus.empty:
        return 'Empty';
      case CylinderStatus.filled:
        return 'Filled';
      case CylinderStatus.inspection:
        return 'In Inspection';
      case CylinderStatus.error:
        return 'Error';
      case CylinderStatus.maintenance:
        return 'In Maintenance';
    }
  }

  // Get color associated with the status
  Color get color {
    switch (this) {
      case CylinderStatus.empty:
        return Colors.grey;
      case CylinderStatus.filled:
        return Colors.green;
      case CylinderStatus.inspection:
        return Colors.blue;
      case CylinderStatus.error:
        return Colors.red;
      case CylinderStatus.maintenance:
        return Colors.orange;
    }
  }
}

import 'package:flutter/material.dart';
