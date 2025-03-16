class CylinderType {
  final int id;
  final String name;         // e.g., "Medical", "Industrial"
  final String gasType;      // e.g., "Oxygen", "Nitrogen", "Carbon Dioxide"
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CylinderType({
    required this.id,
    required this.name,
    required this.gasType,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory method to create a CylinderType from JSON
  factory CylinderType.fromJson(Map<String, dynamic> json) {
    return CylinderType(
      id: json['id'],
      name: json['name'],
      gasType: json['gasType'],
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  // Convert CylinderType to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gasType': gasType,
      'description': description,
      'isActive': isActive,
      // Dates are not included when sending to API
    };
  }

  // Create a copy of this CylinderType with the given fields replaced
  CylinderType copyWith({
    int? id,
    String? name,
    String? gasType,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CylinderType(
      id: id ?? this.id,
      name: name ?? this.name,
      gasType: gasType ?? this.gasType,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Create an empty CylinderType (for form initialization)
  factory CylinderType.empty() {
    return CylinderType(
      id: 0,
      name: '',
      gasType: '',
      description: '',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Predefined common types
  static List<CylinderType> predefinedTypes() {
    return [
      CylinderType(
        id: 1,
        name: 'Medical',
        gasType: 'Oxygen',
        description: 'Medical grade oxygen for hospital use',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CylinderType(
        id: 2,
        name: 'Industrial',
        gasType: 'Oxygen',
        description: 'Industrial grade oxygen for welding and manufacturing',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CylinderType(
        id: 3,
        name: 'Medical',
        gasType: 'Nitrogen',
        description: 'Medical grade nitrogen for medical equipment',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CylinderType(
        id: 4,
        name: 'Industrial',
        gasType: 'Nitrogen',
        description: 'Industrial grade nitrogen for manufacturing processes',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CylinderType(
        id: 5,
        name: 'Industrial',
        gasType: 'Carbon Dioxide',
        description: 'Industrial grade carbon dioxide for welding and manufacturing',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CylinderType(
        id: 6,
        name: 'Industrial',
        gasType: 'Argon',
        description: 'Industrial grade argon for welding applications',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      CylinderType(
        id: 7,
        name: 'Industrial',
        gasType: 'Acetylene',
        description: 'Industrial grade acetylene for welding and cutting',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}