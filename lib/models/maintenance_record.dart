class MaintenanceRecord {
  final String id;
  final DateTime maintenanceDate;
  final String maintenanceContent;
  final double cost;
  final String futureMaintenance;
  final int currentMileage;
  final List<String> imagePaths;
  final VehicleType vehicleType;

  MaintenanceRecord({
    required this.id,
    required this.maintenanceDate,
    required this.maintenanceContent,
    required this.cost,
    required this.futureMaintenance,
    required this.currentMileage,
    required this.imagePaths,
    required this.vehicleType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'maintenanceDate': maintenanceDate.toIso8601String(),
      'maintenanceContent': maintenanceContent,
      'cost': cost,
      'futureMaintenance': futureMaintenance,
      'currentMileage': currentMileage,
      'imagePaths': imagePaths,
      'vehicleType': vehicleType.toString(),
    };
  }

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'],
      maintenanceDate: DateTime.parse(json['maintenanceDate']),
      maintenanceContent: json['maintenanceContent'],
      cost: json['cost'].toDouble(),
      futureMaintenance: json['futureMaintenance'],
      currentMileage: json['currentMileage'],
      imagePaths: List<String>.from(json['imagePaths']),
      vehicleType: VehicleType.values.firstWhere(
        (e) => e.toString() == json['vehicleType'],
      ),
    );
  }
}

enum VehicleType {
  car,
  bike,
}

extension VehicleTypeExtension on VehicleType {
  String get displayName {
    switch (this) {
      case VehicleType.car:
        return '자동차';
      case VehicleType.bike:
        return '바이크';
    }
  }

  String get icon {
    switch (this) {
      case VehicleType.car:
        return '🚗';
      case VehicleType.bike:
        return '🏍️';
    }
  }
}
