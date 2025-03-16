import 'user.dart';
import 'cylinder.dart';

class Inspection {
  final int id;
  final DateTime inspectionDate;
  final int cylinderId;
  final int inspectedById;
  final double pressureReading;
  final bool visualInspection;
  final String result;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Cylinder? cylinder;
  final User? inspectedBy;

  Inspection({
    required this.id,
    required this.inspectionDate,
    required this.cylinderId,
    required this.inspectedById,
    required this.pressureReading,
    required this.visualInspection,
    required this.result,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.cylinder,
    this.inspectedBy,
  });

  factory Inspection.fromJson(Map<String, dynamic> json) {
    return Inspection(
      id: json['id'],
      inspectionDate: DateTime.parse(json['inspectionDate']),
      cylinderId: json['cylinderId'],
      inspectedById: json['inspectedById'],
      pressureReading: json['pressureReading'].toDouble(),
      visualInspection: json['visualInspection'],
      result: json['result'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      cylinder: json['Cylinder'] != null ? Cylinder.fromJson(json['Cylinder']) : null,
      inspectedBy: json['InspectedBy'] != null ? User.fromJson(json['InspectedBy']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inspectionDate': inspectionDate.toIso8601String(),
      'cylinderId': cylinderId,
      'inspectedById': inspectedById,
      'pressureReading': pressureReading,
      'visualInspection': visualInspection,
      'result': result,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // For creating a new inspection
  Map<String, dynamic> toCreateJson() {
    return {
      'cylinderId': cylinderId,
      'pressureReading': pressureReading,
      'visualInspection': visualInspection,
      'result': result,
      'notes': notes,
    };
  }

  // For batch inspection
  static Map<String, dynamic> toBatchInspectJson({
    required List<int> cylinderIds,
    required String result,
    String? notes,
  }) {
    return {
      'cylinderIds': cylinderIds,
      'result': result,
      'notes': notes,
    };
  }

  Inspection copyWith({
    int? id,
    DateTime? inspectionDate,
    int? cylinderId,
    int? inspectedById,
    double? pressureReading,
    bool? visualInspection,
    String? result,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Cylinder? cylinder,
    User? inspectedBy,
  }) {
    return Inspection(
      id: id ?? this.id,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      cylinderId: cylinderId ?? this.cylinderId,
      inspectedById: inspectedById ?? this.inspectedById,
      pressureReading: pressureReading ?? this.pressureReading,
      visualInspection: visualInspection ?? this.visualInspection,
      result: result ?? this.result,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cylinder: cylinder ?? this.cylinder,
      inspectedBy: inspectedBy ?? this.inspectedBy,
    );
  }
}
