class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? contact;
  final String? address;
  final DateTime? lastLogin;
  final bool active;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.contact,
    this.address,
    this.lastLogin,
    this.active = true,
  });

  // Factory method to create a user from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      contact: json['contact'],
      address: json['address'],
      lastLogin: json['lastLogin'] != null 
        ? DateTime.parse(json['lastLogin']) 
        : null,
      active: json['active'] ?? true,
    );
  }

  // Convert user to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'contact': contact,
      'address': address,
      'lastLogin': lastLogin?.toIso8601String(),
      'active': active,
    };
  }

  // Check if the user has a specific role
  bool hasRole(String roleToCheck) {
    return role == roleToCheck;
  }

  // Check if the user has admin role
  bool get isAdmin => role == 'admin';

  // Check if the user has manager role
  bool get isManager => role == 'manager';

  // Check if the user has filler role
  bool get isFiller => role == 'filler';

  // Check if the user has seller role
  bool get isSeller => role == 'seller';

  // Get role display name
  String get roleDisplayName {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'manager':
        return 'Manager';
      case 'filler':
        return 'Filler';
      case 'seller':
        return 'Seller';
      default:
        return 'Unknown';
    }
  }

  // Create a copy of this user with the given fields replaced
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? contact,
    String? address,
    DateTime? lastLogin,
    bool? active,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      lastLogin: lastLogin ?? this.lastLogin,
      active: active ?? this.active,
    );
  }
}
