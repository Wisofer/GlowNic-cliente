// Modelos para reportes de empleados

/// Reporte de citas por empleado
class EmployeeAppointmentsReportDto {
  final DateTime startDate;
  final DateTime endDate;
  final int totalAppointments;
  final List<EmployeeAppointmentStats> byEmployee;

  EmployeeAppointmentsReportDto({
    required this.startDate,
    required this.endDate,
    required this.totalAppointments,
    required this.byEmployee,
  });

  factory EmployeeAppointmentsReportDto.fromJson(Map<String, dynamic> json) {
    return EmployeeAppointmentsReportDto(
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate'].toString())
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'].toString())
          : DateTime.now(),
      totalAppointments: json['totalAppointments'] ?? 0,
      byEmployee: (json['byEmployee'] as List?)
              ?.map((e) => EmployeeAppointmentStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class EmployeeAppointmentStats {
  final int? employeeId;
  final String employeeName;
  final int completed;
  final int pending;
  final int confirmed;
  final int cancelled;
  final int total;
  final double totalIncome;
  final double averagePerAppointment;

  EmployeeAppointmentStats({
    this.employeeId,
    required this.employeeName,
    required this.completed,
    required this.pending,
    required this.confirmed,
    required this.cancelled,
    required this.total,
    required this.totalIncome,
    required this.averagePerAppointment,
  });

  factory EmployeeAppointmentStats.fromJson(Map<String, dynamic> json) {
    return EmployeeAppointmentStats(
      employeeId: json['employeeId'] is String ? int.tryParse(json['employeeId']) : json['employeeId'] as int?,
      employeeName: json['employeeName']?.toString() ?? 'Barbero (Dueño)',
      completed: json['completed'] ?? 0,
      pending: json['pending'] ?? 0,
      confirmed: json['confirmed'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
      total: json['total'] ?? 0,
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      averagePerAppointment: (json['averagePerAppointment'] ?? 0).toDouble(),
    );
  }
}

/// Reporte de ingresos por empleado
class EmployeeIncomeReportDto {
  final DateTime startDate;
  final DateTime endDate;
  final double totalIncome;
  final List<EmployeeIncomeStats> byEmployee;

  EmployeeIncomeReportDto({
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.byEmployee,
  });

  factory EmployeeIncomeReportDto.fromJson(Map<String, dynamic> json) {
    return EmployeeIncomeReportDto(
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate'].toString())
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'].toString())
          : DateTime.now(),
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      byEmployee: (json['byEmployee'] as List?)
              ?.map((e) => EmployeeIncomeStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class EmployeeIncomeStats {
  final int? employeeId;
  final String employeeName;
  final double totalIncome;
  final int count;
  final double fromAppointments;
  final double manual;
  final double averagePerTransaction;

  EmployeeIncomeStats({
    this.employeeId,
    required this.employeeName,
    required this.totalIncome,
    required this.count,
    required this.fromAppointments,
    required this.manual,
    required this.averagePerTransaction,
  });

  factory EmployeeIncomeStats.fromJson(Map<String, dynamic> json) {
    return EmployeeIncomeStats(
      employeeId: json['employeeId'] is String ? int.tryParse(json['employeeId']) : json['employeeId'] as int?,
      employeeName: json['employeeName']?.toString() ?? 'Barbero (Dueño)',
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
      fromAppointments: (json['fromAppointments'] ?? 0).toDouble(),
      manual: (json['manual'] ?? 0).toDouble(),
      averagePerTransaction: (json['averagePerTransaction'] ?? 0).toDouble(),
    );
  }
}

/// Reporte de egresos por empleado
class EmployeeExpensesReportDto {
  final DateTime startDate;
  final DateTime endDate;
  final double totalExpenses;
  final List<EmployeeExpenseStats> byEmployee;

  EmployeeExpensesReportDto({
    required this.startDate,
    required this.endDate,
    required this.totalExpenses,
    required this.byEmployee,
  });

  factory EmployeeExpensesReportDto.fromJson(Map<String, dynamic> json) {
    return EmployeeExpensesReportDto(
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate'].toString())
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'].toString())
          : DateTime.now(),
      totalExpenses: (json['totalExpenses'] ?? 0).toDouble(),
      byEmployee: (json['byEmployee'] as List?)
              ?.map((e) => EmployeeExpenseStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class EmployeeExpenseStats {
  final int? employeeId;
  final String employeeName;
  final double totalExpenses;
  final int count;
  final Map<String, double> categories;
  final double averagePerTransaction;

  EmployeeExpenseStats({
    this.employeeId,
    required this.employeeName,
    required this.totalExpenses,
    required this.count,
    required this.categories,
    required this.averagePerTransaction,
  });

  factory EmployeeExpenseStats.fromJson(Map<String, dynamic> json) {
    final categoriesMap = <String, double>{};
    if (json['categories'] is Map) {
      (json['categories'] as Map).forEach((key, value) {
        categoriesMap[key.toString()] = (value as num).toDouble();
      });
    }

    return EmployeeExpenseStats(
      employeeId: json['employeeId'] is String ? int.tryParse(json['employeeId']) : json['employeeId'] as int?,
      employeeName: json['employeeName']?.toString() ?? 'Barbero (Dueño)',
      totalExpenses: (json['totalExpenses'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
      categories: categoriesMap,
      averagePerTransaction: (json['averagePerTransaction'] ?? 0).toDouble(),
    );
  }
}

/// Reporte de actividad general de empleados
class EmployeeActivityReportDto {
  final DateTime startDate;
  final DateTime endDate;
  final List<EmployeeActivityStats> employees;

  EmployeeActivityReportDto({
    required this.startDate,
    required this.endDate,
    required this.employees,
  });

  factory EmployeeActivityReportDto.fromJson(Map<String, dynamic> json) {
    return EmployeeActivityReportDto(
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate'].toString())
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'].toString())
          : DateTime.now(),
      employees: (json['employees'] as List?)
              ?.map((e) => EmployeeActivityStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class EmployeeActivityStats {
  final int? employeeId;
  final String employeeName;
  final String email;
  final bool isActive;
  final int appointmentsCompleted;
  final int appointmentsPending;
  final double totalIncome;
  final double totalExpenses;
  final double netContribution;
  final double averagePerAppointment;
  final DateTime? lastActivity;

  EmployeeActivityStats({
    this.employeeId,
    required this.employeeName,
    required this.email,
    required this.isActive,
    required this.appointmentsCompleted,
    required this.appointmentsPending,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netContribution,
    required this.averagePerAppointment,
    this.lastActivity,
  });

  factory EmployeeActivityStats.fromJson(Map<String, dynamic> json) {
    return EmployeeActivityStats(
      employeeId: json['employeeId'] is String ? int.tryParse(json['employeeId']) : json['employeeId'] as int?,
      employeeName: json['employeeName']?.toString() ?? 'Barbero (Dueño)',
      email: json['email']?.toString() ?? '',
      isActive: json['isActive'] ?? true,
      appointmentsCompleted: json['appointmentsCompleted'] ?? 0,
      appointmentsPending: json['appointmentsPending'] ?? 0,
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      totalExpenses: (json['totalExpenses'] ?? 0).toDouble(),
      netContribution: (json['netContribution'] ?? 0).toDouble(),
      averagePerAppointment: (json['averagePerAppointment'] ?? 0).toDouble(),
      lastActivity: json['lastActivity'] != null
          ? DateTime.parse(json['lastActivity'].toString())
          : null,
    );
  }
}

/// Estadísticas de empleados en el dashboard
class EmployeeStatsDto {
  final int totalEmployees;
  final int activeEmployees;
  final List<TopPerformerDto> topPerformers;

  EmployeeStatsDto({
    required this.totalEmployees,
    required this.activeEmployees,
    required this.topPerformers,
  });

  factory EmployeeStatsDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return EmployeeStatsDto(
        totalEmployees: 0,
        activeEmployees: 0,
        topPerformers: [],
      );
    }

    return EmployeeStatsDto(
      totalEmployees: json['totalEmployees'] ?? 0,
      activeEmployees: json['activeEmployees'] ?? 0,
      topPerformers: (json['topPerformers'] as List?)
              ?.map((e) => TopPerformerDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TopPerformerDto {
  final int? employeeId;
  final String employeeName;
  final int appointmentsCompleted;
  final double totalIncome;
  final double averagePerAppointment;

  TopPerformerDto({
    this.employeeId,
    required this.employeeName,
    required this.appointmentsCompleted,
    required this.totalIncome,
    required this.averagePerAppointment,
  });

  factory TopPerformerDto.fromJson(Map<String, dynamic> json) {
    return TopPerformerDto(
      employeeId: json['employeeId'] is String ? int.tryParse(json['employeeId']) : json['employeeId'] as int?,
      employeeName: json['employeeName']?.toString() ?? 'Barbero (Dueño)',
      appointmentsCompleted: json['appointmentsCompleted'] ?? 0,
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      averagePerAppointment: (json['averagePerAppointment'] ?? 0).toDouble(),
    );
  }
}

