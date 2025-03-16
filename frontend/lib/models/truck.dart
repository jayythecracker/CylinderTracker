class Truck {
  final int id;
  final String licenseNumber;
  final String type;
  final String owner;
  final int capacity;
  final String? driver;
  final String? driverContact;
  final String status; // Available, InTransit, Maintenance, OutOfService
  final DateTime? lastMaintenance;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Optional field when truck details are fetched
  final int? activeSalesCount;

  Truck({
    required this.id,
    required this.licenseNumber,
    required this.type,
    required this.owner,
    required this.capacity,
    this.driver,
    this.driverContact,
    required this.status,
    this.lastMaintenance,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.activeSalesCount,
  });

  // Factory method to create a Truck from JSON
  factory Truck.fromJson(Map<String, dynamic> json) {
    return Truck(
      id: json['id'],
      licenseNumber: json['licenseNumber'],
      type: json['type'],
      owner: json['owner'],
      capacity: json['capacity'],
      driver: json['driver'],
      driverContact: json['driverContact'],
      status: json['status'],
      lastMaintenance: json['lastMaintenance'] != null 
        ? DateTime.parse(json['lastMaintenance']) 
        : null,
      notes: json['notes'],
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt']) 
        : DateTime.now(),
      activeSalesCount: json['activeSalesCount'],
    );
  }

  // Convert Truck to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'licenseNumber': licenseNumber,
      'type': type,
      'owner': owner,
      'capacity': capacity,
      'driver': driver,
      'driverContact': driverContact,
      'status': status,
      'lastMaintenance': lastMaintenance?.toIso8601String(),
      'notes': notes,
    };
  }

  // Create a copy of this Truck with the given fields replaced
  Truck copyWith({
    int? id,
    String? licenseNumber,
    String? type,
    String? owner,
    int? capacity,
    String? driver,
    String? driverContact,
    String? status,
    DateTime? lastMaintenance,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? activeSalesCount,
  }) {
    return Truck(
      id: id ?? this.id,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      type: type ?? this.type,
      owner: owner ?? this.owner,
      capacity: capacity ?? this.capacity,
      driver: driver ?? this.driver,
      driverContact: driverContact ?? this.driverContact,
      status: status ?? this.status,
      lastMaintenance: lastMaintenance ?? this.lastMaintenance,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      activeSalesCount: activeSalesCount ?? this.activeSalesCount,
    );
  }

  // Create a Truck for new Truck form (for create operation)
  factory Truck.empty() {
    return Truck(
      id: 0,
      licenseNumber: '',
      type: '',
      owner: '',
      capacity: 0,
      status: 'Available',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Helper method to check if truck is available
  bool get isAvailable => status == 'Available';

  // Helper method to check if truck is in transit
  bool get isInTransit => status == 'InTransit';

  // Helper method to check if truck is in maintenance
  bool get isInMaintenance => status == 'Maintenance';

  // Helper method to check if truck is out of service
  bool get isOutOfService => status == 'OutOfService';

  // Helper method to format capacity as string
  String get capacityFormatted => '$capacity cylinders';
}
