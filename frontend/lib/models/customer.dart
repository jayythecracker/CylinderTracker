class Customer {
  final int id;
  final String name;
  final String type;
  final String address;
  final String? contactPerson;
  final String contactNumber;
  final String? email;
  final String paymentType;
  final String? priceGroup;
  final double creditLimit;
  final double currentCredit;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    this.contactPerson,
    required this.contactNumber,
    this.email,
    required this.paymentType,
    this.priceGroup,
    required this.creditLimit,
    required this.currentCredit,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      address: json['address'],
      contactPerson: json['contactPerson'],
      contactNumber: json['contactNumber'],
      email: json['email'],
      paymentType: json['paymentType'],
      priceGroup: json['priceGroup'],
      creditLimit: json['creditLimit'].toDouble(),
      currentCredit: json['currentCredit'].toDouble(),
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'address': address,
      'contactPerson': contactPerson,
      'contactNumber': contactNumber,
      'email': email,
      'paymentType': paymentType,
      'priceGroup': priceGroup,
      'creditLimit': creditLimit,
      'currentCredit': currentCredit,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // For creating a new customer
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'type': type,
      'address': address,
      'contactPerson': contactPerson,
      'contactNumber': contactNumber,
      'email': email,
      'paymentType': paymentType,
      'priceGroup': priceGroup,
      'creditLimit': creditLimit,
    };
  }

  Customer copyWith({
    int? id,
    String? name,
    String? type,
    String? address,
    String? contactPerson,
    String? contactNumber,
    String? email,
    String? paymentType,
    String? priceGroup,
    double? creditLimit,
    double? currentCredit,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      contactPerson: contactPerson ?? this.contactPerson,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      paymentType: paymentType ?? this.paymentType,
      priceGroup: priceGroup ?? this.priceGroup,
      creditLimit: creditLimit ?? this.creditLimit,
      currentCredit: currentCredit ?? this.currentCredit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
