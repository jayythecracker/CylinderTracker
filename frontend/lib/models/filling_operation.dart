class FillingOperation {
  final int id;
  final int cylinderId;
  final int filledById;
  final DateTime fillingDate;
  final String gasType;
  final double initialPressure;
  final double? finalPressure;
  final String status; // InProgress, Completed, Cancelled
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  FillingOperation({
    required this.id,
    required this.cylinderId,
    required this.filledById,
    required this.fillingDate,
    required this.gasType,
    required this.initialPressure,
    this.finalPressure,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory method to create a FillingOperation from JSON
  factory FillingOperation.fromJson(Map<String, dynamic> json) {
    return FillingOperation(
      id: json['id'],
      cylinderId: json['cylinderId'],
      filledById: json['filledById'],
      fillingDate: json['fillingDate'] != null 
          ? DateTime.parse(json['fillingDate']) 
          : DateTime.now(),
      gasType: json['gasType'],
      initialPressure: json['initialPressure'] is int 
          ? json['initialPressure'].toDouble() 
          : json['initialPressure'],
      finalPressure: json['finalPressure'] != null
          ? (json['finalPressure'] is int
              ? json['finalPressure'].toDouble()
              : json['finalPressure'])
          : null,
      status: json['status'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  // Convert FillingOperation to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cylinderId': cylinderId,
      'filledById': filledById,
      'fillingDate': fillingDate.toIso8601String(),
      'gasType': gasType,
      'initialPressure': initialPressure,
      'finalPressure': finalPressure,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy of this FillingOperation with the given fields replaced
  FillingOperation copyWith({
    int? id,
    int? cylinderId,
    int? filledById,
    DateTime? fillingDate,
    String? gasType,
    double? initialPressure,
    double? finalPressure,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FillingOperation(
      id: id ?? this.id,
      cylinderId: cylinderId ?? this.cylinderId,
      filledById: filledById ?? this.filledById,
      fillingDate: fillingDate ?? this.fillingDate,
      gasType: gasType ?? this.gasType,
      initialPressure: initialPressure ?? this.initialPressure,
      finalPressure: finalPressure ?? this.finalPressure,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to check if the filling operation is in progress
  bool get isInProgress => status == 'InProgress';

  // Helper method to check if the filling operation is completed
  bool get isCompleted => status == 'Completed';
}