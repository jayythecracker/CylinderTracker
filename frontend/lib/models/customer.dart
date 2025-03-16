// Customer model
class Customer {
  final int id;
  final String name;
  final CustomerType type;
  final String? address;
  final String? contact;
  final String? email;
  final PaymentType paymentType;
  final String? priceGroup;
  final double creditLimit;
  final double balance;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.name,
    required this.type,
    this.address,
    this.contact,
    this.email,
    required this.paymentType,
    this.priceGroup,
    required this.creditLimit,
    required this.balance,
    required this.isActive,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create Customer from JSON
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      type: _parseCustomerType(json['type']),
      address: json['address'],
      contact: json['contact'],
      email: json['email'],
      paymentType: _parsePaymentType(json['paymentType']),
      priceGroup: json['priceGroup'],
      creditLimit: json['creditLimit'] is int 
          ? json['creditLimit'].toDouble() 
          : json['creditLimit'] ?? 0.0,
      balance: json['balance'] is int
          ? json['balance'].toDouble()
          : json['balance'] ?? 0.0,
      isActive: json['isActive'] ?? true,
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Convert Customer to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'address': address,
      'contact': contact,
      'email': email,
      'paymentType': paymentType.name,
      'priceGroup': priceGroup,
      'creditLimit': creditLimit,
      'balance': balance,
      'isActive': isActive,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy of the customer with updated fields
  Customer copyWith({
    int? id,
    String? name,
    CustomerType? type,
    String? address,
    String? contact,
    String? email,
    PaymentType? paymentType,
    String? priceGroup,
    double? creditLimit,
    double? balance,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      paymentType: paymentType ?? this.paymentType,
      priceGroup: priceGroup ?? this.priceGroup,
      creditLimit: creditLimit ?? this.creditLimit,
      balance: balance ?? this.balance,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Parse customer type from string
  static CustomerType _parseCustomerType(String type) {
    switch (type) {
      case 'hospital':
        return CustomerType.hospital;
      case 'individual':
        return CustomerType.individual;
      case 'shop':
        return CustomerType.shop;
      case 'factory':
        return CustomerType.factory;
      case 'workshop':
        return CustomerType.workshop;
      default:
        return CustomerType.individual;
    }
  }

  // Parse payment type from string
  static PaymentType _parsePaymentType(String paymentType) {
    switch (paymentType) {
      case 'cash':
        return PaymentType.cash;
      case 'credit':
        return PaymentType.credit;
      default:
        return PaymentType.cash;
    }
  }
}

// Enum for customer types
enum CustomerType {
  hospital,
  individual,
  shop,
  factory,
  workshop
}

// Extension to get string representation of the customer type
extension CustomerTypeExtension on CustomerType {
  String get name {
    switch (this) {
      case CustomerType.hospital:
        return 'hospital';
      case CustomerType.individual:
        return 'individual';
      case CustomerType.shop:
        return 'shop';
      case CustomerType.factory:
        return 'factory';
      case CustomerType.workshop:
        return 'workshop';
    }
  }

  String get displayName {
    switch (this) {
      case CustomerType.hospital:
        return 'Hospital';
      case CustomerType.individual:
        return 'Individual';
      case CustomerType.shop:
        return 'Shop';
      case CustomerType.factory:
        return 'Factory';
      case CustomerType.workshop:
        return 'Workshop';
    }
  }
}

// Enum for payment types
enum PaymentType {
  cash,
  credit
}

// Extension to get string representation of the payment type
extension PaymentTypeExtension on PaymentType {
  String get name {
    switch (this) {
      case PaymentType.cash:
        return 'cash';
      case PaymentType.credit:
        return 'credit';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentType.cash:
        return 'Cash';
      case PaymentType.credit:
        return 'Credit';
    }
  }
}
