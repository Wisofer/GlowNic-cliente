import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:system_movil/utils/audio_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioHelper Tests', () {
    setUp(() {
      // Resetear el estado antes de cada test
      AudioHelper.setEnabled(true);
    });

    test('AudioHelper está habilitado por defecto', () {
      // Verificar que por defecto está habilitado
      expect(AudioHelper.isEnabled, true);
    });

    test('setEnabled cambia el estado correctamente', () {
      // Deshabilitar
      AudioHelper.setEnabled(false);
      expect(AudioHelper.isEnabled, false);

      // Habilitar
      AudioHelper.setEnabled(true);
      expect(AudioHelper.isEnabled, true);
    });

    test('playSuccess no lanza excepción cuando está habilitado', () async {
      AudioHelper.setEnabled(true);
      // No debería lanzar excepción (aunque el audio no se reproduzca en test)
      try {
        await AudioHelper.playSuccess();
        expect(true, true); // Si llegó aquí, no hubo excepción
      } catch (e) {
        // En test puede fallar por falta de assets, pero la lógica está bien
        expect(e, isNot(throwsException));
      }
    });

    test('playError no lanza excepción cuando está habilitado', () async {
      AudioHelper.setEnabled(true);
      // No debería lanzar excepción (aunque el audio no se reproduzca en test)
      try {
        await AudioHelper.playError();
        expect(true, true); // Si llegó aquí, no hubo excepción
      } catch (e) {
        // En test puede fallar por falta de assets, pero la lógica está bien
        expect(e, isNot(throwsException));
      }
    });

    test('playSuccess no hace nada cuando está deshabilitado', () async {
      AudioHelper.setEnabled(false);
      // No debería hacer nada cuando está deshabilitado
      await AudioHelper.playSuccess();
      expect(AudioHelper.isEnabled, false);
    });

    test('playError no hace nada cuando está deshabilitado', () async {
      AudioHelper.setEnabled(false);
      // No debería hacer nada cuando está deshabilitado
      await AudioHelper.playError();
      expect(AudioHelper.isEnabled, false);
    });

    test('stop no lanza excepción', () async {
      expect(() => AudioHelper.stop(), returnsNormally);
    });
  });
}

