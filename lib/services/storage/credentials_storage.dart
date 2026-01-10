import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para guardar y cargar credenciales de login
class CredentialsStorage {
  final _secureStorage = const FlutterSecureStorage();
  static const _passwordKey = 'saved_password';
  static const _usernameKey = 'saved_username';
  static const _rememberCredentialsKey = 'remember_credentials';

  /// Guarda las credenciales
  Future<void> saveCredentials(String username, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usernameKey, username);
      await _secureStorage.write(key: _passwordKey, value: password);
      await prefs.setBool(_rememberCredentialsKey, true);
    } catch (e) {
      // Ignorar errores de almacenamiento
    }
  }

  /// Carga las credenciales guardadas
  Future<Map<String, String?>> loadCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_rememberCredentialsKey) ?? false;
      
      if (!remember) {
        return {'username': null, 'password': null};
      }

      final username = prefs.getString(_usernameKey);
      final password = await _secureStorage.read(key: _passwordKey);
      
      return {
        'username': username,
        'password': password,
      };
    } catch (e) {
      return {'username': null, 'password': null};
    }
  }

  /// Elimina las credenciales guardadas
  Future<void> clearCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_usernameKey);
      await _secureStorage.delete(key: _passwordKey);
      await prefs.setBool(_rememberCredentialsKey, false);
    } catch (e) {
      // Ignorar errores
    }
  }

  /// Verifica si hay credenciales guardadas
  Future<bool> hasSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberCredentialsKey) ?? false;
    } catch (e) {
      return false;
    }
  }
}


