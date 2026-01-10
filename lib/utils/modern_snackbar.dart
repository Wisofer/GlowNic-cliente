import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../main_theme.dart';
import 'snackbar_helper.dart';

/// Utilidades para mostrar SnackBars modernos con iconos y animaciones
/// Usando la paleta de colores personalizada de GlowNic
class ModernSnackBar {
  
  /// Mostrar SnackBar completamente personalizado con colores del tema
  static void showCustom(
    BuildContext context, {
    required String title,
    required String message,
    required Color backgroundColor,
    required Color iconColor,
    required IconData icon,
  }) {
    // 🔒 SEGURIDAD: Capturar el ScaffoldMessengerState cuando se crea el SnackBar
    // Esto evita el error "Looking up a deactivated widget's ancestor is unsafe"
    ScaffoldMessengerState? scaffoldMessenger;
    
    try {
      if (context.mounted) {
        scaffoldMessenger = ScaffoldMessenger.of(context);
      }
    } catch (e) {
      // Si falla, usar el GlobalKey como fallback
      scaffoldMessenger = SnackbarHelper.scaffoldMessengerKey.currentState;
    }
    
    // Si no hay scaffoldMessenger disponible, no mostrar el SnackBar
    if (scaffoldMessenger == null) {
      debugPrint('⚠️ [SNACKBAR] No se pudo mostrar snackbar: $title - $message');
      return;
    }
    
    scaffoldMessenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              // Icono con fondo circular
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Contenido del mensaje
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: SystemMovilTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: SystemMovilTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              // Botón de cerrar - 🔒 SEGURIDAD: Usar GlobalKey directamente para evitar errores
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // 🔒 SEGURIDAD: Usar GlobalKey directamente para evitar "deactivated widget" error
                    // Esto es más seguro porque no depende del context que puede estar desactivado
                    try {
                      final messenger = SnackbarHelper.scaffoldMessengerKey.currentState;
                      if (messenger != null) {
                        messenger.hideCurrentSnackBar();
                      } else {
                        // Fallback: intentar con el scaffoldMessenger capturado si el GlobalKey falla
                        if (scaffoldMessenger != null) {
                          try {
                            scaffoldMessenger.hideCurrentSnackBar();
                          } catch (_) {
                            // Si todo falla, ignorar silenciosamente (el SnackBar se cerrará automáticamente)
                          }
                        }
                      }
                    } catch (e) {
                      // Si todo falla, ignorar silenciosamente
                      // El SnackBar se cerrará automáticamente después de su duración
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  splashColor: Colors.white.withOpacity(0.1),
                  highlightColor: Colors.white.withOpacity(0.05),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.close_circle,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Mostrar SnackBar de éxito con colores personalizados
  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showCustom(
      context,
      title: title,
      message: message,
      backgroundColor: SystemMovilColors.success,
      iconColor: Colors.white,
      icon: Iconsax.tick_circle,
    );
  }

  /// Mostrar SnackBar de error con colores personalizados
  static void showError(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showCustom(
      context,
      title: title,
      message: message,
      backgroundColor: SystemMovilColors.error,
      iconColor: Colors.white,
      icon: Iconsax.close_circle,
    );
  }

  /// Mostrar SnackBar de advertencia con colores personalizados
  static void showWarning(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showCustom(
      context,
      title: title,
      message: message,
      backgroundColor: SystemMovilColors.warning,
      iconColor: Colors.white,
      icon: Iconsax.warning_2,
    );
  }

  /// Mostrar SnackBar de información con colores personalizados
  static void showInfo(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showCustom(
      context,
      title: title,
      message: message,
      backgroundColor: SystemMovilColors.info,
      iconColor: Colors.white,
      icon: Iconsax.info_circle,
    );
  }

  /// Mostrar SnackBar de ayuda con colores personalizados
  static void showHelp(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showCustom(
      context,
      title: title,
      message: message,
      backgroundColor: SystemMovilColors.primary,
      iconColor: Colors.white,
      icon: Iconsax.message_question,
    );
  }
}
