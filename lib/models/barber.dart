import 'service.dart';

class BarberDto {
  final int id;
  final String name;
  final String? businessName;
  final String phone;
  final String slug;
  final bool isActive;
  final String qrUrl;
  final DateTime createdAt;
  final String? email;

  BarberDto({
    required this.id,
    required this.name,
    this.businessName,
    required this.phone,
    required this.slug,
    required this.isActive,
    required this.qrUrl,
    required this.createdAt,
    this.email,
  });

  factory BarberDto.fromJson(Map<String, dynamic> json) => BarberDto(
        id: json['id'],
        name: json['name'],
        businessName: json['businessName'],
        phone: json['phone'],
        slug: json['slug'],
        isActive: json['isActive'],
        qrUrl: json['qrUrl'],
        createdAt: DateTime.parse(json['createdAt']),
        email: json['email'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'businessName': businessName,
        'phone': phone,
        'slug': slug,
        'isActive': isActive,
        'qrUrl': qrUrl,
        'createdAt': createdAt.toIso8601String(),
        'email': email,
      };
}

class BarberPublicDto {
  final int id;
  final String name;
  final String? businessName;
  final String phone;
  final String slug;
  final List<ServiceDto> services;
  final List<WorkingHoursDto> workingHours;

  BarberPublicDto({
    required this.id,
    required this.name,
    this.businessName,
    required this.phone,
    required this.slug,
    required this.services,
    required this.workingHours,
  });

  factory BarberPublicDto.fromJson(Map<String, dynamic> json) => BarberPublicDto(
        id: json['id'],
        name: json['name'],
        businessName: json['businessName'],
        phone: json['phone'],
        slug: json['slug'],
        services: (json['services'] as List?)
                ?.map((e) => ServiceDto.fromJson(e))
                .toList() ??
            [],
        workingHours: (json['workingHours'] as List?)
                ?.map((e) => WorkingHoursDto.fromJson(e))
                .toList() ??
            [],
      );
}

class WorkingHoursDto {
  final int id;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isActive;

  WorkingHoursDto({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  factory WorkingHoursDto.fromJson(Map<String, dynamic> json) {
    try {
      // Manejar id que puede venir como String o int
      int id;
      if (json['id'] is String) {
        id = int.parse(json['id']);
      } else {
        id = json['id'] ?? 0;
      }
      
      // Manejar dayOfWeek que puede venir como String (nombre del día o número) o int
      int dayOfWeek;
      final dayOfWeekValue = json['dayOfWeek'];
      if (dayOfWeekValue is int) {
        dayOfWeek = dayOfWeekValue;
      } else if (dayOfWeekValue is String) {
        // Intentar parsear como número primero
        final parsed = int.tryParse(dayOfWeekValue);
        if (parsed != null) {
          dayOfWeek = parsed;
        } else {
          // Si no es número, convertir nombre del día a número
          dayOfWeek = _dayNameToNumber(dayOfWeekValue);
        }
      } else {
        dayOfWeek = 0;
      }
      
      // Normalizar formato de tiempo (puede venir con segundos)
      String startTime = json['startTime'] ?? '09:00';
      String endTime = json['endTime'] ?? '18:00';
      
      // Si viene con formato HH:mm:ss, quitar los segundos
      if (startTime.length > 5) {
        startTime = startTime.substring(0, 5);
      }
      if (endTime.length > 5) {
        endTime = endTime.substring(0, 5);
      }
      
      return WorkingHoursDto(
        id: id,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        isActive: json['isActive'] ?? false,
      );
    } catch (e, stackTrace) {
      rethrow;
    }
  }

  // Convertir nombre del día (en inglés) a número (0=Domingo, 1=Lunes, etc.)
  static int _dayNameToNumber(String dayName) {
    final dayMap = {
      'Sunday': 0,
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Domingo': 0,
      'Lunes': 1,
      'Martes': 2,
      'Miércoles': 3,
      'Jueves': 4,
      'Viernes': 5,
      'Sábado': 6,
    };
    return dayMap[dayName] ?? 0;
  }
}

