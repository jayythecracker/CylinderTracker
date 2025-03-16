enum CustomerType { Hospital, Factory, Shop, Workshop, Individual }
enum PaymentType { Cash, Credit }

class Customer {
  final int id;
  final String name;
  final CustomerType type;
  final String? contactPerson;
  final String? contactNumber;
  final String? email;
  final String? address;
  final PaymentType paymentType;
  final double creditLimit;
  final double currentCredit;
  final String? notes;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.type,
    this.contactPerson,
    this.contactNumber,
    this.email,
    this.address,
    required this.paymentType,
    required this.creditLimit,
    required this.currentCredit,
    this.notes,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory method to create a Customer from JSON
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      type: CustomerType.values.firstWhere(
        (e) => e.toString() == 'CustomerType.${json['type']}',
        orElse: () => CustomerType.Individual,
      ),
      contactPerson: json['contact_person'],
      contactNumber: json['contact_number'],
      email: json['email'],
      address: json['address'],
      paymentType: PaymentType.values.firstWhere(
        (e) => e.toString() == 'PaymentType.${json['payment_type']}',
        orElse: () => PaymentType.Cash,
      ),
      creditLimit: (json['credit_limit'] ?? 0.0).toDouble(),
      currentCredit: (json['current_credit'] ?? 0.0).toDouble(),
      notes: json['notes'],
      active: json['active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  // Convert Customer to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'contact_person': contactPerson,
      'contact_number': contactNumber,
      'email': email,
      'address': address,
      'payment_type': paymentType.toString().split('.').last,
      'credit_limit': creditLimit,
      'current_credit': currentCredit,
      'notes': notes,
      'active': active,
    };
  }

  // Create a copy of this Customer with the given fields replaced
  Customer copyWith({
    int? id,
    String? name,
    CustomerType? type,
    String? contactPerson,
    String? contactNumber,
    String? email,
    String? address,
    PaymentType? paymentType,
    double? creditLimit,
    double? currentCredit,
    String? notes,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      contactPerson: contactPerson ?? this.contactPerson,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      paymentType: paymentType ?? this.paymentType,
      creditLimit: creditLimit ?? this.creditLimit,
      currentCredit: currentCredit ?? this.currentCredit,
      notes: notes ?? this.notes,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods to check customer type
  bool get isHospital => type == CustomerType.Hospital;
  bool get isFactory => type == CustomerType.Factory;
  bool get isShop => type == CustomerType.Shop;
  bool get isWorkshop => type == CustomerType.Workshop;
  bool get isIndividual => type == CustomerType.Individual;

  // Helper methods for payment and credit
  bool get isCashCustomer => paymentType == PaymentType.Cash;
  bool get isCreditCustomer => paymentType == PaymentType.Credit;
  double get availableCredit => creditLimit - currentCredit;
  bool get hasAvailableCredit => availableCredit > 0;

  // Empty customer for form initialization
  factory Customer.empty() {
    return Customer(
      id: 0,
      name: '',
      type: CustomerType.Individual,
      paymentType: PaymentType.Cash,
      creditLimit: 0.0,
      currentCredit: 0.0,
      active: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return '$name (${type.toString().split('.').last})';
  }
}