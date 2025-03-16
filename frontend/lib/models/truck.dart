class Truck {
  final int id;
  final String licenseNumber;
  final String type;
  final String owner;
  final int capacity;
  final String status;
  final String? driverName;
  final String? driverContact;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Truck({
    required this.id,
    required this.licenseNumber,
    required this.type,
    required this.owner,
    required this.capacity,
    required this.status,
    this.driverName,
    this.driverContact,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Truck.fromJson(Map<String, dynamic> json) {
    return Truck(
      id: json['id'],
      licenseNumber: json['licenseNumber'],
      type: json['type'],
      owner: json['owner'],
      capacity: json['capacity'],
      status: json['status'],
      driverName: json['driverName'],
      driverContact: json['driverContact'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'licenseNumber': licenseNumber,
      'type': type,
      'owner': owner,
      'capacity': capacity,
      'status': status,
      'driverName': driverName,
      'driverContact': driverContact,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // For creating a new truck
  Map<String, dynamic> toCreateJson() {
    return {
      'licenseNumber': licenseNumber,
      'type': type,
      'owner': owner,
      'capacity': capacity,
      'driverName': driverName,
      'driverContact': driverContact,
    };
  }

  Truck copyWith({
    int? id,
    String? licenseNumber,
    String? type,
    String? owner,
    int? capacity,
    String? status,
    String? driverName,
    String? driverContact,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Truck(
      id: id ?? this.id,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      type: type ?? this.type,
      owner: owner ?? this.owner,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      driverName: driverName ?? this.driverName,
      driverContact: driverContact ?? this.driverContact,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
