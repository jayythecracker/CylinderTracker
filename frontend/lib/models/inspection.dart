class Inspection {
  final int id;
  final int cylinderId;
  final DateTime inspectionDate;
  final int inspectedById;
  final bool visualInspection;
  final double? pressureReading;
  final String result; // Approved, Rejected
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Inspection({
    required this.id,
    required this.cylinderId,
    required this.inspectionDate,
    required this.inspectedById,
    required this.visualInspection,
    this.pressureReading,
    required this.result,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory method to create an Inspection from JSON
  factory Inspection.fromJson(Map<String, dynamic> json) {
    return Inspection(
      id: json['id'],
      cylinderId: json['cylinderId'],
      inspectionDate: json['inspectionDate'] != null 
          ? DateTime.parse(json['inspectionDate']) 
          : DateTime.now(),
      inspectedById: json['inspectedById'],
      visualInspection: json['visualInspection'] ?? false,
      pressureReading: json['pressureReading'] != null
          ? (json['pressureReading'] is int
              ? json['pressureReading'].toDouble()
              : json['pressureReading'])
          : null,
      result: json['result'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  // Convert Inspection to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cylinderId': cylinderId,
      'inspectionDate': inspectionDate.toIso8601String(),
      'inspectedById': inspectedById,
      'visualInspection': visualInspection,
      'pressureReading': pressureReading,
      'result': result,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy of this Inspection with the given fields replaced
  Inspection copyWith({
    int? id,
    int? cylinderId,
    DateTime? inspectionDate,
    int? inspectedById,
    bool? visualInspection,
    double? pressureReading,
    String? result,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Inspection(
      id: id ?? this.id,
      cylinderId: cylinderId ?? this.cylinderId,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      inspectedById: inspectedById ?? this.inspectedById,
      visualInspection: visualInspection ?? this.visualInspection,
      pressureReading: pressureReading ?? this.pressureReading,
      result: result ?? this.result,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to check if the inspection was approved
  bool get isApproved => result == 'Approved';

  // Helper method to check if the inspection was rejected
  bool get isRejected => result == 'Rejected';

  // Empty inspection for form initialization
  factory Inspection.empty() {
    return Inspection(
      id: 0,
      cylinderId: 0,
      inspectionDate: DateTime.now(),
      inspectedById: 0,
      visualInspection: false,
      result: 'Approved',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}