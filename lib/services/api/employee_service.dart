import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/employee.dart';
import '../../providers/providers.dart';

class EmployeeService {
  final Dio _dio;

  EmployeeService(this._dio);

  /// Obtener todos los trabajadores del barbero dueño
  Future<List<EmployeeDto>> getEmployees() async {
    try {
      final response = await _dio.get('/barber/employees');
      
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
          .map((json) => EmployeeDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener un trabajador por ID
  Future<EmployeeDto> getEmployeeById(int id) async {
    try {
      final response = await _dio.get('/barber/employees/$id');
      
      if (response.data is String && (response.data as String).trim().startsWith('<!DOCTYPE')) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'El servidor devolvió HTML. Posible sesión expirada o token inválido.',
        );
      }
      
      return EmployeeDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Crear un nuevo trabajador
  Future<EmployeeDto> createEmployee(CreateEmployeeRequest request) async {
    try {
      final response = await _dio.post(
        '/barber/employees',
        data: request.toJson(),
      );
      
      return EmployeeDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar un trabajador
  Future<EmployeeDto> updateEmployee(int id, UpdateEmployeeRequest request) async {
    try {
      final response = await _dio.put(
        '/barber/employees/$id',
        data: request.toJson(),
      );
      
      return EmployeeDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar (desactivar) un trabajador
  Future<void> deleteEmployee(int id) async {
    try {
      final response = await _dio.delete('/barber/employees/$id');
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}

final employeeServiceProvider = Provider<EmployeeService>((ref) {
  final dio = ref.watch(dioProvider);
  return EmployeeService(dio);
});

