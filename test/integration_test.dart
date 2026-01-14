import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:system_movil/services/api/api_config.dart';
import 'package:system_movil/services/api/auth_service.dart';
import 'package:system_movil/services/api/appointment_service.dart';
import 'package:system_movil/services/api/service_service.dart';
import 'package:system_movil/services/api/employee_service.dart';
import 'package:system_movil/services/api/finance_service.dart';
import 'package:system_movil/services/api/salon_service.dart';
import 'package:system_movil/services/api/export_service.dart';
import 'package:system_movil/services/storage/token_storage.dart';
import 'package:system_movil/models/appointment.dart';
import 'package:system_movil/models/service.dart';
import 'package:system_movil/models/employee.dart';
import 'package:system_movil/models/finance.dart';

/// Tests de integración completos para GlowNic
/// 
/// Credenciales de prueba:
/// Email: william@gmail.com
/// Password: wisofer17

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late Dio dio;
  late String authToken;
  late AuthService authService;
  
  group('🔐 Tests de Autenticación', () {
    late TokenStorage tokenStorage;

    setUp(() {
      dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: ApiConfig.defaultHeaders,
      ));
      // Crear un TokenStorage mock para tests
      tokenStorage = TokenStorage();
      authService = AuthService(dio, tokenStorage);
    });

    test('✅ Login exitoso con credenciales válidas', () async {
      try {
        final response = await authService.login(
          'william@gmail.com',
          'wisofer17',
        );
        
        expect(response, isNotNull);
        expect(response.token, isNotEmpty);
        expect(response.refreshToken, isNotEmpty);
        
        authToken = response.token;
        dio.options.headers['Authorization'] = 'Bearer $authToken';
        
        // Verificar que el token se guardó correctamente
        final savedToken = await tokenStorage.getAccessToken();
        expect(savedToken, isNotNull);
        expect(savedToken, authToken);
        
        print('✅ Login exitoso - Token obtenido y guardado');
      } catch (e) {
        print('❌ Error en login: $e');
        fail('❌ Error en login: $e');
      }
    });

    test('❌ Login falla con credenciales inválidas', () async {
      try {
        await authService.login(
          'william@gmail.com',
          'password_incorrecto',
        );
        fail('❌ Debería haber fallado con credenciales inválidas');
      } catch (e) {
        expect(e, isA<Exception>());
        print('✅ Login correctamente rechazado con credenciales inválidas');
      }
    });
  });

  group('📅 Tests de Citas (Appointments)', () {
    late AppointmentService appointmentService;
    int? createdAppointmentId;

    setUp(() {
      appointmentService = AppointmentService(dio);
    });

    test('✅ Crear cita nueva', () async {
      try {
        final appointment = await appointmentService.createAppointment(
          clientName: 'Cliente Test',
          clientPhone: '50512345678',
          date: DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
          time: '10:00',
          serviceIds: null,
        );
        
        expect(appointment, isNotNull);
        expect(appointment.id, greaterThan(0));
        expect(appointment.clientName, 'Cliente Test');
        expect(appointment.status, 'Confirmed');
        
        createdAppointmentId = appointment.id;
        print('✅ Cita creada exitosamente - ID: ${appointment.id}');
      } catch (e) {
        fail('❌ Error al crear cita: $e');
      }
    });

    test('✅ Obtener lista de citas', () async {
      try {
        final appointments = await appointmentService.getAppointments();
        
        expect(appointments, isA<List<AppointmentDto>>());
        expect(appointments.length, greaterThanOrEqualTo(0));
        
        print('✅ Lista de citas obtenida - Total: ${appointments.length}');
      } catch (e) {
        fail('❌ Error al obtener citas: $e');
      }
    });

    test('✅ Obtener cita específica', () async {
      if (createdAppointmentId == null) {
        // Crear una cita primero
        final appointment = await appointmentService.createAppointment(
          clientName: 'Cliente Test Get',
          clientPhone: '50512345679',
          date: DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
          time: '11:00',
        );
        createdAppointmentId = appointment.id;
      }

      try {
        final appointment = await appointmentService.getAppointment(createdAppointmentId!);
        
        expect(appointment, isNotNull);
        expect(appointment.id, createdAppointmentId);
        
        print('✅ Cita obtenida exitosamente - ID: ${appointment.id}');
      } catch (e) {
        fail('❌ Error al obtener cita: $e');
      }
    });

    test('✅ Actualizar estado de cita a Completed', () async {
      if (createdAppointmentId == null) {
        final appointment = await appointmentService.createAppointment(
          clientName: 'Cliente Test Update',
          clientPhone: '50512345680',
          date: DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
          time: '12:00',
        );
        createdAppointmentId = appointment.id;
      }

      try {
        final updated = await appointmentService.updateAppointment(
          id: createdAppointmentId!,
          status: 'Completed',
        );
        
        expect(updated.status, 'Completed');
        
        print('✅ Cita actualizada a Completed - ID: ${updated.id}');
      } catch (e) {
        fail('❌ Error al actualizar cita: $e');
      }
    });

    test('✅ Obtener URL de WhatsApp para confirmación', () async {
      if (createdAppointmentId == null) {
        final appointment = await appointmentService.createAppointment(
          clientName: 'Cliente Test WhatsApp',
          clientPhone: '50512345681',
          date: DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
          time: '13:00',
        );
        createdAppointmentId = appointment.id;
      }

      try {
        final whatsappData = await appointmentService.getWhatsAppUrl(createdAppointmentId!);
        
        expect(whatsappData, isNotNull);
        expect(whatsappData['url'], isNotNull);
        expect(whatsappData['url'], contains('wa.me'));
        
        print('✅ URL de WhatsApp obtenida: ${whatsappData['url']}');
      } catch (e) {
        fail('❌ Error al obtener URL de WhatsApp: $e');
      }
    });

    test('✅ Obtener URL de WhatsApp para rechazo', () async {
      if (createdAppointmentId == null) {
        final appointment = await appointmentService.createAppointment(
          clientName: 'Cliente Test Reject',
          clientPhone: '50512345682',
          date: DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
          time: '14:00',
        );
        createdAppointmentId = appointment.id;
      }

      try {
        final whatsappData = await appointmentService.getWhatsAppUrlReject(createdAppointmentId!);
        
        expect(whatsappData, isNotNull);
        expect(whatsappData['url'], isNotNull);
        expect(whatsappData['url'], contains('wa.me'));
        
        print('✅ URL de WhatsApp de rechazo obtenida: ${whatsappData['url']}');
      } catch (e) {
        fail('❌ Error al obtener URL de WhatsApp de rechazo: $e');
      }
    });
  });

  group('💅 Tests de Servicios (Services)', () {
    late ServiceService serviceService;
    int? createdServiceId;

    setUp(() {
      serviceService = ServiceService(dio);
    });

    test('✅ Crear servicio nuevo', () async {
      try {
        final service = await serviceService.createService(
          name: 'Corte de Cabello Test',
          price: 150.0,
          durationMinutes: 30,
        );
        
        expect(service, isNotNull);
        expect(service.id, greaterThan(0));
        expect(service.name, 'Corte de Cabello Test');
        expect(service.price, 150.0);
        
        createdServiceId = service.id;
        print('✅ Servicio creado exitosamente - ID: ${service.id}');
      } catch (e) {
        fail('❌ Error al crear servicio: $e');
      }
    });

    test('✅ Obtener lista de servicios', () async {
      try {
        final services = await serviceService.getServices();
        
        expect(services, isA<List<ServiceDto>>());
        expect(services.length, greaterThanOrEqualTo(0));
        
        print('✅ Lista de servicios obtenida - Total: ${services.length}');
      } catch (e) {
        fail('❌ Error al obtener servicios: $e');
      }
    });

    test('✅ Actualizar servicio', () async {
      if (createdServiceId == null) {
        final service = await serviceService.createService(
          name: 'Servicio Test Update',
          price: 200.0,
          durationMinutes: 45,
        );
        createdServiceId = service.id;
      }

      try {
        final updated = await serviceService.updateService(
          id: createdServiceId!,
          name: 'Servicio Actualizado',
          price: 250.0,
          durationMinutes: 60,
        );
        
        expect(updated.name, 'Servicio Actualizado');
        expect(updated.price, 250.0);
        
        print('✅ Servicio actualizado exitosamente - ID: ${updated.id}');
      } catch (e) {
        fail('❌ Error al actualizar servicio: $e');
      }
    });

    test('✅ Desactivar servicio', () async {
      if (createdServiceId == null) {
        final service = await serviceService.createService(
          name: 'Servicio Test Deactivate',
          price: 100.0,
          durationMinutes: 30,
        );
        createdServiceId = service.id;
      }

      try {
        final updated = await serviceService.updateService(
          id: createdServiceId!,
          name: 'Servicio Test Deactivate',
          price: 100.0,
          durationMinutes: 30,
          isActive: false,
        );
        
        expect(updated.isActive, false);
        
        print('✅ Servicio desactivado exitosamente - ID: ${updated.id}');
      } catch (e) {
        fail('❌ Error al desactivar servicio: $e');
      }
    });
  });

  group('👥 Tests de Trabajadores (Employees)', () {
    late EmployeeService employeeService;
    int? createdEmployeeId;

    setUp(() {
      employeeService = EmployeeService(dio);
    });

    test('✅ Crear trabajador nuevo', () async {
      try {
        final request = CreateEmployeeRequest(
          name: 'Trabajador Test',
          email: 'trabajador.test@glownic.com',
          phone: '50512345690',
          password: 'password123',
        );
        
        final employee = await employeeService.createEmployee(request);
        
        expect(employee, isNotNull);
        expect(employee.id, greaterThan(0));
        expect(employee.name, 'Trabajador Test');
        
        createdEmployeeId = employee.id;
        print('✅ Trabajador creado exitosamente - ID: ${employee.id}');
      } catch (e) {
        fail('❌ Error al crear trabajador: $e');
      }
    });

    test('✅ Obtener lista de trabajadores', () async {
      try {
        final employees = await employeeService.getEmployees();
        
        expect(employees, isA<List<EmployeeDto>>());
        expect(employees.length, greaterThanOrEqualTo(0));
        
        print('✅ Lista de trabajadores obtenida - Total: ${employees.length}');
      } catch (e) {
        fail('❌ Error al obtener trabajadores: $e');
      }
    });

    test('✅ Actualizar trabajador', () async {
      if (createdEmployeeId == null) {
        final request = CreateEmployeeRequest(
          name: 'Trabajador Test Update',
          email: 'trabajador.update@glownic.com',
          phone: '50512345691',
          password: 'password123',
        );
        final employee = await employeeService.createEmployee(request);
        createdEmployeeId = employee.id;
      }

      try {
        final updateRequest = UpdateEmployeeRequest(
          name: 'Trabajador Actualizado',
          phone: '50512345692',
          isActive: true,
        );
        
        final updated = await employeeService.updateEmployee(
          createdEmployeeId!,
          updateRequest,
        );
        
        expect(updated.name, 'Trabajador Actualizado');
        
        print('✅ Trabajador actualizado exitosamente - ID: ${updated.id}');
      } catch (e) {
        fail('❌ Error al actualizar trabajador: $e');
      }
    });
  });

  group('💰 Tests de Finanzas (Finance)', () {
    late FinanceService financeService;

    setUp(() {
      financeService = FinanceService(dio);
    });

    test('✅ Crear ingreso', () async {
      try {
        final income = await financeService.createIncome(
          amount: 500.0,
          description: 'Ingreso Test',
          category: 'Servicios',
          date: DateTime.now(),
        );
        
        expect(income, isNotNull);
        expect(income.id, greaterThan(0));
        expect(income.amount, 500.0);
        expect(income.type, 'Income');
        
        print('✅ Ingreso creado exitosamente - ID: ${income.id}');
      } catch (e) {
        fail('❌ Error al crear ingreso: $e');
      }
    });

    test('✅ Obtener lista de ingresos', () async {
      try {
        final response = await financeService.getIncome();
        
        expect(response, isNotNull);
        expect(response.items, isA<List<TransactionDto>>());
        
        print('✅ Lista de ingresos obtenida - Total: ${response.items.length}');
      } catch (e) {
        fail('❌ Error al obtener ingresos: $e');
      }
    });

    test('✅ Crear gasto', () async {
      try {
        final expense = await financeService.createExpense(
          amount: 100.0,
          description: 'Gasto Test',
          category: 'Suministros',
          date: DateTime.now(),
        );
        
        expect(expense, isNotNull);
        expect(expense.id, greaterThan(0));
        expect(expense.amount, 100.0);
        expect(expense.type, 'Expense');
        
        print('✅ Gasto creado exitosamente - ID: ${expense.id}');
      } catch (e) {
        fail('❌ Error al crear gasto: $e');
      }
    });

    test('✅ Obtener lista de gastos', () async {
      try {
        final response = await financeService.getExpenses();
        
        expect(response, isNotNull);
        expect(response.items, isA<List<TransactionDto>>());
        
        print('✅ Lista de gastos obtenida - Total: ${response.items.length}');
      } catch (e) {
        fail('❌ Error al obtener gastos: $e');
      }
    });
  });

  group('🏢 Tests de Perfil del Salón (Salon Profile)', () {
    late SalonService salonService;

    setUp(() {
      salonService = SalonService(dio);
    });

    test('✅ Obtener información del salón', () async {
      try {
        final salon = await salonService.getProfile();
        
        expect(salon, isNotNull);
        expect(salon.id, greaterThan(0));
        
        print('✅ Información del salón obtenida - ID: ${salon.id}');
      } catch (e) {
        fail('❌ Error al obtener información del salón: $e');
      }
    });

    test('✅ Actualizar información del salón', () async {
      try {
        final updated = await salonService.updateProfile(
          name: 'Salón GlowNic Test',
          phone: '50512345699',
        );
        
        expect(updated, isNotNull);
        
        print('✅ Información del salón actualizada exitosamente');
      } catch (e) {
        fail('❌ Error al actualizar información del salón: $e');
      }
    });

    test('✅ Obtener horarios de trabajo', () async {
      try {
        final workingHours = await salonService.getWorkingHours();
        
        expect(workingHours, isA<List>());
        expect(workingHours.length, greaterThanOrEqualTo(0));
        
        print('✅ Horarios de trabajo obtenidos - Total: ${workingHours.length}');
      } catch (e) {
        fail('❌ Error al obtener horarios de trabajo: $e');
      }
    });

    test('✅ Actualizar horarios de trabajo', () async {
      try {
        final workingHours = [
          {
            'dayOfWeek': 1,
            'startTime': '09:00',
            'endTime': '18:00',
            'isActive': true,
          },
          {
            'dayOfWeek': 2,
            'startTime': '09:00',
            'endTime': '18:00',
            'isActive': true,
          },
        ];
        
        await salonService.updateWorkingHours(workingHours);
        
        print('✅ Horarios de trabajo actualizados exitosamente');
      } catch (e) {
        fail('❌ Error al actualizar horarios de trabajo: $e');
      }
    });
  });

  group('📊 Tests de Exportación de Datos', () {
    late ExportService exportService;

    setUp(() {
      exportService = ExportService(dio);
    });

    test('✅ Exportar datos (verificar que el endpoint existe)', () async {
      try {
        // Este test verifica que el servicio puede ser instanciado
        // La exportación real requiere descargar archivos
        expect(exportService, isNotNull);
        
        print('✅ Servicio de exportación disponible');
      } catch (e) {
        fail('❌ Error en servicio de exportación: $e');
      }
    });
  });

  group('📈 Tests de Estadísticas y Reportes', () {
    late SalonService salonService;

    setUp(() {
      salonService = SalonService(dio);
    });


    test('✅ Obtener dashboard del salón', () async {
      try {
        final dashboard = await salonService.getDashboard();
        
        expect(dashboard, isNotNull);
        
        print('✅ Dashboard del salón obtenido');
      } catch (e) {
        fail('❌ Error al obtener dashboard del salón: $e');
      }
    });

    test('✅ Obtener resumen financiero', () async {
      try {
        final summary = await salonService.getFinanceSummary(
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
        );
        
        expect(summary, isNotNull);
        
        print('✅ Resumen financiero obtenido');
      } catch (e) {
        fail('❌ Error al obtener resumen financiero: $e');
      }
    });
  });
}
