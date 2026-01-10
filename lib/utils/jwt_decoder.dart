import 'dart:convert';

class JwtDecoder {
  static String? getUserId(String? token) {
    if (token == null) return null;
    
    try {
      // Dividir el JWT en sus partes
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      // Decodificar el payload (segunda parte)
      final payload = parts[1];
      
      // Agregar padding si es necesario
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      
      final Map<String, dynamic> payloadMap = json.decode(decoded);
      
      // Extraer el userId del claim 'sub' (subject)
      return payloadMap['sub'] as String?;
    } catch (e) {
      return null;
    }
  }

  static String? getUserName(String? token) {
    if (token == null) return null;
    
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      
      final Map<String, dynamic> payloadMap = json.decode(decoded);
      
      // Extraer el userName del claim 'name'
      return payloadMap['name'] as String?;
    } catch (e) {
      return null;
    }
  }

  static String? getUserRole(String? token) {
    if (token == null) return null;
    
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      
      final Map<String, dynamic> payloadMap = json.decode(decoded);
      
      
      // Buscar el rol en diferentes claims posibles
      // 1. Claim estándar simple
      String? role = payloadMap['role'] as String?;
      if (role != null) {
        return role;
      }
      
      // 2. Claim con mayúscula
      role = payloadMap['Role'] as String?;
      if (role != null) {
        return role;
      }
      
      // 3. Claim de Microsoft (el que usa el backend)
      role = payloadMap['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] as String?;
      if (role != null) {
        return role;
      }
      
      // 4. Otros claims posibles
      role = payloadMap['roles'] as String?;
      if (role != null) {
        return role;
      }
      
      role = payloadMap['userRole'] as String?;
      if (role != null) {
        return role;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Verifica si el token está expirado
  /// Retorna true si el token está expirado o es inválido
  static bool isTokenExpired(String? token) {
    if (token == null) return true;
    
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      
      final Map<String, dynamic> payloadMap = json.decode(decoded);
      
      // El claim 'exp' contiene la fecha de expiración en segundos (Unix timestamp)
      final exp = payloadMap['exp'];
      if (exp == null) return true;
      
      // Convertir a DateTime
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      
      // Si la expiración es antes de ahora, el token está expirado
      // También consideramos expirado si expira en menos de 1 minuto (margen de seguridad)
      return expirationDate.isBefore(now.add(const Duration(minutes: 1)));
    } catch (e) {
      // Si hay error al decodificar, considerar expirado
      return true;
    }
  }

  /// Obtiene la fecha de expiración del token
  static DateTime? getExpirationDate(String? token) {
    if (token == null) return null;
    
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      
      final Map<String, dynamic> payloadMap = json.decode(decoded);
      
      final exp = payloadMap['exp'];
      if (exp == null) return null;
      
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (e) {
      return null;
    }
  }
}
