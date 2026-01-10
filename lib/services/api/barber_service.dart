import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/barber.dart';
import '../../models/dashboard_barber.dart';
import '../../models/finance.dart';
import '../../models/auth.dart';
import '../../providers/providers.dart';
import '../../providers/auth_provider.dart';
import '../demo/mock_barber_service.dart';

class BarberService {
  final Dio _dio;

  BarberService(this._dio);

  Future<BarberDashboardDto> getDashboard() async {
    try {
      final response = await _dio.get('/barber/dashboard');
      
      // Validar que la respuesta sea JSON
      if (response.data is String && (response.data as String).trim().startsWith('<!DOCTYPE')) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'El servidor devolvió HTML. Posible sesión expirada o token inválido.',
        );
      }
      
      return BarberDashboardDto.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data is String && (e.response!.data as String).contains('<!DOCTYPE')) {
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<BarberDto> getProfile() async {
    try {
      final response = await _dio.get('/barber/profile');
      
      // Validar que la respuesta sea JSON
      if (response.data is String && (response.data as String).trim().startsWith('<!DOCTYPE')) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'El servidor devolvió HTML. Posible sesión expirada o token inválido.',
        );
      }
      
      return BarberDto.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data is String && (e.response!.data as String).contains('<!DOCTYPE')) {
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<BarberDto> updateProfile({
    required String name,
    String? businessName,
    required String phone,
  }) async {
    final response = await _dio.put(
      '/barber/profile',
      data: {
        'name': name,
        'businessName': businessName,
        'phone': phone,
      },
    );
    return BarberDto.fromJson(response.data);
  }

  Future<QrResponse> getQrCode() async {
    final response = await _dio.get('/barber/qr-url');
    return QrResponse.fromJson(response.data);
  }

  Future<FinanceSummaryDto> getFinanceSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await _dio.get(
        '/barber/finances/summary',
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
      
      return FinanceSummaryDto.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data is String && (e.response!.data as String).contains('<!DOCTYPE')) {
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Cambiar contraseña del barbero autenticado
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/barber/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      // Mensajes amigables según respuesta del backend
      if (statusCode == 400) {
        final message = (data is Map && data['message'] is String)
            ? data['message'] as String
            : 'La contraseña actual es incorrecta.';
        throw Exception(message);
      }

      if (statusCode == 401) {
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
      }

      final message = (data is Map && data['message'] is String)
          ? data['message'] as String
          : 'No se pudo cambiar la contraseña. Inténtalo más tarde.';
      throw Exception(message);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<WorkingHoursDto>> getWorkingHours() async {
    try {
      final response = await _dio.get('/barber/working-hours');
      
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
              return WorkingHoursDto.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              rethrow;
            }
          })
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

  Future<void> updateWorkingHours(List<Map<String, dynamic>> workingHours) async {
    try {
      final requestData = {
        'workingHours': workingHours,
      };
      final response = await _dio.put(
        '/barber/working-hours',
        data: requestData,
      );
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}

final barberServiceProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(authNotifierProvider);
  
  // Si está en modo demo, usar servicio mock
  if (authState.isDemoMode) {
    return MockBarberService();
  }
  
  final dio = ref.watch(dioProvider);
  return BarberService(dio);
});

