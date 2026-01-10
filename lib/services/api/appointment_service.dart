import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/appointment.dart';
import '../../providers/providers.dart';
import '../../providers/auth_provider.dart';
import '../demo/mock_appointment_service.dart';

class AppointmentService {
  final Dio _dio;

  AppointmentService(this._dio);

  Future<List<AppointmentDto>> getAppointments({
    String? date,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) queryParams['date'] = date;
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/barber/appointments',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      
      // Validar que la respuesta sea JSON
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
      
      // Log del primer elemento para debugging
      if ((response.data as List).isNotEmpty) {
      }
      
      return (response.data as List)
          .map((json) {
            try {
              return AppointmentDto.fromJson(json);
            } catch (e) {
              rethrow;
            }
          })
          .toList();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      
      // Si es 404, probablemente no hay citas, retornar lista vacía
      if (statusCode == 404) {
        return [];
      }
      
      if (e.response?.data is String && (e.response!.data as String).contains('<!DOCTYPE')) {
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

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
        'status': 'Confirmed', // Las citas creadas manualmente por el barbero se crean directamente como confirmadas
      };
      
      // Solo incluir serviceIds si se proporciona y no está vacío
      if (serviceIds != null && serviceIds.isNotEmpty) {
        body['serviceIds'] = serviceIds;
      }
      
      final response = await _dio.post(
        '/barber/appointments',
        data: body,
      );
      return AppointmentDto.fromJson(response.data);
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener una cita específica
  Future<AppointmentDto> getAppointment(int id) async {
    try {
      final response = await _dio.get('/barber/appointments/$id');
      
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

  Future<AppointmentDto> updateAppointment({
    required int id,
    String? status,
    String? date,
    String? time,
    String? clientName,
    String? clientPhone,
    int? serviceId, // Legacy
    List<int>? serviceIds, // Nuevo: múltiples servicios
  }) async {
    try {
      final body = <String, dynamic>{};
      if (status != null) body['status'] = status;
      if (date != null) body['date'] = date;
      if (time != null) body['time'] = time;
      if (clientName != null) body['clientName'] = clientName;
      if (clientPhone != null) body['clientPhone'] = clientPhone;
      if (serviceId != null) body['serviceId'] = serviceId; // Legacy
      if (serviceIds != null && serviceIds.isNotEmpty) {
        body['serviceIds'] = serviceIds; // Nuevo
      }

      final response = await _dio.put(
        '/barber/appointments/$id',
        data: body,
      );
      return AppointmentDto.fromJson(response.data);
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAppointment(int id) async {
    await _dio.delete('/barber/appointments/$id');
  }

  Future<Map<String, dynamic>> getWhatsAppUrl(int id) async {
    try {
      final response = await _dio.get('/barber/appointments/$id/whatsapp-url');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener historial completo de citas (sin filtros de fecha)
  Future<List<AppointmentDto>> getHistory() async {
    try {
      final response = await _dio.get('/barber/appointments/history');
      
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
          .map((json) {
            try {
              return AppointmentDto.fromJson(json);
            } catch (e) {
              rethrow;
            }
          })
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

// Provider que devuelve AppointmentService o MockAppointmentService según el modo
final appointmentServiceProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(authNotifierProvider);
  
  // Si está en modo demo, usar servicio mock
  if (authState.isDemoMode) {
    return MockAppointmentService();
  }
  
  final dio = ref.watch(dioProvider);
  return AppointmentService(dio);
});

