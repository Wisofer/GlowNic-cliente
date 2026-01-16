import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../providers/pending_appointments_provider.dart';
import '../../providers/dashboard_refresh_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../utils/snackbar_helper.dart';

/// Handler centralizado para procesar notificaciones y actualizar la UI
class NotificationHandler {
  static Ref? _ref;
  
  /// Inicializar el handler con el ref
  static void initialize(Ref ref) {
    _ref = ref;
  }
  
  /// Procesar notificación de tipo "appointment" cuando la app está en foreground
  static void handleAppointmentNotification(RemoteMessage message) {
    final data = message.data;
    final type = (data['type'] ?? '').toString().toLowerCase();
    
    if (type != 'appointment') {
      return;
    }
    
    // Obtener información de la cita
    final clientName = data['clientName'] ?? data['data']?['clientName'] ?? 'Cliente';
    final date = data['date'] ?? data['data']?['date'] ?? '';
    final time = data['time'] ?? data['data']?['time'] ?? '';
    
    // Refrescar contador de citas pendientes y badge de notificaciones
    if (_ref != null) {
      try {
        _ref!.read(pendingAppointmentsProvider.notifier).refresh();
        _ref!.read(dashboardRefreshProvider.notifier).refresh();
        // ✅ Actualizar badge de notificaciones automáticamente
        _ref!.read(notificationsProvider.notifier).refresh();
      } catch (e) {
        // Error silencioso
      }
    }
    
    // Mostrar snackbar discreto
    _showAppointmentSnackbar(clientName, date, time);
  }
  
  /// Mostrar snackbar cuando llega una notificación de cita
  static void _showAppointmentSnackbar(String clientName, String date, String time) {
    try {
      SnackbarHelper.showInfo(
        title: 'Nueva cita recibida',
        message: '$clientName agendó una cita para el $date a las $time',
      );
    } catch (e) {
      // Error silencioso
    }
  }
  
  /// Procesar cualquier notificación y actualizar providers necesarios
  static void handleNotification(RemoteMessage message) {
    final data = message.data;
    final type = (data['type'] ?? '').toString().toLowerCase();
    
    switch (type) {
      case 'appointment':
        // handleAppointmentNotification ya actualiza el badge, no duplicar
        handleAppointmentNotification(message);
        break;
      default:
        // Para otros tipos de notificaciones, solo actualizar badge
        if (_ref != null) {
          try {
            _ref!.read(notificationsProvider.notifier).refresh();
          } catch (e) {
            // Error silencioso
          }
        }
        break;
    }
  }
}
