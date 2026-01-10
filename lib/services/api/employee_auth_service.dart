import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';

/// Servicio de autenticación específico para operaciones del empleado autenticado.
class EmployeeAuthService {
  final Dio _dio;

  EmployeeAuthService(this._dio);

  /// Cambiar contraseña del empleado autenticado.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/employee/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return;
      }
      throw Exception('No se pudo cambiar la contraseña. Código ${response.statusCode}');
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

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
    }
  }
}

final employeeAuthServiceProvider = Provider<EmployeeAuthService>((ref) {
  final dio = ref.watch(dioProvider);
  return EmployeeAuthService(dio);
});


