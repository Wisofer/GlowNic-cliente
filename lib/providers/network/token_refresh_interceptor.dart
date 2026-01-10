import 'dart:async';
import 'package:dio/dio.dart';
import '../../services/storage/token_storage.dart';
import '../../services/api/api_config.dart';

/// Interceptor que maneja el refresh automático de tokens cuando se recibe un 401
/// Similar al comportamiento de Facebook, LinkedIn, etc.
class TokenRefreshInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final Dio _refreshDio; // Dio separado para evitar loops infinitos al hacer refresh
  Dio? _originalDio; // Dio original para reintentar peticiones con todos los interceptores
  bool _isRefreshing = false;
  final List<({RequestOptions options, Completer<Response> completer})> _failedQueue = [];

  TokenRefreshInterceptor(this._tokenStorage)
      : _refreshDio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: ApiConfig.connectTimeout,
            receiveTimeout: ApiConfig.receiveTimeout,
            headers: ApiConfig.defaultHeaders,
          ),
        );

  /// Establece el Dio original para poder reintentar peticiones con todos los interceptores
  void setOriginalDio(Dio dio) {
    _originalDio = dio;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Solo manejar errores 401 y que NO sean del endpoint de refresh
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/refresh')) {
      
      // Si ya hay un refresh en proceso, encolar esta petición
      if (_isRefreshing) {
        final completer = Completer<Response>();
        _failedQueue.add((options: err.requestOptions, completer: completer));

        try {
          final response = await completer.future;
          handler.resolve(response);
        } catch (e) {
          handler.reject(err);
        }
        return;
      }

      // Iniciar proceso de refresh
      _isRefreshing = true;

      try {
        // Intentar refrescar el token
        final newTokens = await _refreshToken();

        if (newTokens != null) {
          // Guardar nuevos tokens
          await _tokenStorage.saveTokens(
            newTokens['accessToken']!,
            newTokens['refreshToken']!,
          );

          // Procesar cola de peticiones fallidas
          final dioToUse = _originalDio ?? _refreshDio;
          for (var item in _failedQueue) {
            item.options.headers['Authorization'] = 'Bearer ${newTokens['accessToken']}';
            try {
              final response = await dioToUse.fetch(item.options);
              item.completer.complete(response);
            } catch (e) {
              item.completer.completeError(e);
            }
          }
          _failedQueue.clear();

          // Reintentar petición original con nuevo token
          err.requestOptions.headers['Authorization'] = 'Bearer ${newTokens['accessToken']}';
          final response = await dioToUse.fetch(err.requestOptions);
          handler.resolve(response);
        } else {
          // Refresh falló, limpiar tokens y pasar el error
          await _clearTokensAndReject(err, handler);
        }
      } catch (e) {
        // Error al refrescar, limpiar tokens y rechazar todas las peticiones en cola
        await _clearTokensAndReject(err, handler);
      } finally {
        _isRefreshing = false;
      }
    } else {
      // No es un 401 o es del endpoint de refresh, pasar al siguiente handler
      handler.next(err);
    }
  }

  /// Intenta refrescar el token usando el refresh token
  Future<Map<String, String>?> _refreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }

      final response = await _refreshDio.post(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        // El backend devuelve: { "token": "...", "refreshToken": "...", "user": {...}, "role": "..." }
        final newToken = response.data['token'] as String?;
        final newRefreshToken = response.data['refreshToken'] as String?;
        
        if (newToken != null && newToken.isNotEmpty) {
          return {
            'accessToken': newToken,
            'refreshToken': newRefreshToken ?? newToken, // Si no hay nuevo refreshToken, usar el mismo
          };
        }
      }

      return null;
    } catch (e) {
      // Error al refrescar (token inválido, expirado, etc.)
      return null;
    }
  }

  /// Limpia los tokens y rechaza todas las peticiones pendientes
  Future<void> _clearTokensAndReject(
    DioException originalError,
    ErrorInterceptorHandler handler,
  ) async {
    // Limpiar tokens
    await _tokenStorage.clear();

    // Rechazar todas las peticiones en cola
    for (var item in _failedQueue) {
      item.completer.completeError(originalError);
    }
    _failedQueue.clear();

    // Rechazar la petición original
    handler.reject(originalError);
  }
}

