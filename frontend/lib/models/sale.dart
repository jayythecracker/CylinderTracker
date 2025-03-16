import 'package:cylinder_management/models/customer.dart';
import 'package:cylinder_management/models/truck.dart';

class Sale {
  final int id;
  final int customerId;
  final String invoiceNumber;
  final DateTime saleDate;
  final double totalAmount;
  final double paidAmount;
  final String status;
  final String paymentStatus;
  final String deliveryStatus;
  final String deliveryMethod;
  final bool isPickup;
  final int cylinderCount;
  final Truck? truck;
  final DateTime? deliveryDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional nested objects
  final Customer? customer;

  Sale({
    required this.id,
    required this.customerId,
    required this.invoiceNumber,
    required this.saleDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.status,
    required this.paymentStatus,
    required this.deliveryStatus,
    required this.deliveryMethod,
    required this.isPickup,
    required this.cylinderCount,
    this.truck,
    this.deliveryDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.customer,
  });

  // Factory method to create a Sale from JSON
  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'],
      customerId: json['customerId'],
      invoiceNumber: json['invoiceNumber'] ?? '',
      saleDate: json['saleDate'] != null 
          ? DateTime.parse(json['saleDate']) 
          : DateTime.now(),
      totalAmount: json['totalAmount'] is int 
          ? json['totalAmount'].toDouble() 
          : json['totalAmount'],
      paidAmount: json['paidAmount'] is int 
          ? json['paidAmount'].toDouble() 
          : json['paidAmount'],
      status: json['status'],
      paymentStatus: json['paymentStatus'],
      deliveryStatus: json['deliveryStatus'] ?? 'Pending',
      deliveryMethod: json['deliveryMethod'] ?? 'Delivery',
      isPickup: json['isPickup'] ?? false,
      cylinderCount: json['cylinderCount'] ?? 0,
      truck: json['truck'] != null ? Truck.fromJson(json['truck']) : null,
      deliveryDate: json['deliveryDate'] != null 
          ? DateTime.parse(json['deliveryDate']) 
          : null,
      notes: json['notes'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      customer: json['customer'] != null 
          ? Customer.fromJson(json['customer']) 
          : null,
    );
  }

  // Convert Sale to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'invoiceNumber': invoiceNumber,
      'saleDate': saleDate.toIso8601String(),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'status': status,
      'paymentStatus': paymentStatus,
      'deliveryStatus': deliveryStatus,
      'deliveryMethod': deliveryMethod,
      'isPickup': isPickup,
      'cylinderCount': cylinderCount,
      'truck': truck?.toJson(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'notes': notes,
    };
  }

  // Create a copy of this Sale with the given fields replaced
  Sale copyWith({
    int? id,
    int? customerId,
    String? invoiceNumber,
    DateTime? saleDate,
    double? totalAmount,
    double? paidAmount,
    String? status,
    String? paymentStatus,
    String? deliveryStatus,
    String? deliveryMethod,
    bool? isPickup,
    int? cylinderCount,
    Truck? truck,
    DateTime? deliveryDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Customer? customer,
  }) {
    return Sale(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      saleDate: saleDate ?? this.saleDate,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      isPickup: isPickup ?? this.isPickup,
      cylinderCount: cylinderCount ?? this.cylinderCount,
      truck: truck ?? this.truck,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customer: customer ?? this.customer,
    );
  }

  // Empty sale for form initialization
  factory Sale.empty() {
    return Sale(
      id: 0,
      customerId: 0,
      invoiceNumber: '',
      saleDate: DateTime.now(),
      totalAmount: 0.0,
      paidAmount: 0.0,
      status: 'Pending',
      paymentStatus: 'Unpaid',
      deliveryStatus: 'Pending',
      deliveryMethod: 'Delivery',
      isPickup: false,
      cylinderCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Helper methods
  bool get isPending => status == 'Pending';
  bool get isDelivered => status == 'Delivered';
  bool get isCompleted => status == 'Completed';
  bool get isCancelled => status == 'Cancelled';

  bool get isUnpaid => paymentStatus == 'Unpaid';
  bool get isPartiallyPaid => paymentStatus == 'Partially Paid';
  bool get isPaid => paymentStatus == 'Paid';

  double get remainingAmount => totalAmount - paidAmount;
}