import 'barber.dart';
import 'appointment.dart';
import 'employee_reports.dart';

class BarberDashboardDto {
  final BarberDto barber;
  final TodayStats today;
  final WeekStats thisWeek;
  final MonthStats thisMonth;
  final List<AppointmentDto> recentAppointments;
  final List<AppointmentDto> upcomingAppointments;
  final EmployeeStatsDto? employeeStats;

  BarberDashboardDto({
    required this.barber,
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.recentAppointments,
    required this.upcomingAppointments,
    this.employeeStats,
  });

  factory BarberDashboardDto.fromJson(Map<String, dynamic> json) => BarberDashboardDto(
        barber: BarberDto.fromJson(json['barber']),
        today: TodayStats.fromJson(json['today']),
        thisWeek: WeekStats.fromJson(json['thisWeek']),
        thisMonth: MonthStats.fromJson(json['thisMonth']),
        recentAppointments: (json['recentAppointments'] as List?)
                ?.map((e) => AppointmentDto.fromJson(e))
                .toList() ??
            [],
        upcomingAppointments: (json['upcomingAppointments'] as List?)
                ?.map((e) => AppointmentDto.fromJson(e))
                .toList() ??
            [],
        employeeStats: json['employeeStats'] != null
            ? EmployeeStatsDto.fromJson(json['employeeStats'] as Map<String, dynamic>)
            : null,
      );
}

class TodayStats {
  final int appointments;
  final int completed;
  final int pending;
  final double income;
  final double expenses;
  final double profit;

  TodayStats({
    required this.appointments,
    required this.completed,
    required this.pending,
    required this.income,
    required this.expenses,
    required this.profit,
  });

  factory TodayStats.fromJson(Map<String, dynamic> json) => TodayStats(
        appointments: json['appointments'] ?? 0,
        completed: json['completed'] ?? 0,
        pending: json['pending'] ?? 0,
        income: (json['income'] ?? 0).toDouble(),
        expenses: (json['expenses'] ?? 0).toDouble(),
        profit: (json['profit'] ?? 0).toDouble(),
      );
}

class WeekStats {
  final int appointments;
  final double income;
  final double expenses;
  final double profit;
  final int uniqueClients;
  final double averagePerClient;

  WeekStats({
    required this.appointments,
    required this.income,
    required this.expenses,
    required this.profit,
    this.uniqueClients = 0,
    this.averagePerClient = 0.0,
  });

  factory WeekStats.fromJson(Map<String, dynamic> json) => WeekStats(
        appointments: json['appointments'] ?? 0,
        income: (json['income'] ?? 0).toDouble(),
        expenses: (json['expenses'] ?? 0).toDouble(),
        profit: (json['profit'] ?? 0).toDouble(),
        uniqueClients: json['uniqueClients'] ?? 0,
        averagePerClient: (json['averagePerClient'] ?? 0).toDouble(),
      );
}

class MonthStats {
  final int appointments;
  final double income;
  final double expenses;
  final double profit;
  final int uniqueClients;
  final double averagePerClient;

  MonthStats({
    required this.appointments,
    required this.income,
    required this.expenses,
    required this.profit,
    this.uniqueClients = 0,
    this.averagePerClient = 0.0,
  });

  factory MonthStats.fromJson(Map<String, dynamic> json) => MonthStats(
        appointments: json['appointments'] ?? 0,
        income: (json['income'] ?? 0).toDouble(),
        expenses: (json['expenses'] ?? 0).toDouble(),
        profit: (json['profit'] ?? 0).toDouble(),
        uniqueClients: json['uniqueClients'] ?? 0,
        averagePerClient: (json['averagePerClient'] ?? 0).toDouble(),
      );
}

