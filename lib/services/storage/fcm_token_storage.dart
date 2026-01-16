import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento seguro del token FCM
class FcmTokenStorage {
  final _storage = FlutterSecureStorage();
  static const _fcmKey = 'fcm_token';

  /// Guardar token FCM
  Future<void> saveFcmToken(String token) async {
    await _storage.write(key: _fcmKey, value: token);
  }

  /// Obtener token FCM guardado
  Future<String?> getFcmToken() => _storage.read(key: _fcmKey);

  /// Eliminar token FCM (útil para logout)
  Future<void> clear() async {
    await _storage.delete(key: _fcmKey);
  }
}
