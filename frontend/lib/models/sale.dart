import 'package:cylinder_management/models/customer.dart';

class Sale {
  final int id;
  final int customerId;
  final DateTime saleDate;
  final double totalAmount;
  final double paidAmount;
  final String status; // Pending, Delivered, Completed, Cancelled
  final String paymentStatus; // Unpaid, Partially Paid, Paid
  final String deliveryType; // Pickup, Delivery
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Optional nested objects
  final Customer? customer;

  Sale({
    required this.id,
    required this.customerId,
    required this.saleDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.status,
    required this.paymentStatus,
    required this.deliveryType,
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
      deliveryType: json['deliveryType'],
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
      'saleDate': saleDate.toIso8601String(),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'status': status,
      'paymentStatus': paymentStatus,
      'deliveryType': deliveryType,
      'notes': notes,
      // Nested customer is not included in JSON for API requests
    };
  }

  // Create a copy of this Sale with the given fields replaced
  Sale copyWith({
    int? id,
    int? customerId,
    DateTime? saleDate,
    double? totalAmount,
    double? paidAmount,
    String? status,
    String? paymentStatus,
    String? deliveryType,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Customer? customer,
  }) {
    return Sale(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      saleDate: saleDate ?? this.saleDate,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryType: deliveryType ?? this.deliveryType,
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
      saleDate: DateTime.now(),
      totalAmount: 0.0,
      paidAmount: 0.0,
      status: 'Pending',
      paymentStatus: 'Unpaid',
      deliveryType: 'Delivery',
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

  double get balanceDue => totalAmount - paidAmount;
}