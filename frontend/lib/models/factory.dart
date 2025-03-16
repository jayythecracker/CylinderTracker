class Factory {
  final int id;
  final String name;
  final String location;
  final String? contactPerson;
  final String? contactPhone;
  final String? email;
  final bool active;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? cylinderCount; // Optional field when factory details are fetched

  Factory({
    required this.id,
    required this.name,
    required this.location,
    this.contactPerson,
    this.contactPhone,
    this.email,
    this.active = true,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.cylinderCount,
  });

  // Factory method to create a Factory from JSON
  factory Factory.fromJson(Map<String, dynamic> json) {
    return Factory(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      contactPerson: json['contactPerson'],
      contactPhone: json['contactPhone'],
      email: json['email'],
      active: json['active'] ?? true,
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      cylinderCount: json['cylinderCount'],
    );
  }

  // Convert Factory to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      'email': email,
      'active': active,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy of this Factory with the given fields replaced
  Factory copyWith({
    int? id,
    String? name,
    String? location,
    String? contactPerson,
    String? contactPhone,
    String? email,
    bool? active,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? cylinderCount,
  }) {
    return Factory(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      email: email ?? this.email,
      active: active ?? this.active,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cylinderCount: cylinderCount ?? this.cylinderCount,
    );
  }

  // Create a Factory for new Factory form (for create operation)
  factory Factory.empty() {
    return Factory(
      id: 0,
      name: '',
      location: '',
      active: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
