import 'package:dio/dio.dart';
import 'package:system_movil/services/storage/token_storage.dart';
import 'package:system_movil/models/user_profile.dart';

class _Endpoints {
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String verificar = '/auth/verificar';
}

class AuthApi {
  final Dio _dio;
  final TokenStorage _storage;

  AuthApi(this._dio, this._storage);

  /// POST /api/movil/auth/login
  /// Body: { "usuario": "string", "contrasena": "string" }
  Future<Map<String, dynamic>> login(String usuario, String contrasena) async {
    try {
      final res = await _dio.post(
        _Endpoints.login,
        data: {
          'usuario': usuario,
          'contrasena': contrasena,
        },
      );
      
      // Verificar respuesta exitosa
      if (res.data['success'] == true) {
        final data = res.data['data'];
        if (data == null) {
          throw Exception('Respuesta inesperada del servidor');
        }
        
        // Guardar token (esta API no tiene refreshToken)
        final token = data['token'];
        await _storage.saveTokens(token, token); // Usamos el mismo token como refresh
        
        // Retornar datos del usuario
        return data['usuario'] ?? {};
      } else {
        final message = res.data['message'] ?? 'Error de autenticación';
        throw Exception(message);
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      
      if (status == 401) {
        final message = body?['message'] ?? 'Credenciales inválidas';
        throw Exception(message);
      } else if (status == 400) {
        final message = body?['message'] ?? 'Datos inválidos';
        throw Exception(message);
      }
      
      throw Exception('Error de conexión. Intenta nuevamente.');
    }
  }

  /// GET /api/movil/auth/me
  /// Obtener usuario actual
  Future<UserProfile> getProfile() async {
    try {
      final accessToken = await _storage.getAccessToken();
      if (accessToken == null) {
        throw Exception("No hay sesión activa");
      }

      final res = await _dio.get(
        _Endpoints.me,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (res.data['success'] == true) {
        final data = res.data['data'];
        if (data == null) {
          throw Exception('Respuesta inesperada');
        }
        
        // Mapear respuesta al modelo UserProfile
        return UserProfile(
          userId: data['id']?.toString() ?? '',
          userName: data['nombreUsuario'] ?? '',
          role: data['rol'] ?? '',
          nombre: data['nombreCompleto'] ?? data['nombreUsuario'] ?? '',
          apellido: '',
          email: data['nombreUsuario'],
        );
      } else {
        final message = res.data['message'] ?? 'Error obteniendo perfil';
        throw Exception(message);
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      
      if (status == 401) {
        throw Exception('Sesión expirada. Inicia sesión nuevamente.');
      }
      
      throw Exception('Error de conexión. Intenta nuevamente.');
    }
  }

  /// GET /api/movil/auth/verificar
  /// Verificar si el token es válido
  Future<bool> verificarToken() async {
    try {
      final accessToken = await _storage.getAccessToken();
      if (accessToken == null) return false;

      final res = await _dio.get(
        _Endpoints.verificar,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      return res.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Cerrar sesión (limpiar tokens locales)
  Future<void> revoke() async {
    await _storage.clear();
  }

  /// Refresh token - Esta API no lo soporta, solo limpiamos
  Future<void> refreshToken() async {
    // Esta API no tiene refresh token, el token dura 7 días
    // Si expira, el usuario debe hacer login de nuevo
    throw Exception('Token expirado. Inicia sesión nuevamente.');
  }
}
