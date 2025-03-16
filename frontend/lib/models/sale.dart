import 'package:cylinder_management/models/customer.dart';
import 'package:cylinder_management/models/cylinder.dart';
import 'package:cylinder_management/models/truck.dart';
import 'package:cylinder_management/models/user.dart';

class SaleCylinder {
  final int id;
  final int quantity;
  final Cylinder? cylinder;

  SaleCylinder({
    required this.id,
    required this.quantity,
    this.cylinder,
  });

  factory SaleCylinder.fromJson(Map<String, dynamic> json) {
    return SaleCylinder(
      id: json['id'],
      quantity: json['quantity'],
      cylinder: json['cylinder'] != null ? Cylinder.fromJson(json['cylinder']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
      'cylinderId': cylinder?.id,
    };
  }
}

class Sale {
  final int id;
  final int customerId;
  final int sellerId;
  final DateTime saleDate;
  final String deliveryMethod; // Pickup, Delivery
  final int? truckId;
  final double totalAmount;
  final String paymentStatus; // Paid, Pending, Partial
  final double paidAmount;
  final String deliveryStatus; // Pending, InTransit, Delivered, Cancelled
  final DateTime? deliveryDate;
  final String? signatureImage;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Optional nested objects
  final Customer? customer;
  final User? seller;
  final Truck? truck;
  final List<SaleCylinder>? cylinders;

  Sale({
    required this.id,
    required this.customerId,
    required this.sellerId,
    required this.saleDate,
    required this.deliveryMethod,
    this.truckId,
    required this.totalAmount,
    required this.paymentStatus,
    required this.paidAmount,
    required this.deliveryStatus,
    this.deliveryDate,
    this.signatureImage,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.customer,
    this.seller,
    this.truck,
    this.cylinders,
  });

  // Factory method to create a Sale from JSON
  factory Sale.fromJson(Map<String, dynamic> json) {
    List<SaleCylinder>? cylinderList;
    if (json['cylinders'] != null) {
      cylinderList = (json['cylinders'] as List)
          .map((item) => SaleCylinder.fromJson(item))
          .toList();
    }

    return Sale(
      id: json['id'],
      customerId: json['customerId'],
      sellerId: json['sellerId'],
      saleDate: DateTime.parse(json['saleDate']),
      deliveryMethod: json['deliveryMethod'],
      truckId: json['truckId'],
      totalAmount: json['totalAmount'] is int 
        ? json['totalAmount'].toDouble() 
        : json['totalAmount'],
      paymentStatus: json['paymentStatus'],
      paidAmount: json['paidAmount'] is int 
        ? json['paidAmount'].toDouble() 
        : json['paidAmount'],
      deliveryStatus: json['deliveryStatus'],
      deliveryDate: json['deliveryDate'] != null 
        ? DateTime.parse(json['deliveryDate']) 
        : null,
      signatureImage: json['signatureImage'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt']) 
        : DateTime.now(),
      customer: json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      seller: json['seller'] != null ? User.fromJson(json['seller']) : null,
      truck: json['truck'] != null ? Truck.fromJson(json['truck']) : null,
      cylinders: cylinderList,
    );
  }

  // Convert Sale to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'sellerId': sellerId,
      'saleDate': saleDate.toIso8601String(),
      'deliveryMethod': deliveryMethod,
      'truckId': truckId,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
      'paidAmount': paidAmount,
      'deliveryStatus': deliveryStatus,
      'deliveryDate': deliveryDate?.toIso8601String(),
      'signatureImage': signatureImage,
      'notes': notes,
    };
  }

  // Create a copy of this Sale with the given fields replaced
  Sale copyWith({
    int? id,
    int? customerId,
    int? sellerId,
    DateTime? saleDate,
    String? deliveryMethod,
    int? truckId,
    double? totalAmount,
    String? paymentStatus,
    double? paidAmount,
    String? deliveryStatus,
    DateTime? deliveryDate,
    String? signatureImage,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Customer? customer,
    User? seller,
    Truck? truck,
    List<SaleCylinder>? cylinders,
  }) {
    return Sale(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      sellerId: sellerId ?? this.sellerId,
      saleDate: saleDate ?? this.saleDate,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      truckId: truckId ?? this.truckId,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      signatureImage: signatureImage ?? this.signatureImage,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customer: customer ?? this.customer,
      seller: seller ?? this.seller,
      truck: truck ?? this.truck,
      cylinders: cylinders ?? this.cylinders,
    );
  }

  // Create a Sale for new Sale form (for create operation)
  factory Sale.empty() {
    return Sale(
      id: 0,
      customerId: 0,
      sellerId: 0,
      saleDate: DateTime.now(),
      deliveryMethod: 'Pickup',
      totalAmount: 0.0,
      paymentStatus: 'Pending',
      paidAmount: 0.0,
      deliveryStatus: 'Pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Helper methods
  bool get isPaid => paymentStatus == 'Paid';
  bool get isPartiallyPaid => paymentStatus == 'Partial';
  bool get isPending => paymentStatus == 'Pending';
  
  bool get isDelivered => deliveryStatus == 'Delivered';
  bool get isInTransit => deliveryStatus == 'InTransit';
  bool get isCancelled => deliveryStatus == 'Cancelled';
  
  bool get isPickup => deliveryMethod == 'Pickup';
  bool get isDelivery => deliveryMethod == 'Delivery';
  
  double get remainingAmount => totalAmount - paidAmount;
  
  int get cylinderCount {
    if (cylinders == null) return 0;
    
    int count = 0;
    for (var cylinder in cylinders!) {
      count += cylinder.quantity;
    }
    return count;
  }
}
