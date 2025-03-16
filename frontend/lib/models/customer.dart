class Customer {
  final int id;
  final String name;
  final String type; // Hospital, Individual, Shop, Factory, Workshop
  final String address;
  final String contact;
  final String? email;
  final String paymentType; // Cash, Credit
  final String priceGroup;
  final double? creditLimit;
  final double balance;
  final bool active;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional stats fields
  final int? totalSales;
  final double? totalAmount;

  Customer({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.contact,
    this.email,
    required this.paymentType,
    required this.priceGroup,
    this.creditLimit,
    this.balance = 0.0,
    this.active = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.totalSales,
    this.totalAmount,
  });

  // Factory method to create a Customer from JSON
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      address: json['address'],
      contact: json['contact'],
      email: json['email'],
      paymentType: json['paymentType'],
      priceGroup: json['priceGroup'],
      creditLimit: json['creditLimit'] != null 
        ? double.parse(json['creditLimit'].toString()) 
        : null,
      balance: json['balance'] != null 
        ? double.parse(json['balance'].toString()) 
        : 0.0,
      active: json['active'] ?? true,
      notes: json['notes'],
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt']) 
        : DateTime.now(),
      totalSales: json['stats'] != null ? json['stats']['totalSales'] : null,
      totalAmount: json['stats'] != null && json['stats']['totalAmount'] != null 
        ? double.parse(json['stats']['totalAmount'].toString()) 
        : null,
    );
  }

  // Convert Customer to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'address': address,
      'contact': contact,
      'email': email,
      'paymentType': paymentType,
      'priceGroup': priceGroup,
      'creditLimit': creditLimit,
      'balance': balance,
      'active': active,
      'notes': notes,
    };
  }

  // Create a copy of this Customer with the given fields replaced
  Customer copyWith({
    int? id,
    String? name,
    String? type,
    String? address,
    String? contact,
    String? email,
    String? paymentType,
    String? priceGroup,
    double? creditLimit,
    double? balance,
    bool? active,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalSales,
    double? totalAmount,
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
      active: active ?? this.active,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalSales: totalSales ?? this.totalSales,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  // Create a Customer for new Customer form (for create operation)
  factory Customer.empty() {
    return Customer(
      id: 0,
      name: '',
      type: 'Individual',
      address: '',
      contact: '',
      paymentType: 'Cash',
      priceGroup: 'Standard',
      balance: 0.0,
      active: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Helper method to get customer type display name
  String get typeDisplayName {
    switch (type) {
      case 'Hospital':
        return 'Hospital';
      case 'Individual':
        return 'Individual';
      case 'Shop':
        return 'Shop';
      case 'Factory':
        return 'Factory';
      case 'Workshop':
        return 'Workshop';
      default:
        return type;
    }
  }

  // Helper method to check if customer is credit customer
  bool get isCreditCustomer => paymentType == 'Credit';

  // Helper method to check if customer has outstanding balance
  bool get hasOutstandingBalance => balance > 0;
}
