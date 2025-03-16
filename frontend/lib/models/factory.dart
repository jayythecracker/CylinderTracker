// Factory model
class Factory {
  final int id;
  final String name;
  final String location;
  final String? contact;
  final String? email;
  final bool isActive;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? cylinderCount; // For displaying cylinder count

  const Factory({
    required this.id,
    required this.name,
    required this.location,
    this.contact,
    this.email,
    required this.isActive,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.cylinderCount,
  });

  // Factory constructor to create Factory from JSON
  factory Factory.fromJson(Map<String, dynamic> json) {
    return Factory(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      contact: json['contact'],
      email: json['email'],
      isActive: json['isActive'] ?? true,
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      cylinderCount: json['cylinderCount'],
    );
  }

  // Convert Factory to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'contact': contact,
      'email': email,
      'isActive': isActive,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy of the factory with updated fields
  Factory copyWith({
    int? id,
    String? name,
    String? location,
    String? contact,
    String? email,
    bool? isActive,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? cylinderCount,
  }) {
    return Factory(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cylinderCount: cylinderCount ?? this.cylinderCount,
    );
  }
}
