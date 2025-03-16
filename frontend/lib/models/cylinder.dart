import 'package:cylinder_management/models/factory.dart';
import 'package:cylinder_management/models/cylinder_type.dart';

class Cylinder {
  final int id;
  final String serialNumber;
  final String size;
  final String type; // Medical or Industrial
  final String gasType; // Oxygen, Nitrogen, etc.
  final DateTime? importDate;
  final DateTime productionDate;
  final String? originalNumber;
  final double workingPressure;
  final double designPressure;
  final String status; // Empty, Full, Error, InMaintenance, InTransit
  final int factoryId;
  final DateTime? lastFilled;
  final DateTime? lastInspected;
  final String? qrCode;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Optional nested objects
  final Factory? factory;
  final CylinderType? cylinderType;

  Cylinder({
    required this.id,
    required this.serialNumber,
    required this.size,
    required this.type,
    required this.gasType,
    this.importDate,
    required this.productionDate,
    this.originalNumber,
    required this.workingPressure,
    required this.designPressure,
    required this.status,
    required this.factoryId,
    this.lastFilled,
    this.lastInspected,
    this.qrCode,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.factory,
    this.cylinderType,
  });

  // Factory method to create a Cylinder from JSON
  factory Cylinder.fromJson(Map<String, dynamic> json) {
    return Cylinder(
      id: json['id'],
      serialNumber: json['serialNumber'],
      size: json['size'],
      type: json['type'] ?? 'Industrial', // Default to Industrial if not specified
      gasType: json['gasType'] ?? 'Oxygen', // Default to Oxygen if not specified
      importDate: json['importDate'] != null ? DateTime.parse(json['importDate']) : null,
      productionDate: json['productionDate'] != null ? DateTime.parse(json['productionDate']) : DateTime.now(),
      originalNumber: json['originalNumber'],
      workingPressure: json['workingPressure'] is int 
        ? json['workingPressure'].toDouble() 
        : (json['workingPressure'] ?? 0.0),
      designPressure: json['designPressure'] is int 
        ? json['designPressure'].toDouble() 
        : (json['designPressure'] ?? 0.0),
      status: json['status'] ?? 'Empty',
      factoryId: json['factoryId'] ?? 0,
      lastFilled: json['lastFilled'] != null ? DateTime.parse(json['lastFilled']) : null,
      lastInspected: json['lastInspected'] != null ? DateTime.parse(json['lastInspected']) : null,
      qrCode: json['qrCode'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      factory: json['factory'] != null ? Factory.fromJson(json['factory']) : null,
      cylinderType: json['cylinderType'] != null ? CylinderType.fromJson(json['cylinderType']) : null,
    );
  }

  // Convert Cylinder to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serialNumber': serialNumber,
      'size': size,
      'type': type,
      'gasType': gasType,
      'importDate': importDate?.toIso8601String(),
      'productionDate': productionDate.toIso8601String(),
      'originalNumber': originalNumber,
      'workingPressure': workingPressure,
      'designPressure': designPressure,
      'status': status,
      'factoryId': factoryId,
      'lastFilled': lastFilled?.toIso8601String(),
      'lastInspected': lastInspected?.toIso8601String(),
      'qrCode': qrCode,
      'notes': notes,
      // Nested objects are not included in the JSON for API requests
    };
  }

  // Create a copy of this Cylinder with the given fields replaced
  Cylinder copyWith({
    int? id,
    String? serialNumber,
    String? size,
    String? type,
    String? gasType,
    DateTime? importDate,
    DateTime? productionDate,
    String? originalNumber,
    double? workingPressure,
    double? designPressure,
    String? status,
    int? factoryId,
    DateTime? lastFilled,
    DateTime? lastInspected,
    String? qrCode,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Factory? factory,
    CylinderType? cylinderType,
  }) {
    return Cylinder(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      size: size ?? this.size,
      type: type ?? this.type,
      gasType: gasType ?? this.gasType,
      importDate: importDate ?? this.importDate,
      productionDate: productionDate ?? this.productionDate,
      originalNumber: originalNumber ?? this.originalNumber,
      workingPressure: workingPressure ?? this.workingPressure,
      designPressure: designPressure ?? this.designPressure,
      status: status ?? this.status,
      factoryId: factoryId ?? this.factoryId,
      lastFilled: lastFilled ?? this.lastFilled,
      lastInspected: lastInspected ?? this.lastInspected,
      qrCode: qrCode ?? this.qrCode,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      factory: factory ?? this.factory,
      cylinderType: cylinderType ?? this.cylinderType,
    );
  }

  // Create a Cylinder for new Cylinder form (for create operation)
  factory Cylinder.empty() {
    return Cylinder(
      id: 0,
      serialNumber: '',
      size: '',
      type: 'Industrial',
      gasType: 'Oxygen',
      productionDate: DateTime.now(),
      workingPressure: 0.0,
      designPressure: 0.0,
      status: 'Empty',
      factoryId: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Helper method to check if cylinder is fillable
  bool get isFillable => status == 'Empty';

  // Helper method to check if cylinder is available for sale
  bool get isAvailableForSale => status == 'Full';

  // Helper method to check if cylinder needs maintenance
  bool get needsMaintenance => status == 'Error';
}
