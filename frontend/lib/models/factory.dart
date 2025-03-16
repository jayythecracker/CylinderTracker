class Factory {
  final int id;
  final String name;
  final String location;
  final String? contactPerson;
  final String? contactEmail;
  final String? contactPhone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Factory({
    required this.id,
    required this.name,
    required this.location,
    this.contactPerson,
    this.contactEmail,
    this.contactPhone,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Factory.fromJson(Map<String, dynamic> json) {
    return Factory(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      contactPerson: json['contactPerson'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'contactPerson': contactPerson,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // For creating a new factory
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'location': location,
      'contactPerson': contactPerson,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
    };
  }

  Factory copyWith({
    int? id,
    String? name,
    String? location,
    String? contactPerson,
    String? contactEmail,
    String? contactPhone,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Factory(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      contactPerson: contactPerson ?? this.contactPerson,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
