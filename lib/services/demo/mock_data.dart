import '../../models/appointment.dart';
import '../../models/service.dart';
import '../../models/barber.dart';
import '../../models/dashboard_barber.dart';
import '../../models/user_profile.dart';

/// Datos mock estáticos para el modo demo
class MockData {
  // Servicios de ejemplo - Salón de Belleza
  static List<ServiceDto> get mockServices => [
    ServiceDto(
      id: 1,
      name: 'Corte de Cabello',
      price: 200.00,
      durationMinutes: 45,
      isActive: true,
    ),
    ServiceDto(
      id: 2,
      name: 'Corte + Peinado',
      price: 300.00,
      durationMinutes: 60,
      isActive: true,
    ),
    ServiceDto(
      id: 3,
      name: 'Coloración Completa',
      price: 450.00,
      durationMinutes: 120,
      isActive: true,
    ),
    ServiceDto(
      id: 4,
      name: 'Mechas',
      price: 350.00,
      durationMinutes: 90,
      isActive: true,
    ),
    ServiceDto(
      id: 5,
      name: 'Tratamiento Capilar',
      price: 180.00,
      durationMinutes: 30,
      isActive: true,
    ),
    ServiceDto(
      id: 6,
      name: 'Alisado',
      price: 400.00,
      durationMinutes: 150,
      isActive: true,
    ),
    ServiceDto(
      id: 7,
      name: 'Manicure',
      price: 120.00,
      durationMinutes: 40,
      isActive: true,
    ),
    ServiceDto(
      id: 8,
      name: 'Pedicure',
      price: 150.00,
      durationMinutes: 50,
      isActive: true,
    ),
  ];

  // Citas de ejemplo para hoy
  static List<AppointmentDto> get mockTodayAppointments {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    return [
      AppointmentDto(
        id: 1,
        barberId: 1,
        barberName: 'Salón GlowNic',
        services: [mockServices[0], mockServices[1]],
        clientName: 'María González',
        clientPhone: '8888-8888',
        date: today,
        time: '09:00',
        status: 'Confirmed',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      AppointmentDto(
        id: 2,
        barberId: 1,
        barberName: 'Salón GlowNic',
        services: [mockServices[2]],
        clientName: 'Ana Rodríguez',
        clientPhone: '7777-7777',
        date: today,
        time: '10:30',
        status: 'Pending',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      AppointmentDto(
        id: 3,
        barberId: 1,
        barberName: 'Salón GlowNic',
        services: [mockServices[3]],
        clientName: 'Carmen Martínez',
        clientPhone: '6666-6666',
        date: today,
        time: '14:00',
        status: 'Confirmed',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      AppointmentDto(
        id: 4,
        barberId: 1,
        barberName: 'Salón GlowNic',
        services: [mockServices[0], mockServices[6]],
        clientName: 'Laura Sánchez',
        clientPhone: '5555-5555',
        date: today,
        time: '16:30',
        status: 'Pending',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  // Citas pendientes
  static List<AppointmentDto> get mockPendingAppointments {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    
    return [
      AppointmentDto(
        id: 2,
        barberId: 1,
        barberName: 'Salón GlowNic',
        services: [mockServices[2]],
        clientName: 'Ana Rodríguez',
        clientPhone: '7777-7777',
        date: today,
        time: '10:30',
        status: 'Pending',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      AppointmentDto(
        id: 4,
        barberId: 1,
        barberName: 'Salón GlowNic',
        services: [mockServices[0], mockServices[6]],
        clientName: 'Laura Sánchez',
        clientPhone: '5555-5555',
        date: today,
        time: '16:30',
        status: 'Pending',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      AppointmentDto(
        id: 5,
        barberId: 1,
        barberName: 'Salón GlowNic',
        services: [mockServices[5]],
        clientName: 'Patricia López',
        clientPhone: '4444-4444',
        date: tomorrowStr,
        time: '09:00',
        status: 'Pending',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  // Historial completo de citas
  static List<AppointmentDto> get mockHistoryAppointments {
    final now = DateTime.now();
    final appointments = <AppointmentDto>[];
    
    // Citas de hoy
    appointments.addAll(mockTodayAppointments);
    
    // Citas de días anteriores
    for (int i = 1; i <= 15; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      appointments.add(
        AppointmentDto(
          id: 10 + i,
          barberId: 1,
          barberName: 'Salón GlowNic',
          services: [mockServices[i % mockServices.length]],
          clientName: 'Cliente ${i}',
          clientPhone: '${8000 + i}-${8000 + i}',
          date: dateStr,
          time: i % 2 == 0 ? '10:00' : '15:00',
          status: i % 3 == 0 ? 'Completed' : (i % 3 == 1 ? 'Confirmed' : 'Cancelled'),
          createdAt: date.subtract(const Duration(days: 1)),
        ),
      );
    }
    
    return appointments;
  }

  // Dashboard mock
  static BarberDashboardDto get mockDashboard {
    final now = DateTime.now();
    final barber = BarberDto(
      id: 1,
      name: 'Usuario de Prueba',
      businessName: 'Salón GlowNic',
      phone: '8888-8888',
      slug: 'salon-glownic',
      isActive: true,
      qrUrl: 'https://glownic.encuentrame.org/b/salon-glownic',
      createdAt: now.subtract(const Duration(days: 30)),
      email: 'demo@glownic.com',
    );

    return BarberDashboardDto(
      barber: barber,
      today: TodayStats(
        appointments: 4,
        completed: 2,
        pending: 2,
        income: 850.00,
        expenses: 150.00,
        profit: 700.00,
      ),
      thisWeek: WeekStats(
        appointments: 28,
        income: 5950.00,
        expenses: 1050.00,
        profit: 4900.00,
        uniqueClients: 22,
        averagePerClient: 270.45,
      ),
      thisMonth: MonthStats(
        appointments: 120,
        income: 25500.00,
        expenses: 4500.00,
        profit: 21000.00,
        uniqueClients: 85,
        averagePerClient: 300.00,
      ),
      recentAppointments: mockTodayAppointments.take(3).toList(),
      upcomingAppointments: mockTodayAppointments,
    );
  }

  // Perfil de usuario demo
  static UserProfile get mockUserProfile => UserProfile(
    userId: '999',
    userName: 'demo@glownic.com',
    role: 'Barber',
    nombre: 'Usuario',
    apellido: 'de Prueba',
    email: 'demo@glownic.com',
    phone: '8888-8888',
  );

  // Perfil de barbero demo
  static BarberDto get mockBarberProfile => BarberDto(
    id: 1,
    name: 'Usuario de Prueba',
      businessName: 'Salón GlowNic',
    phone: '8888-8888',
      slug: 'salon-glownic',
      isActive: true,
      qrUrl: 'https://glownic.encuentrame.org/b/salon-glownic',
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    email: 'demo@glownic.com',
  );
}

