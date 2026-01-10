import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/help_support.dart';
import '../../providers/providers.dart';

class HelpSupportService {
  final Dio _dio;

  HelpSupportService(this._dio);

  Future<HelpSupportDto> getHelpSupport() async {
    try {
      final response = await _dio.get('/barber/help-support');
      
      // Validar que la respuesta sea JSON
      if (response.data is String && (response.data as String).trim().startsWith('<!DOCTYPE')) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'El servidor devolvió HTML. Posible sesión expirada o token inválido.',
        );
      }
      
      return HelpSupportDto.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data is String && (e.response!.data as String).contains('<!DOCTYPE')) {
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}

final helpSupportServiceProvider = Provider<HelpSupportService>((ref) {
  final dio = ref.watch(dioProvider);
  return HelpSupportService(dio);
});

