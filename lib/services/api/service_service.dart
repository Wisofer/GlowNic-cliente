import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/service.dart';
import '../../providers/providers.dart';
import '../../providers/auth_provider.dart';
import '../demo/mock_service_service.dart';

class ServiceService {
  final Dio _dio;

  ServiceService(this._dio);

  Future<List<ServiceDto>> getServices() async {
    try {
      final response = await _dio.get('/barber/services');
      
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

  Future<ServiceDto> createService({
    required String name,
    required double price,
    int? durationMinutes,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'price': price,
      };
      if (durationMinutes != null) {
        data['durationMinutes'] = durationMinutes;
      }
      final response = await _dio.post(
        '/barber/services',
        data: data,
      );
      return ServiceDto.fromJson(response.data);
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<ServiceDto> updateService({
    required int id,
    String? name,
    double? price,
    int? durationMinutes,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (price != null) body['price'] = price;
      if (durationMinutes != null) body['durationMinutes'] = durationMinutes;
      if (isActive != null) body['isActive'] = isActive;

      final response = await _dio.put(
        '/barber/services/$id',
        data: body,
      );
      return ServiceDto.fromJson(response.data);
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteService(int id) async {
    try {
      await _dio.delete('/barber/services/$id');
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}

final serviceServiceProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(authNotifierProvider);
  
  // Si está en modo demo, usar servicio mock
  if (authState.isDemoMode) {
    return MockServiceService();
  }
  
  final dio = ref.watch(dioProvider);
  return ServiceService(dio);
});

