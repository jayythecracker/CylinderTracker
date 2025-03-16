class Customer {
  final int id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String customerType; // Hospital, Factory, Shop, Workshop, Individual
  final double balance;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    required this.customerType,
    required this.balance,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory method to create a Customer from JSON
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      postalCode: json['postalCode'],
      country: json['country'],
      customerType: json['customerType'],
      balance: json['balance'] is int 
          ? json['balance'].toDouble() 
          : json['balance'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  // Convert Customer to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'customerType': customerType,
      'balance': balance,
      'notes': notes,
    };
  }

  // Create a copy of this Customer with the given fields replaced
  Customer copyWith({
    int? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? customerType,
    double? balance,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      customerType: customerType ?? this.customerType,
      balance: balance ?? this.balance,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // String representation of the customer
  @override
  String toString() {
    return '$name (ID: $id)';
  }

  // Helper methods to check customer type
  bool get isHospital => customerType == 'Hospital';
  bool get isFactory => customerType == 'Factory';
  bool get isShop => customerType == 'Shop';
  bool get isWorkshop => customerType == 'Workshop';
  bool get isIndividual => customerType == 'Individual';

  // Get the full address as a string
  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    
    return parts.join(', ');
  }

  // Empty customer for form initialization
  factory Customer.empty() {
    return Customer(
      id: 0,
      name: '',
      customerType: 'Individual',
      balance: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}