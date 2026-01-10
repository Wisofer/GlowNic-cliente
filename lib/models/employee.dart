class EmployeeDto {
  final int id;
  final int ownerBarberId;
  final String ownerBarberName;
  final String name;
  final String email;
  final String? phone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmployeeDto({
    required this.id,
    required this.ownerBarberId,
    required this.ownerBarberName,
    required this.name,
    required this.email,
    this.phone,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmployeeDto.fromJson(Map<String, dynamic> json) {
    return EmployeeDto(
      id: json['id'] as int,
      ownerBarberId: json['ownerBarberId'] as int,
      ownerBarberName: json['ownerBarberName'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerBarberId': ownerBarberId,
      'ownerBarberName': ownerBarberName,
      'name': name,
      'email': email,
      'phone': phone,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class CreateEmployeeRequest {
  final String name;
  final String email;
  final String password;
  final String? phone;

  CreateEmployeeRequest({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
    };
  }
}

class UpdateEmployeeRequest {
  final String name;
  final String? phone;
  final bool isActive;

  UpdateEmployeeRequest({
    required this.name,
    this.phone,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      'isActive': isActive,
    };
  }
}

