import 'package:flutter/material.dart';
import 'customer.dart';
import 'user.dart';
import 'cylinder.dart';
import 'truck.dart';

// Sale model
class Sale {
  final int id;
  final String invoiceNumber;
  final int customerId;
  final Customer? customer; // For displaying customer info
  final int sellerId;
  final User? seller; // For displaying seller info
  final DateTime saleDate;
  final double totalAmount;
  final double paidAmount;
  final DeliveryType deliveryType;
  final int? deliveryTripId;
  final DeliveryTrip? deliveryTrip; // For displaying delivery trip info
  final SaleStatus status;
  final bool customerSignature;
  final DateTime? deliveryDate;
  final String? notes;
  final List<SaleItem> items; // For displaying sale items
  final DateTime createdAt;
  final DateTime updatedAt;

  const Sale({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    this.customer,
    required this.sellerId,
    this.seller,
    required this.saleDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.deliveryType,
    this.deliveryTripId,
    this.deliveryTrip,
    required this.status,
    required this.customerSignature,
    this.deliveryDate,
    this.notes,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create Sale from JSON
  factory Sale.fromJson(Map<String, dynamic> json) {
    // Handle the case where related entities are included in the response
    final customerJson = json['customer'];
    final customer = customerJson != null ? Customer.fromJson(customerJson) : null;

    final sellerJson = json['seller'];
    final seller = sellerJson != null ? User.fromJson(sellerJson) : null;

    final deliveryTripJson = json['deliveryTrip'];
    final deliveryTrip = deliveryTripJson != null ? DeliveryTrip.fromJson(deliveryTripJson) : null;

    final itemsJson = json['items'] as List<dynamic>?;
    final items = itemsJson != null
        ? itemsJson.map((i) => SaleItem.fromJson(i)).toList()
        : <SaleItem>[];

    return Sale(
      id: json['id'],
      invoiceNumber: json['invoiceNumber'],
      customerId: json['customerId'],
      customer: customer,
      sellerId: json['sellerId'],
      seller: seller,
      saleDate: DateTime.parse(json['saleDate']),
      totalAmount: json['totalAmount'] is int
          ? json['totalAmount'].toDouble()
          : json['totalAmount'],
      paidAmount: json['paidAmount'] is int
          ? json['paidAmount'].toDouble()
          : json['paidAmount'],
      deliveryType: _parseDeliveryType(json['deliveryType']),
      deliveryTripId: json['deliveryTripId'],
      deliveryTrip: deliveryTrip,
      status: _parseSaleStatus(json['status']),
      customerSignature: json['customerSignature'] ?? false,
      deliveryDate: json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate']) : null,
      notes: json['notes'],
      items: items,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Convert Sale to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'sellerId': sellerId,
      'saleDate': saleDate.toIso8601String(),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'deliveryType': deliveryType.name,
      'deliveryTripId': deliveryTripId,
      'status': status.name,
      'customerSignature': customerSignature,
      'deliveryDate': deliveryDate?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy of the sale with updated fields
  Sale copyWith({
    int? id,
    String? invoiceNumber,
    int? customerId,
    Customer? customer,
    int? sellerId,
    User? seller,
    DateTime? saleDate,
    double? totalAmount,
    double? paidAmount,
    DeliveryType? deliveryType,
    int? deliveryTripId,
    DeliveryTrip? deliveryTrip,
    SaleStatus? status,
    bool? customerSignature,
    DateTime? deliveryDate,
    String? notes,
    List<SaleItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Sale(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customer: customer ?? this.customer,
      sellerId: sellerId ?? this.sellerId,
      seller: seller ?? this.seller,
      saleDate: saleDate ?? this.saleDate,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      deliveryType: deliveryType ?? this.deliveryType,
      deliveryTripId: deliveryTripId ?? this.deliveryTripId,
      deliveryTrip: deliveryTrip ?? this.deliveryTrip,
      status: status ?? this.status,
      customerSignature: customerSignature ?? this.customerSignature,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Parse delivery type from string
  static DeliveryType _parseDeliveryType(String type) {
    switch (type) {
      case 'delivery':
        return DeliveryType.delivery;
      case 'pickup':
        return DeliveryType.pickup;
      default:
        return DeliveryType.delivery;
    }
  }

  // Parse sale status from string
  static SaleStatus _parseSaleStatus(String status) {
    switch (status) {
      case 'pending':
        return SaleStatus.pending;
      case 'processing':
        return SaleStatus.processing;
      case 'delivered':
        return SaleStatus.delivered;
      case 'picked_up':
        return SaleStatus.pickedUp;
      case 'cancelled':
        return SaleStatus.cancelled;
      default:
        return SaleStatus.pending;
    }
  }
}

// SaleItem model
class SaleItem {
  final int id;
  final int saleId;
  final int cylinderId;
  final Cylinder? cylinder; // For displaying cylinder info
  final double price;
  final bool isReturn;
  final SaleItemStatus status;

  const SaleItem({
    required this.id,
    required this.saleId,
    required this.cylinderId,
    this.cylinder,
    required this.price,
    required this.isReturn,
    required this.status,
  });

  // Factory constructor to create SaleItem from JSON
  factory SaleItem.fromJson(Map<String, dynamic> json) {
    // Handle the case where cylinder is included in the response
    final cylinderJson = json['cylinder'];
    final cylinder = cylinderJson != null ? Cylinder.fromJson(cylinderJson) : null;

    return SaleItem(
      id: json['id'],
      saleId: json['saleId'],
      cylinderId: json['cylinderId'],
      cylinder: cylinder,
      price: json['price'] is int ? json['price'].toDouble() : json['price'],
      isReturn: json['isReturn'] ?? false,
      status: _parseSaleItemStatus(json['status']),
    );
  }

  // Convert SaleItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saleId': saleId,
      'cylinderId': cylinderId,
      'price': price,
      'isReturn': isReturn,
      'status': status.name,
    };
  }

  // Parse sale item status from string
  static SaleItemStatus _parseSaleItemStatus(String status) {
    switch (status) {
      case 'pending':
        return SaleItemStatus.pending;
      case 'delivered':
        return SaleItemStatus.delivered;
      case 'returned':
        return SaleItemStatus.returned;
      default:
        return SaleItemStatus.pending;
    }
  }
}

// Enum for delivery types
enum DeliveryType {
  delivery,
  pickup
}

// Extension to get string representation of the delivery type
extension DeliveryTypeExtension on DeliveryType {
  String get name {
    switch (this) {
      case DeliveryType.delivery:
        return 'delivery';
      case DeliveryType.pickup:
        return 'pickup';
    }
  }

  String get displayName {
    switch (this) {
      case DeliveryType.delivery:
        return 'Delivery';
      case DeliveryType.pickup:
        return 'Pickup';
    }
  }
}

// Enum for sale statuses
enum SaleStatus {
  pending,
  processing,
  delivered,
  pickedUp,
  cancelled
}

// Extension to get string representation of the sale status
extension SaleStatusExtension on SaleStatus {
  String get name {
    switch (this) {
      case SaleStatus.pending:
        return 'pending';
      case SaleStatus.processing:
        return 'processing';
      case SaleStatus.delivered:
        return 'delivered';
      case SaleStatus.pickedUp:
        return 'picked_up';
      case SaleStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case SaleStatus.pending:
        return 'Pending';
      case SaleStatus.processing:
        return 'Processing';
      case SaleStatus.delivered:
        return 'Delivered';
      case SaleStatus.pickedUp:
        return 'Picked Up';
      case SaleStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Get color associated with the status
  Color get color {
    switch (this) {
      case SaleStatus.pending:
        return Colors.blue;
      case SaleStatus.processing:
        return Colors.orange;
      case SaleStatus.delivered:
        return Colors.green;
      case SaleStatus.pickedUp:
        return Colors.green;
      case SaleStatus.cancelled:
        return Colors.red;
    }
  }
}

// Enum for sale item statuses
enum SaleItemStatus {
  pending,
  delivered,
  returned
}

// Extension to get string representation of the sale item status
extension SaleItemStatusExtension on SaleItemStatus {
  String get name {
    switch (this) {
      case SaleItemStatus.pending:
        return 'pending';
      case SaleItemStatus.delivered:
        return 'delivered';
      case SaleItemStatus.returned:
        return 'returned';
    }
  }

  String get displayName {
    switch (this) {
      case SaleItemStatus.pending:
        return 'Pending';
      case SaleItemStatus.delivered:
        return 'Delivered';
      case SaleItemStatus.returned:
        return 'Returned';
    }
  }

  // Get color associated with the status
  Color get color {
    switch (this) {
      case SaleItemStatus.pending:
        return Colors.blue;
      case SaleItemStatus.delivered:
        return Colors.green;
      case SaleItemStatus.returned:
        return Colors.orange;
    }
  }
}
