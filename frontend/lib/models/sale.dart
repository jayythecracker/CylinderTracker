import 'user.dart';
import 'customer.dart';
import 'cylinder.dart';
import 'truck.dart';

class Sale {
  final int id;
  final String invoiceNumber;
  final DateTime saleDate;
  final int customerId;
  final int sellerId;
  final String deliveryType;
  final int? truckId;
  final String status;
  final double totalAmount;
  final double paidAmount;
  final String paymentStatus;
  final String paymentMethod;
  final String? notes;
  final String? deliveryAddress;
  final String? customerSignature;
  final DateTime? deliveryDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Customer? customer;
  final User? seller;
  final Truck? truck;
  final List<SaleItem>? items;

  Sale({
    required this.id,
    required this.invoiceNumber,
    required this.saleDate,
    required this.customerId,
    required this.sellerId,
    required this.deliveryType,
    this.truckId,
    required this.status,
    required this.totalAmount,
    required this.paidAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    this.notes,
    this.deliveryAddress,
    this.customerSignature,
    this.deliveryDate,
    required this.createdAt,
    required this.updatedAt,
    this.customer,
    this.seller,
    this.truck,
    this.items,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'],
      invoiceNumber: json['invoiceNumber'],
      saleDate: DateTime.parse(json['saleDate']),
      customerId: json['customerId'],
      sellerId: json['sellerId'],
      deliveryType: json['deliveryType'],
      truckId: json['truckId'],
      status: json['status'],
      totalAmount: json['totalAmount'].toDouble(),
      paidAmount: json['paidAmount'].toDouble(),
      paymentStatus: json['paymentStatus'],
      paymentMethod: json['paymentMethod'],
      notes: json['notes'],
      deliveryAddress: json['deliveryAddress'],
      customerSignature: json['customerSignature'],
      deliveryDate: json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      customer: json['Customer'] != null ? Customer.fromJson(json['Customer']) : null,
      seller: json['Seller'] != null ? User.fromJson(json['Seller']) : null,
      truck: json['Truck'] != null ? Truck.fromJson(json['Truck']) : null,
      items: json['SaleItems'] != null
          ? (json['SaleItems'] as List).map((e) => SaleItem.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'saleDate': saleDate.toIso8601String(),
      'customerId': customerId,
      'sellerId': sellerId,
      'deliveryType': deliveryType,
      'truckId': truckId,
      'status': status,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'deliveryAddress': deliveryAddress,
      'customerSignature': customerSignature,
      'deliveryDate': deliveryDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // For creating a new sale
  Map<String, dynamic> toCreateJson() {
    return {
      'customerId': customerId,
      'deliveryType': deliveryType,
      'truckId': truckId,
      'items': items?.map((item) => {
        'cylinderId': item.cylinderId,
        'price': item.price,
      }).toList(),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'deliveryAddress': deliveryAddress,
    };
  }

  // For updating sale status
  Map<String, dynamic> toUpdateStatusJson() {
    return {
      'status': status,
      'customerSignature': customerSignature,
      'deliveryDate': deliveryDate?.toIso8601String(),
    };
  }

  // For updating payment
  Map<String, dynamic> toUpdatePaymentJson(double additionalAmount) {
    return {
      'paidAmount': additionalAmount,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  Sale copyWith({
    int? id,
    String? invoiceNumber,
    DateTime? saleDate,
    int? customerId,
    int? sellerId,
    String? deliveryType,
    int? truckId,
    String? status,
    double? totalAmount,
    double? paidAmount,
    String? paymentStatus,
    String? paymentMethod,
    String? notes,
    String? deliveryAddress,
    String? customerSignature,
    DateTime? deliveryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Customer? customer,
    User? seller,
    Truck? truck,
    List<SaleItem>? items,
  }) {
    return Sale(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      saleDate: saleDate ?? this.saleDate,
      customerId: customerId ?? this.customerId,
      sellerId: sellerId ?? this.sellerId,
      deliveryType: deliveryType ?? this.deliveryType,
      truckId: truckId ?? this.truckId,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      customerSignature: customerSignature ?? this.customerSignature,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customer: customer ?? this.customer,
      seller: seller ?? this.seller,
      truck: truck ?? this.truck,
      items: items ?? this.items,
    );
  }
}

class SaleItem {
  final int id;
  final int saleId;
  final int cylinderId;
  final double price;
  final bool returnedEmpty;
  final DateTime? returnDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Cylinder? cylinder;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.cylinderId,
    required this.price,
    required this.returnedEmpty,
    this.returnDate,
    required this.createdAt,
    required this.updatedAt,
    this.cylinder,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'],
      saleId: json['saleId'],
      cylinderId: json['cylinderId'],
      price: json['price'].toDouble(),
      returnedEmpty: json['returnedEmpty'],
      returnDate: json['returnDate'] != null ? DateTime.parse(json['returnDate']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      cylinder: json['Cylinder'] != null ? Cylinder.fromJson(json['Cylinder']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saleId': saleId,
      'cylinderId': cylinderId,
      'price': price,
      'returnedEmpty': returnedEmpty,
      'returnDate': returnDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // For recording a cylinder return
  Map<String, dynamic> toReturnJson() {
    return {
      'returnDate': DateTime.now().toIso8601String(),
    };
  }

  SaleItem copyWith({
    int? id,
    int? saleId,
    int? cylinderId,
    double? price,
    bool? returnedEmpty,
    DateTime? returnDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Cylinder? cylinder,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      cylinderId: cylinderId ?? this.cylinderId,
      price: price ?? this.price,
      returnedEmpty: returnedEmpty ?? this.returnedEmpty,
      returnDate: returnDate ?? this.returnDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cylinder: cylinder ?? this.cylinder,
    );
  }
}
