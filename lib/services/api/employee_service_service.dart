import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/service.dart';
import '../../providers/providers.dart';

/// Servicio para que los empleados puedan ver servicios (solo lectura)
class EmployeeServiceService {
  final Dio _dio;

  EmployeeServiceService(this._dio);

  /// Obtener todos los servicios del barbero dueño (solo lectura para empleados)
  Future<List<ServiceDto>> getServices() async {
    try {
      final response = await _dio.get('/employee/services');
      
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
      return (response.data as List)
          .map((json) => ServiceDto.fromJson(json))
          .toList();
    } on DioException catch (e) {
      if (e.response?.data is String && (e.response!.data as String).contains('<!DOCTYPE')) {
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener un servicio específico por ID (solo lectura para empleados)
  Future<ServiceDto> getService(int id) async {
    try {
      final response = await _dio.get('/employee/services/$id');
      
      // Validar que la respuesta sea JSON
      if (response.data is String && (response.data as String).trim().startsWith('<!DOCTYPE')) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'El servidor devolvió HTML. Posible sesión expirada o token inválido.',
        );
      }
      
      return ServiceDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}

final employeeServiceServiceProvider = Provider<EmployeeServiceService>((ref) {
  final dio = ref.watch(dioProvider);
  return EmployeeServiceService(dio);
});

