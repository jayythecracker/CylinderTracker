import 'package:flutter/material.dart';
import 'user.dart';

// Truck model
class Truck {
  final int id;
  final String licenseNumber;
  final String type;
  final String owner;
  final int capacity;
  final TruckStatus status;
  final DateTime? lastMaintenanceDate;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Truck({
    required this.id,
    required this.licenseNumber,
    required this.type,
    required this.owner,
    required this.capacity,
    required this.status,
    this.lastMaintenanceDate,
    required this.isActive,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create Truck from JSON
  factory Truck.fromJson(Map<String, dynamic> json) {
    return Truck(
      id: json['id'],
      licenseNumber: json['licenseNumber'],
      type: json['type'],
      owner: json['owner'],
      capacity: json['capacity'],
      status: _parseTruckStatus(json['status']),
      lastMaintenanceDate: json['lastMaintenanceDate'] != null
          ? DateTime.parse(json['lastMaintenanceDate'])
          : null,
      isActive: json['isActive'] ?? true,
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Convert Truck to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'licenseNumber': licenseNumber,
      'type': type,
      'owner': owner,
      'capacity': capacity,
      'status': status.name,
      'lastMaintenanceDate': lastMaintenanceDate?.toIso8601String(),
      'isActive': isActive,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy of the truck with updated fields
  Truck copyWith({
    int? id,
    String? licenseNumber,
    String? type,
    String? owner,
    int? capacity,
    TruckStatus? status,
    DateTime? lastMaintenanceDate,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Truck(
      id: id ?? this.id,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      type: type ?? this.type,
      owner: owner ?? this.owner,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Parse truck status from string
  static TruckStatus _parseTruckStatus(String status) {
    switch (status) {
      case 'available':
        return TruckStatus.available;
      case 'in_delivery':
        return TruckStatus.inDelivery;
      case 'maintenance':
        return TruckStatus.maintenance;
      default:
        return TruckStatus.available;
    }
  }
}

// Enum for truck statuses
enum TruckStatus {
  available,
  inDelivery,
  maintenance
}

// Extension to get string representation of the status
extension TruckStatusExtension on TruckStatus {
  String get name {
    switch (this) {
      case TruckStatus.available:
        return 'available';
      case TruckStatus.inDelivery:
        return 'in_delivery';
      case TruckStatus.maintenance:
        return 'maintenance';
    }
  }

  String get displayName {
    switch (this) {
      case TruckStatus.available:
        return 'Available';
      case TruckStatus.inDelivery:
        return 'In Delivery';
      case TruckStatus.maintenance:
        return 'Maintenance';
    }
  }

  // Get color associated with the status
  Color get color {
    switch (this) {
      case TruckStatus.available:
        return Colors.green;
      case TruckStatus.inDelivery:
        return Colors.blue;
      case TruckStatus.maintenance:
        return Colors.orange;
    }
  }
}

// DeliveryTrip model
class DeliveryTrip {
  final int id;
  final int truckId;
  final Truck? truck; // For displaying truck info
  final int driverId;
  final User? driver; // For displaying driver info
  final DateTime departureTime;
  final DateTime? returnTime;
  final DeliveryTripStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DeliveryTrip({
    required this.id,
    required this.truckId,
    this.truck,
    required this.driverId,
    this.driver,
    required this.departureTime,
    this.returnTime,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create DeliveryTrip from JSON
  factory DeliveryTrip.fromJson(Map<String, dynamic> json) {
    // Handle the case where related entities are included in the response
    final truckJson = json['truck'];
    final truck = truckJson != null ? Truck.fromJson(truckJson) : null;

    final driverJson = json['driver'];
    final driver = driverJson != null ? User.fromJson(driverJson) : null;

    return DeliveryTrip(
      id: json['id'],
      truckId: json['truckId'],
      truck: truck,
      driverId: json['driverId'],
      driver: driver,
      departureTime: DateTime.parse(json['departureTime']),
      returnTime: json['returnTime'] != null ? DateTime.parse(json['returnTime']) : null,
      status: _parseDeliveryTripStatus(json['status']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Convert DeliveryTrip to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'truckId': truckId,
      'driverId': driverId,
      'departureTime': departureTime.toIso8601String(),
      'returnTime': returnTime?.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Parse delivery trip status from string
  static DeliveryTripStatus _parseDeliveryTripStatus(String status) {
    switch (status) {
      case 'planned':
        return DeliveryTripStatus.planned;
      case 'in_progress':
        return DeliveryTripStatus.inProgress;
      case 'completed':
        return DeliveryTripStatus.completed;
      case 'cancelled':
        return DeliveryTripStatus.cancelled;
      default:
        return DeliveryTripStatus.planned;
    }
  }
}

// Enum for delivery trip statuses
enum DeliveryTripStatus {
  planned,
  inProgress,
  completed,
  cancelled
}

// Extension to get string representation of the status
extension DeliveryTripStatusExtension on DeliveryTripStatus {
  String get name {
    switch (this) {
      case DeliveryTripStatus.planned:
        return 'planned';
      case DeliveryTripStatus.inProgress:
        return 'in_progress';
      case DeliveryTripStatus.completed:
        return 'completed';
      case DeliveryTripStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case DeliveryTripStatus.planned:
        return 'Planned';
      case DeliveryTripStatus.inProgress:
        return 'In Progress';
      case DeliveryTripStatus.completed:
        return 'Completed';
      case DeliveryTripStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Get color associated with the status
  Color get color {
    switch (this) {
      case DeliveryTripStatus.planned:
        return Colors.blue;
      case DeliveryTripStatus.inProgress:
        return Colors.orange;
      case DeliveryTripStatus.completed:
        return Colors.green;
      case DeliveryTripStatus.cancelled:
        return Colors.red;
    }
  }
}
