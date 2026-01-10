import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Helper para reproducir sonidos de éxito y error en la aplicación
class AudioHelper {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isEnabled = true; // Por defecto habilitado

  /// Habilitar o deshabilitar los sonidos
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Verificar si los sonidos están habilitados
  static bool get isEnabled => _isEnabled;

  /// Reproducir sonido de éxito
  static Future<void> playSuccess() async {
    if (!_isEnabled) return;
    
    try {
      await _player.play(AssetSource('audios/success.mp3'));
    } catch (e) {
      // Silenciar errores de audio en producción
      if (kDebugMode) {
        debugPrint('Error al reproducir audio de éxito: $e');
      }
    }
  }

  /// Reproducir sonido de error
  static Future<void> playError() async {
    if (!_isEnabled) return;
    
    try {
      await _player.play(AssetSource('audios/error.mp3'));
    } catch (e) {
      // Silenciar errores de audio en producción
      if (kDebugMode) {
        debugPrint('Error al reproducir audio de error: $e');
      }
    }
  }

  /// Detener cualquier audio que se esté reproduciendo
  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      // Ignorar errores al detener
    }
  }

  /// Liberar recursos (llamar al cerrar la app)
  static Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (e) {
      // Ignorar errores al liberar
    }
  }
}

