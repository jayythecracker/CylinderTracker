import 'factory.dart';

class Cylinder {
  final int id;
  final String serialNumber;
  final String qrCode;
  final String size;
  final DateTime? importDate;
  final DateTime productionDate;
  final String? originalNumber;
  final double workingPressure;
  final double designPressure;
  final String gasType;
  final String status;
  final DateTime? lastFilledDate;
  final DateTime? lastInspectionDate;
  final int factoryId;
  final int? currentCustomerId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Factory? factory;

  Cylinder({
    required this.id,
    required this.serialNumber,
    required this.qrCode,
    required this.size,
    this.importDate,
    required this.productionDate,
    this.originalNumber,
    required this.workingPressure,
    required this.designPressure,
    required this.gasType,
    required this.status,
    this.lastFilledDate,
    this.lastInspectionDate,
    required this.factoryId,
    this.currentCustomerId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.factory,
  });

  factory Cylinder.fromJson(Map<String, dynamic> json) {
    return Cylinder(
      id: json['id'],
      serialNumber: json['serialNumber'],
      qrCode: json['qrCode'],
      size: json['size'],
      importDate: json['importDate'] != null ? DateTime.parse(json['importDate']) : null,
      productionDate: DateTime.parse(json['productionDate']),
      originalNumber: json['originalNumber'],
      workingPressure: json['workingPressure'].toDouble(),
      designPressure: json['designPressure'].toDouble(),
      gasType: json['gasType'],
      status: json['status'],
      lastFilledDate: json['lastFilledDate'] != null ? DateTime.parse(json['lastFilledDate']) : null,
      lastInspectionDate: json['lastInspectionDate'] != null ? DateTime.parse(json['lastInspectionDate']) : null,
      factoryId: json['factoryId'],
      currentCustomerId: json['currentCustomerId'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      factory: json['Factory'] != null ? Factory.fromJson(json['Factory']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serialNumber': serialNumber,
      'qrCode': qrCode,
      'size': size,
      'importDate': importDate?.toIso8601String(),
      'productionDate': productionDate.toIso8601String(),
      'originalNumber': originalNumber,
      'workingPressure': workingPressure,
      'designPressure': designPressure,
      'gasType': gasType,
      'status': status,
      'lastFilledDate': lastFilledDate?.toIso8601String(),
      'lastInspectionDate': lastInspectionDate?.toIso8601String(),
      'factoryId': factoryId,
      'currentCustomerId': currentCustomerId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // For creating a new cylinder
  Map<String, dynamic> toCreateJson() {
    return {
      'serialNumber': serialNumber,
      'size': size,
      'importDate': importDate?.toIso8601String(),
      'productionDate': productionDate.toIso8601String(),
      'originalNumber': originalNumber,
      'workingPressure': workingPressure,
      'designPressure': designPressure,
      'gasType': gasType,
      'factoryId': factoryId,
    };
  }

  Cylinder copyWith({
    int? id,
    String? serialNumber,
    String? qrCode,
    String? size,
    DateTime? importDate,
    DateTime? productionDate,
    String? originalNumber,
    double? workingPressure,
    double? designPressure,
    String? gasType,
    String? status,
    DateTime? lastFilledDate,
    DateTime? lastInspectionDate,
    int? factoryId,
    int? currentCustomerId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Factory? factory,
  }) {
    return Cylinder(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      qrCode: qrCode ?? this.qrCode,
      size: size ?? this.size,
      importDate: importDate ?? this.importDate,
      productionDate: productionDate ?? this.productionDate,
      originalNumber: originalNumber ?? this.originalNumber,
      workingPressure: workingPressure ?? this.workingPressure,
      designPressure: designPressure ?? this.designPressure,
      gasType: gasType ?? this.gasType,
      status: status ?? this.status,
      lastFilledDate: lastFilledDate ?? this.lastFilledDate,
      lastInspectionDate: lastInspectionDate ?? this.lastInspectionDate,
      factoryId: factoryId ?? this.factoryId,
      currentCustomerId: currentCustomerId ?? this.currentCustomerId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      factory: factory ?? this.factory,
    );
  }
}
