import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/auth.dart';
import '../../providers/providers.dart';
import '../../services/storage/token_storage.dart';

class AuthService {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  AuthService(this._dio, this._tokenStorage);

  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      
      
      final loginResponse = LoginResponse.fromJson(response.data);
      
      
      // Guardar ambos tokens (access y refresh)
      await _tokenStorage.saveTokens(loginResponse.token, loginResponse.refreshToken);
      
      // Verificar que se guardó correctamente
      final savedToken = await _tokenStorage.getAccessToken();
      if (savedToken != null && savedToken == loginResponse.token) {
      } else {
      }
      
      return loginResponse;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credenciales inválidas');
      }
      throw Exception(e.response?.data['message'] ?? 'Error en el login');
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(dioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthService(dio, tokenStorage);
});

