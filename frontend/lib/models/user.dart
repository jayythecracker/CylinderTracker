// User model for the app
class User {
  final int id;
  final String name;
  final String email;
  final String? contact;
  final String? address;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.contact,
    this.address,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      contact: json['contact'],
      address: json['address'],
      role: _parseUserRole(json['role']),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'contact': contact,
      'address': address,
      'role': role.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy of the user with updated fields
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? contact,
    String? address,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Parse user role from string
  static UserRole _parseUserRole(String role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'filler':
        return UserRole.filler;
      case 'seller':
        return UserRole.seller;
      default:
        return UserRole.filler; // Default role
    }
  }
}

// Enum for user roles
enum UserRole {
  admin,
  manager,
  filler,
  seller
}

// Extension to get string representation of the role
extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.manager:
        return 'manager';
      case UserRole.filler:
        return 'filler';
      case UserRole.seller:
        return 'seller';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.filler:
        return 'Filler';
      case UserRole.seller:
        return 'Seller';
    }
  }
}
