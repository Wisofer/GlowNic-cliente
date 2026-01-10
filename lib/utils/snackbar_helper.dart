import 'package:flutter/material.dart';
import 'modern_snackbar.dart';

/// Helper centralizado para mostrar snackbars con fallback a GlobalKey
/// Evita crashes cuando el context está desmontado
class SnackbarHelper {
  // GlobalKey para acceso cross-route
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Muestra un snackbar de éxito con fallback seguro
  static void showSuccess({
    BuildContext? context,
    required String title,
    required String message,
  }) {
    _showSnackbar(
      context: context,
      title: title,
      message: message,
      type: SnackbarType.success,
    );
  }

  /// Muestra un snackbar de error con fallback seguro
  static void showError({
    BuildContext? context,
    required String title,
    required String message,
  }) {
    _showSnackbar(
      context: context,
      title: title,
      message: message,
      type: SnackbarType.error,
    );
  }

  /// Muestra un snackbar de advertencia con fallback seguro
  static void showWarning({
    BuildContext? context,
    required String title,
    required String message,
  }) {
    _showSnackbar(
      context: context,
      title: title,
      message: message,
      type: SnackbarType.warning,
    );
  }

  /// Muestra un snackbar de información con fallback seguro
  static void showInfo({
    BuildContext? context,
    required String title,
    required String message,
  }) {
    _showSnackbar(
      context: context,
      title: title,
      message: message,
      type: SnackbarType.info,
    );
  }

  /// Método interno para mostrar snackbar con fallback
  static void _showSnackbar({
    BuildContext? context,
    required String title,
    required String message,
    required SnackbarType type,
  }) {
    // Prioridad 1: Usar context si está disponible y montado
    if (context != null && context.mounted) {
      try {
        switch (type) {
          case SnackbarType.success:
            ModernSnackBar.showSuccess(context, title: title, message: message);
            break;
          case SnackbarType.error:
            ModernSnackBar.showError(context, title: title, message: message);
            break;
          case SnackbarType.warning:
            ModernSnackBar.showWarning(context, title: title, message: message);
            break;
          case SnackbarType.info:
            ModernSnackBar.showInfo(context, title: title, message: message);
            break;
        }
        return;
      } catch (e) {
        // Si falla con context, intentar con GlobalKey
      }
    }

    // Prioridad 2: Usar GlobalKey como fallback
    final scaffoldMessenger = scaffoldMessengerKey.currentState;
    if (scaffoldMessenger != null) {
      try {
        final snackBar = _buildSnackBar(title, message, type);
        scaffoldMessenger.showSnackBar(snackBar);
        return;
      } catch (e) {
        // Si falla, no hacer nada (evitar crash)
      }
    }

    // Si todo falla, solo loguear en debug
    debugPrint('⚠️ [SNACKBAR] No se pudo mostrar snackbar: $title - $message');
  }

  /// Construye un SnackBar básico para fallback
  static SnackBar _buildSnackBar(String title, String message, SnackbarType type) {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case SnackbarType.success:
        backgroundColor = const Color(0xFFEC4899);
        icon = Icons.check_circle;
        break;
      case SnackbarType.error:
        backgroundColor = Colors.red;
        icon = Icons.error;
        break;
      case SnackbarType.warning:
        backgroundColor = Colors.orange;
        icon = Icons.warning;
        break;
      case SnackbarType.info:
        backgroundColor = Colors.blue;
        icon = Icons.info;
        break;
    }

    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
    );
  }
}

enum SnackbarType {
  success,
  error,
  warning,
  info,
}

