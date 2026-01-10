import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/dashboard.dart';
import '../../providers/providers.dart';

class DashboardService {
  final Dio _dio;

  DashboardService(this._dio);

  /// Dashboard general
  Future<DashboardData?> getDashboard() async {
    try {
      final response = await _dio.get('/dashboard');

      if (response.data['success'] == true) {
        return DashboardData.fromJson(response.data['data']);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Resumen rápido
  Future<Map<String, dynamic>> getResumen() async {
    try {
      final response = await _dio.get('/dashboard/resumen');

      if (response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      return {};
    } on DioException {
      return {};
    }
  }
}

// Provider
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  final dio = ref.watch(dioProvider);
  return DashboardService(dio);
});

