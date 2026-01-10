import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  /// Reproducir sonido de éxito
  Future<void> playSuccess() async {
    try {
      await _player.play(AssetSource('audios/success.mp3'));
    } catch (e) {
      // Silenciar errores de audio
    }
  }

  /// Reproducir sonido de error
  Future<void> playError() async {
    try {
      await _player.play(AssetSource('audios/error.mp3'));
    } catch (e) {
      // Silenciar errores de audio
    }
  }

  /// Liberar recursos
  void dispose() {
    _player.dispose();
  }
}

// Provider
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

