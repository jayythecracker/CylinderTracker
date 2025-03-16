import 'customer.dart';
import 'truck.dart';
import 'user.dart';
import 'cylinder.dart';

enum DeliveryType {
  Truck,
  CustomerPickup
}

enum DeliveryStatus {
  Pending,
  InTransit,
  Delivered,
  Cancelled
}

class Delivery {
  final int id;
  final DateTime deliveryDate;
  final DeliveryType deliveryType;
  final DeliveryStatus status;
  final String? signature;
  final String? receiptNumber;
  final double? totalAmount;
  final String? notes;
  final int customerId;
  final int deliveryPersonId;
  final int? truckId;
  final Customer? customer;
  final User? deliveryPerson;
  final Truck? truck;
  final List<Cylinder>? cylinders;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Delivery({
    required this.id,
    required this.deliveryDate,
    required this.deliveryType,
    required this.status,
    this.signature,
    this.receiptNumber,
    this.totalAmount,
    this.notes,
    required this.customerId,
    required this.deliveryPersonId,
    this.truckId,
    this.customer,
    this.deliveryPerson,
    this.truck,
    this.cylinders,
    this.createdAt,
    this.updatedAt,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    List<Cylinder>? cylinderList;
    if (json['Cylinders'] != null) {
      cylinderList = (json['Cylinders'] as List)
          .map((cylinderJson) => Cylinder.fromJson(cylinderJson))
          .toList();
    }

    return Delivery(
      id: json['id'],
      deliveryDate: DateTime.parse(json['deliveryDate']),
      deliveryType: json['deliveryType'] == 'Truck' ? DeliveryType.Truck : DeliveryType.CustomerPickup,
      status: _parseDeliveryStatus(json['status']),
      signature: json['signature'],
      receiptNumber: json['receiptNumber'],
      totalAmount: json['totalAmount']?.toDouble(),
      notes: json['notes'],
      customerId: json['customerId'],
      deliveryPersonId: json['deliveryPersonId'],
      truckId: json['truckId'],
      customer: json['Customer'] != null ? Customer.fromJson(json['Customer']) : null,
      deliveryPerson: json['deliveryPerson'] != null ? User.fromJson(json['deliveryPerson']) : null,
      truck: json['Truck'] != null ? Truck.fromJson(json['Truck']) : null,
      cylinders: cylinderList,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deliveryDate': deliveryDate.toIso8601String(),
      'deliveryType': deliveryType == DeliveryType.Truck ? 'Truck' : 'CustomerPickup',
      'status': status.toString().split('.').last,
      'signature': signature,
      'receiptNumber': receiptNumber,
      'totalAmount': totalAmount,
      'notes': notes,
      'customerId': customerId,
      'deliveryPersonId': deliveryPersonId,
      'truckId': truckId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static DeliveryStatus _parseDeliveryStatus(String status) {
    switch (status) {
      case 'InTransit':
        return DeliveryStatus.InTransit;
      case 'Delivered':
        return DeliveryStatus.Delivered;
      case 'Cancelled':
        return DeliveryStatus.Cancelled;
      case 'Pending':
      default:
        return DeliveryStatus.Pending;
    }
  }

  // Helper methods
  bool get isPending => status == DeliveryStatus.Pending;
  bool get isInTransit => status == DeliveryStatus.InTransit;
  bool get isDelivered => status == DeliveryStatus.Delivered;
  bool get isCancelled => status == DeliveryStatus.Cancelled;
  bool get isByTruck => deliveryType == DeliveryType.Truck;
  bool get isCustomerPickup => deliveryType == DeliveryType.CustomerPickup;

  // Get status color
  String get statusColor {
    switch (status) {
      case DeliveryStatus.Pending:
        return "#FF9800"; // Orange
      case DeliveryStatus.InTransit:
        return "#2196F3"; // Blue
      case DeliveryStatus.Delivered:
        return "#4CAF50"; // Green
      case DeliveryStatus.Cancelled:
        return "#F44336"; // Red
      default:
        return "#E0E0E0"; // Grey
    }
  }

  // Get status text
  String get statusText {
    switch (status) {
      case DeliveryStatus.Pending:
        return "Pending";
      case DeliveryStatus.InTransit:
        return "In Transit";
      case DeliveryStatus.Delivered:
        return "Delivered";
      case DeliveryStatus.Cancelled:
        return "Cancelled";
      default:
        return "Unknown";
    }
  }

  // Get delivery type text
  String get deliveryTypeText {
    return deliveryType == DeliveryType.Truck ? 'By Truck' : 'Customer Pickup';
  }

  Delivery copyWith({
    int? id,
    DateTime? deliveryDate,
    DeliveryType? deliveryType,
    DeliveryStatus? status,
    String? signature,
    String? receiptNumber,
    double? totalAmount,
    String? notes,
    int? customerId,
    int? deliveryPersonId,
    int? truckId,
    Customer? customer,
    User? deliveryPerson,
    Truck? truck,
    List<Cylinder>? cylinders,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Delivery(
      id: id ?? this.id,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryType: deliveryType ?? this.deliveryType,
      status: status ?? this.status,
      signature: signature ?? this.signature,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      customerId: customerId ?? this.customerId,
      deliveryPersonId: deliveryPersonId ?? this.deliveryPersonId,
      truckId: truckId ?? this.truckId,
      customer: customer ?? this.customer,
      deliveryPerson: deliveryPerson ?? this.deliveryPerson,
      truck: truck ?? this.truck,
      cylinders: cylinders ?? this.cylinders,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
