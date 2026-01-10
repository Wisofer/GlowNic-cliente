import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'jwt_decoder.dart';

class RoleHelper {
  /// Verifica si el usuario actual es un Barber (dueño)
  static bool isBarber(WidgetRef ref) {
    final authState = ref.read(authNotifierProvider);
    final role = authState.userProfile?.role;
    final token = authState.userToken;
    
    if (role != null) {
      return role == 'Barber';
    }
    
    // Si no hay rol en el perfil, intentar desde el token
    if (token != null) {
      final tokenRole = JwtDecoder.getUserRole(token);
      return tokenRole == 'Barber';
    }
    
    return false;
  }

  /// Verifica si el usuario actual es un Employee (trabajador)
  static bool isEmployee(WidgetRef ref) {
    final authState = ref.read(authNotifierProvider);
    final role = authState.userProfile?.role;
    final token = authState.userToken;
    
    if (role != null) {
      return role == 'Employee';
    }
    
    // Si no hay rol en el perfil, intentar desde el token
    if (token != null) {
      final tokenRole = JwtDecoder.getUserRole(token);
      return tokenRole == 'Employee';
    }
    
    return false;
  }

  /// Obtiene el rol del usuario actual
  static String? getRole(WidgetRef ref) {
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
}
