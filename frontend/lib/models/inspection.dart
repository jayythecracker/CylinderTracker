import 'package:cylinder_management/models/cylinder.dart';
import 'package:cylinder_management/models/user.dart';

class Inspection {
  final int id;
  final int cylinderId;
  final int inspectedById;
  final DateTime inspectionDate;
  final double pressureCheck;
  final bool visualCheck;
  final bool valveCheck;
  final String result; // Approved, Rejected
  final String? rejectionReason;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Optional nested objects
  final Cylinder? cylinder;
  final User? inspectedBy;

  Inspection({
    required this.id,
    required this.cylinderId,
    required this.inspectedById,
    required this.inspectionDate,
    required this.pressureCheck,
    required this.visualCheck,
    required this.valveCheck,
    required this.result,
    this.rejectionReason,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.cylinder,
    this.inspectedBy,
  });

  // Factory method to create an Inspection from JSON
  factory Inspection.fromJson(Map<String, dynamic> json) {
    return Inspection(
      id: json['id'],
      cylinderId: json['cylinderId'],
      inspectedById: json['inspectedById'],
      inspectionDate: DateTime.parse(json['inspectionDate']),
      pressureCheck: json['pressureCheck'] is int 
        ? json['pressureCheck'].toDouble() 
        : json['pressureCheck'],
      visualCheck: json['visualCheck'],
      valveCheck: json['valveCheck'],
      result: json['result'],
      rejectionReason: json['rejectionReason'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt']) 
        : DateTime.now(),
      cylinder: json['cylinder'] != null ? Cylinder.fromJson(json['cylinder']) : null,
      inspectedBy: json['inspectedBy'] != null ? User.fromJson(json['inspectedBy']) : null,
    );
  }

  // Convert Inspection to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cylinderId': cylinderId,
      'inspectedById': inspectedById,
      'inspectionDate': inspectionDate.toIso8601String(),
      'pressureCheck': pressureCheck,
      'visualCheck': visualCheck,
      'valveCheck': valveCheck,
      'result': result,
      'rejectionReason': rejectionReason,
      'notes': notes,
    };
  }

  // Create a copy of this Inspection with the given fields replaced
  Inspection copyWith({
    int? id,
    int? cylinderId,
    int? inspectedById,
    DateTime? inspectionDate,
    double? pressureCheck,
    bool? visualCheck,
    bool? valveCheck,
    String? result,
    String? rejectionReason,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Cylinder? cylinder,
    User? inspectedBy,
  }) {
    return Inspection(
      id: id ?? this.id,
      cylinderId: cylinderId ?? this.cylinderId,
      inspectedById: inspectedById ?? this.inspectedById,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      pressureCheck: pressureCheck ?? this.pressureCheck,
      visualCheck: visualCheck ?? this.visualCheck,
      valveCheck: valveCheck ?? this.valveCheck,
      result: result ?? this.result,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cylinder: cylinder ?? this.cylinder,
      inspectedBy: inspectedBy ?? this.inspectedBy,
    );
  }

  // Create an Inspection for new Inspection form (for create operation)
  factory Inspection.empty() {
    return Inspection(
      id: 0,
      cylinderId: 0,
      inspectedById: 0,
      inspectionDate: DateTime.now(),
      pressureCheck: 0.0,
      visualCheck: false,
      valveCheck: false,
      result: 'Approved',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Helper method to check if inspection was approved
  bool get isApproved => result == 'Approved';

  // Helper method to check if inspection was rejected
  bool get isRejected => result == 'Rejected';

  // Helper method to check if all checks passed
  bool get allChecksPassed => visualCheck && valveCheck;
}
