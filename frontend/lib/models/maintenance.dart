import 'cylinder.dart';
import 'user.dart';

enum MaintenanceStatus {
  Pending,
  InProgress,
  Completed,
  Unrepairable
}

class Maintenance {
  final int id;
  final DateTime maintenanceDate;
  final String issueDescription;
  final String? actionTaken;
  final MaintenanceStatus status;
  final double? cost;
  final DateTime? completionDate;
  final String? notes;
  final int cylinderId;
  final int technicianId;
  final Cylinder? cylinder;
  final User? technician;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Maintenance({
    required this.id,
    required this.maintenanceDate,
    required this.issueDescription,
    this.actionTaken,
    required this.status,
    this.cost,
    this.completionDate,
    this.notes,
    required this.cylinderId,
    required this.technicianId,
    this.cylinder,
    this.technician,
    this.createdAt,
    this.updatedAt,
  });

  factory Maintenance.fromJson(Map<String, dynamic> json) {
    return Maintenance(
      id: json['id'],
      maintenanceDate: DateTime.parse(json['maintenanceDate']),
      issueDescription: json['issueDescription'],
      actionTaken: json['actionTaken'],
      status: _parseMaintenanceStatus(json['status']),
      cost: json['cost']?.toDouble(),
      completionDate: json['completionDate'] != null ? DateTime.parse(json['completionDate']) : null,
      notes: json['notes'],
      cylinderId: json['cylinderId'],
      technicianId: json['technicianId'],
      cylinder: json['Cylinder'] != null ? Cylinder.fromJson(json['Cylinder']) : null,
      technician: json['technician'] != null ? User.fromJson(json['technician']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'maintenanceDate': maintenanceDate.toIso8601String(),
      'issueDescription': issueDescription,
      'actionTaken': actionTaken,
      'status': status.toString().split('.').last,
      'cost': cost,
      'completionDate': completionDate?.toIso8601String(),
      'notes': notes,
      'cylinderId': cylinderId,
      'technicianId': technicianId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static MaintenanceStatus _parseMaintenanceStatus(String status) {
    switch (status) {
      case 'InProgress':
        return MaintenanceStatus.InProgress;
      case 'Completed':
        return MaintenanceStatus.Completed;
      case 'Unrepairable':
        return MaintenanceStatus.Unrepairable;
      case 'Pending':
      default:
        return MaintenanceStatus.Pending;
    }
  }

  // Helper methods
  bool get isPending => status == MaintenanceStatus.Pending;
  bool get isInProgress => status == MaintenanceStatus.InProgress;
  bool get isCompleted => status == MaintenanceStatus.Completed;
  bool get isUnrepairable => status == MaintenanceStatus.Unrepairable;

  // Get time taken for completion
  Duration? get timeTaken {
    if (completionDate == null) return null;
    return completionDate!.difference(maintenanceDate);
  }

  // Get status color
  String get statusColor {
    switch (status) {
      case MaintenanceStatus.Pending:
        return "#FF9800"; // Orange
      case MaintenanceStatus.InProgress:
        return "#2196F3"; // Blue
      case MaintenanceStatus.Completed:
        return "#4CAF50"; // Green
      case MaintenanceStatus.Unrepairable:
        return "#F44336"; // Red
      default:
        return "#E0E0E0"; // Grey
    }
  }

  // Get status text
  String get statusText {
    switch (status) {
      case MaintenanceStatus.Pending:
        return "Pending";
      case MaintenanceStatus.InProgress:
        return "In Progress";
      case MaintenanceStatus.Completed:
        return "Completed";
      case MaintenanceStatus.Unrepairable:
        return "Unrepairable";
      default:
        return "Unknown";
    }
  }

  Maintenance copyWith({
    int? id,
    DateTime? maintenanceDate,
    String? issueDescription,
    String? actionTaken,
    MaintenanceStatus? status,
    double? cost,
    DateTime? completionDate,
    String? notes,
    int? cylinderId,
    int? technicianId,
    Cylinder? cylinder,
    User? technician,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Maintenance(
      id: id ?? this.id,
      maintenanceDate: maintenanceDate ?? this.maintenanceDate,
      issueDescription: issueDescription ?? this.issueDescription,
      actionTaken: actionTaken ?? this.actionTaken,
      status: status ?? this.status,
      cost: cost ?? this.cost,
      completionDate: completionDate ?? this.completionDate,
      notes: notes ?? this.notes,
      cylinderId: cylinderId ?? this.cylinderId,
      technicianId: technicianId ?? this.technicianId,
      cylinder: cylinder ?? this.cylinder,
      technician: technician ?? this.technician,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
