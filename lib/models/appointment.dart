import 'service.dart';

class AppointmentDto {
  final int id;
  final int barberId;
  final String barberName;
  
  // Información del empleado asignado
  final int? employeeId;
  final String? employeeName;
  
  // Lista de todos los servicios (NUEVO)
  final List<ServiceDto> services;
  
  // Campos de compatibilidad (primer servicio)
  final int? serviceId;
  final String? serviceName;
  final double? servicePrice;
  
  final String clientName;
  final String clientPhone;
  final String date; // DateOnly format: "YYYY-MM-DD"
  final String time; // TimeOnly format: "HH:mm"
  final String status; // "Pending", "Confirmed", "Cancelled", "Completed"
  final DateTime createdAt;

  AppointmentDto({
    required this.id,
    required this.barberId,
    required this.barberName,
    this.employeeId,
    this.employeeName,
    required this.services,
    this.serviceId,
    this.serviceName,
    this.servicePrice,
    required this.clientName,
    required this.clientPhone,
    required this.date,
    required this.time,
    required this.status,
    required this.createdAt,
  });

  factory AppointmentDto.fromJson(Map<String, dynamic> json) {
    // Parsear lista de servicios
    List<ServiceDto> servicesList = [];
    if (json['services'] != null && json['services'] is List) {
      servicesList = (json['services'] as List)
          .map((serviceJson) => ServiceDto.fromJson(serviceJson))
          .toList();
    }
    
    // Campos de compatibilidad (primer servicio o valores directos)
    int? serviceId;
    String? serviceName;
    double? servicePrice;
    
    if (servicesList.isNotEmpty) {
      // Si hay servicios en la lista, usar el primero
      serviceId = servicesList.first.id;
      serviceName = servicesList.first.name;
      servicePrice = servicesList.first.price;
    } else {
      // Compatibilidad: usar campos directos si existen
      serviceId = json['serviceId'] is String ? int.tryParse(json['serviceId']) : json['serviceId'] as int?;
      serviceName = json['serviceName'] as String?;
      servicePrice = (json['servicePrice'] as num?)?.toDouble();
    }
    
    return AppointmentDto(
      id: json['id'] ?? 0,
      barberId: json['barberId'] ?? 0,
      barberName: json['barberName'] ?? '',
      employeeId: json['employeeId'] is String ? int.tryParse(json['employeeId']) : json['employeeId'] as int?,
      employeeName: json['employeeName'] as String?,
      services: servicesList,
      serviceId: serviceId,
      serviceName: serviceName ?? '',
      servicePrice: servicePrice ?? 0.0,
      clientName: json['clientName'] ?? '',
      clientPhone: json['clientPhone'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? 'Pending',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'barberId': barberId,
        'barberName': barberName,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'serviceId': serviceId,
        'serviceName': serviceName,
        'servicePrice': servicePrice,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'date': date,
        'time': time,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  // Helpers
  DateTime get dateTime {
    final dateParts = date.split('-');
    final timeParts = time.split(':');
    return DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  bool get isPending => status == 'Pending';
  bool get isConfirmed => status == 'Confirmed';
  bool get isCancelled => status == 'Cancelled';
  bool get isCompleted => status == 'Completed';
  
  // Helpers para verificar asignación
  bool get isAssigned => employeeId != null;
  bool get isUnassigned => employeeId == null;
  
  // Verificar si está asignada al empleado actual (requiere pasar el employeeId actual)
  bool isAssignedTo(int? currentEmployeeId) {
    return employeeId != null && employeeId == currentEmployeeId;
  }
}

