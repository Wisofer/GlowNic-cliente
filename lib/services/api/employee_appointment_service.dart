import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/appointment.dart';
import '../../providers/providers.dart';
import '../../providers/auth_provider.dart';
import '../demo/mock_appointment_service.dart';

class EmployeeAppointmentService {
  final Dio _dio;

  EmployeeAppointmentService(this._dio);

  /// Obtener citas del trabajador autenticado
  Future<List<AppointmentDto>> getAppointments({
    String? date,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) queryParams['date'] = date;
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/employee/appointments',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      
      if (response.data is String && (response.data as String).trim().startsWith('<!DOCTYPE')) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'El servidor devolvió HTML. Posible sesión expirada o token inválido.',
        );
      }
      
      if (response.data is! List) {
        throw Exception('Respuesta inesperada: se esperaba una lista pero se recibió ${response.data.runtimeType}');
      }
      
      return (response.data as List)
          .map((json) => AppointmentDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      
      if (statusCode == 404) {
        return [];
      }
      
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Crear cita manual (trabajador)
  /// Las citas creadas manualmente por el trabajador se crean directamente como confirmadas
  Future<AppointmentDto> createAppointment({
    List<int>? serviceIds,
    required String clientName,
    required String clientPhone,
    required String date,
    required String time,
  }) async {
    try {
      final body = <String, dynamic>{
        'clientName': clientName,
        'clientPhone': clientPhone,
        'date': date,
        'time': time,
        'status': 'Confirmed', // Las citas creadas manualmente por el trabajador se crean directamente como confirmadas
      };
      
      if (serviceIds != null && serviceIds.isNotEmpty) {
        body['serviceIds'] = serviceIds;
      }

      final response = await _dio.post(
        '/employee/appointments',
        data: body,
      );
      
      return AppointmentDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener una cita específica
  Future<AppointmentDto> getAppointment(int id) async {
    try {
      final response = await _dio.get('/employee/appointments/$id');
      
      if (response.data is String && (response.data as String).trim().startsWith('<!DOCTYPE')) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'El servidor devolvió HTML. Posible sesión expirada o token inválido.',
        );
      }
      
      return AppointmentDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar cita (aceptar, completar, modificar)
  Future<AppointmentDto> updateAppointment({
    required int id,
    String? status,
    String? date,
    String? time,
    String? clientName,
    String? clientPhone,
    List<int>? serviceIds,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (status != null) body['status'] = status;
      if (date != null) body['date'] = date;
      if (time != null) body['time'] = time;
      if (clientName != null) body['clientName'] = clientName;
      if (clientPhone != null) body['clientPhone'] = clientPhone;
      if (serviceIds != null && serviceIds.isNotEmpty) {
        body['serviceIds'] = serviceIds;
      }

      final response = await _dio.put(
        '/employee/appointments/$id',
        data: body,
      );
      
      return AppointmentDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener historial completo de citas (sin filtros de fecha)
  Future<List<AppointmentDto>> getHistory() async {
    try {
      final response = await _dio.get('/employee/appointments/history');
      
      if (response.data is String && (response.data as String).trim().startsWith('<!DOCTYPE')) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'El servidor devolvió HTML. Posible sesión expirada o token inválido.',
        );
      }
      
      if (response.data is! List) {
        throw Exception('Respuesta inesperada: se esperaba una lista pero se recibió ${response.data.runtimeType}');
      }
      
      
      return (response.data as List)
          .map((json) => AppointmentDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      
      if (statusCode == 404) {
        return [];
      }
      
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}

final employeeAppointmentServiceProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(authNotifierProvider);
  
  // Si está en modo demo, usar servicio mock
  if (authState.isDemoMode) {
    return MockAppointmentService();
  }
  
  final dio = ref.watch(dioProvider);
  return EmployeeAppointmentService(dio);
});

