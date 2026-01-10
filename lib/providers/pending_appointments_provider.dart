import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment.dart';
import '../services/api/appointment_service.dart';
import '../services/api/employee_appointment_service.dart';
import '../providers/auth_provider.dart';
import '../utils/jwt_decoder.dart';

/// Provider que mantiene el contador de citas pendientes
class PendingAppointmentsNotifier extends StateNotifier<int> {
  PendingAppointmentsNotifier(this.ref) : super(0) {
    _loadPendingCount();
  }

  final Ref ref;

  /// Obtener el rol del usuario actual
  String? _getUserRole() {
    final authState = ref.read(authNotifierProvider);
    final role = authState.userProfile?.role;
    final token = authState.userToken;
    
    if (role != null) {
      return role;
    }
    
    if (token != null) {
      return JwtDecoder.getUserRole(token);
    }
    
    return null;
  }

  /// Cargar el contador de citas pendientes
  Future<void> _loadPendingCount() async {
    try {
      List<AppointmentDto> appointments;
      final role = _getUserRole();
      
      if (role == 'Employee') {
        final service = ref.read(employeeAppointmentServiceProvider);
        appointments = await service.getAppointments(status: 'Pending');
      } else {
        final service = ref.read(appointmentServiceProvider);
        appointments = await service.getAppointments(status: 'Pending');
      }
      
      state = appointments.length;
    } catch (e) {
      // Si hay error, mantener el contador en 0 o el último valor conocido
      // No actualizar el estado si hay error para no perder el contador anterior
    }
  }

  /// Actualizar el contador (llamar manualmente cuando sea necesario)
  Future<void> refresh() async {
    await _loadPendingCount();
  }

  /// Incrementar el contador manualmente (útil cuando se crea una nueva cita pendiente)
  void increment() {
    state = state + 1;
  }

  /// Decrementar el contador manualmente (útil cuando se confirma/cancela una cita)
  void decrement() {
    if (state > 0) {
      state = state - 1;
    }
  }

  /// Resetear el contador
  void reset() {
    state = 0;
  }
}

/// Provider del notifier de citas pendientes
final pendingAppointmentsProvider = StateNotifierProvider<PendingAppointmentsNotifier, int>((ref) {
  return PendingAppointmentsNotifier(ref);
});

