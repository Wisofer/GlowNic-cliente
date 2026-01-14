import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/salon.dart';
import '../../models/dashboard_salon.dart';
import '../../models/finance.dart';
import '../../models/auth.dart';
import '../../providers/providers.dart';
import '../../providers/auth_provider.dart';
import '../demo/mock_salon_service.dart';

class SalonService {
  final Dio _dio;

  SalonService(this._dio);

  Future<SalonDashboardDto> getDashboard() async {
    try {
      final response = await _dio.get('/salon/dashboard');
      
      // Validar que la respuesta sea JSON
      if (response.data is String && (response.data as String).trim().startsWith('<!DOCTYPE')) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'El servidor devolvió HTML. Posible sesión expirada o token inválido.',
        );
      }
      
      return SalonDashboardDto.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data is String && (e.response!.data as String).contains('<!DOCTYPE')) {
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<SalonDto> getProfile() async {
    try {
      final response = await _dio.get('/salon/profile');
      
      // Validar que la respuesta sea JSON
      if (response.data is String && (response.data as String).trim().startsWith('<!DOCTYPE')) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'El servidor devolvió HTML. Posible sesión expirada o token inválido.',
        );
      }
      
      return SalonDto.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data is String && (e.response!.data as String).contains('<!DOCTYPE')) {
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<SalonDto> updateProfile({
    required String name,
    String? businessName,
    required String phone,
  }) async {
    final response = await _dio.put(
      '/salon/profile',
      data: {
        'name': name,
        'businessName': businessName,
        'phone': phone,
      },
    );
    return SalonDto.fromJson(response.data);
  }

  Future<QrResponse> getQrCode() async {
    final response = await _dio.get('/salon/qr-url');
    return QrResponse.fromJson(response.data);
  }

  Future<FinanceSummaryDto> getFinanceSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        // Formato DateOnly: YYYY-MM-DD
        final year = startDate.year.toString();
        final month = startDate.month.toString().padLeft(2, '0');
        final day = startDate.day.toString().padLeft(2, '0');
        queryParams['startDate'] = '$year-$month-$day';
      }
      if (endDate != null) {
        // Formato DateOnly: YYYY-MM-DD
        final year = endDate.year.toString();
        final month = endDate.month.toString().padLeft(2, '0');
        final day = endDate.day.toString().padLeft(2, '0');
        queryParams['endDate'] = '$year-$month-$day';
      }

      final response = await _dio.get(
        '/salon/finances/summary',
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

  /// Cambiar contraseña del dueño autenticado
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/salon/change-password',
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
      final response = await _dio.get('/salon/working-hours');
      
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
      // CORRECCIÓN: El backend espera 'workingHours', NO 'request'
      final requestData = {
        'workingHours': workingHours,
      };
      
      await _dio.put(
        '/salon/working-hours',
        data: requestData,
      );
    } on DioException {
      rethrow;
    }
  }
}

final salonServiceProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(authNotifierProvider);
  
  // Si está en modo demo, usar servicio mock
  if (authState.isDemoMode) {
    return MockSalonService();
  }
  
  final dio = ref.watch(dioProvider);
  return SalonService(dio);
});
