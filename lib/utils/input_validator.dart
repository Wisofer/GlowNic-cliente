/// Utilidades para validación y sanitización de inputs del usuario
class InputValidator {
  // Límites de longitud
  static const int maxTitleLength = 200;
  static const int maxDescriptionLength = 5000;
  static const int maxNameLength = 100;
  static const int maxEmailLength = 254;
  static const int maxPhoneLength = 20;
  static const int maxUrlLength = 2048;
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;

  /// Validar y sanitizar texto (eliminar espacios extras, trim)
  static String sanitizeText(String? text) {
    if (text == null) return '';
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Validar longitud de texto
  static String? validateLength(String? value, {
    required int maxLength,
    int? minLength,
    required String fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return minLength != null && minLength > 0
          ? '$fieldName es requerido'
          : null;
    }

    final sanitized = sanitizeText(value);
    
    if (minLength != null && sanitized.length < minLength) {
      return '$fieldName debe tener al menos $minLength caracteres';
    }
    
    if (sanitized.length > maxLength) {
      return '$fieldName no puede tener más de $maxLength caracteres';
    }
    
    return null;
  }

  /// Validar email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }

    final sanitized = sanitizeText(value);
    
    if (sanitized.length > maxEmailLength) {
      return 'El email no puede tener más de $maxEmailLength caracteres';
    }

    // Regex simplificado pero válido para emails
    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    );

    if (!emailRegex.hasMatch(sanitized)) {
      return 'Ingresa un email válido';
    }

    return null;
  }

  /// Validar teléfono
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Teléfono es opcional
    }

    final sanitized = sanitizeText(value).replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (sanitized.length > maxPhoneLength) {
      return 'El teléfono no puede tener más de $maxPhoneLength caracteres';
    }

    // Validar que solo contenga números y opcionalmente +
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    
    if (!phoneRegex.hasMatch(sanitized)) {
      return 'Ingresa un teléfono válido (solo números, 7-15 dígitos)';
    }

    return null;
  }

  /// Validar URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL es opcional
    }

    final sanitized = sanitizeText(value);
    
    if (sanitized.length > maxUrlLength) {
      return 'La URL no puede tener más de $maxUrlLength caracteres';
    }

    // Validar formato de URL
    try {
      final uri = Uri.parse(sanitized);
      
      // Solo permitir HTTP y HTTPS
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return 'La URL debe comenzar con http:// o https://';
      }
      
      // Validar que tenga host
      if (uri.host.isEmpty) {
        return 'La URL debe tener un dominio válido';
      }
      
      return null;
    } catch (e) {
      return 'Ingresa una URL válida';
    }
  }

  /// Validar contraseña
  static String? validatePassword(String? value, {bool isRequired = true}) {
    if (value == null || value.isEmpty) {
      return isRequired ? 'La contraseña es requerida' : null;
    }

    if (value.length < minPasswordLength) {
      return 'La contraseña debe tener al menos $minPasswordLength caracteres';
    }
    
    if (value.length > maxPasswordLength) {
      return 'La contraseña no puede tener más de $maxPasswordLength caracteres';
    }

    return null;
  }

  /// Validar título de trabajo
  static String? validateJobTitle(String? value) {
    return validateLength(
      value,
      maxLength: maxTitleLength,
      minLength: 3,
      fieldName: 'El título',
    );
  }

  /// Validar descripción de trabajo
  static String? validateJobDescription(String? value) {
    return validateLength(
      value,
      maxLength: maxDescriptionLength,
      minLength: 10,
      fieldName: 'La descripción',
    );
  }

  /// Validar nombre
  static String? validateName(String? value, {String fieldName = 'El nombre'}) {
    return validateLength(
      value,
      maxLength: maxNameLength,
      minLength: 2,
      fieldName: fieldName,
    );
  }

  /// Validar que al menos uno de dos campos esté lleno
  static String? validateAtLeastOne({
    required String? value1,
    required String? value2,
    required String fieldName1,
    required String fieldName2,
  }) {
    final v1 = sanitizeText(value1);
    final v2 = sanitizeText(value2);
    
    if (v1.isEmpty && v2.isEmpty) {
      return 'Debes completar al menos $fieldName1 o $fieldName2';
    }
    
    return null;
  }

  /// Sanitizar texto para prevenir XSS básico
  static String sanitizeForXSS(String? text) {
    if (text == null) return '';
    
    return text
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  /// Validar DNI/NIE (formato español básico)
  static String? validateDNI(String? value) {
    if (value == null || value.isEmpty) {
      return null; // DNI es opcional
    }

    final sanitized = sanitizeText(value).replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
    
    // DNI español: 8 dígitos + 1 letra
    if (sanitized.length == 9) {
      final dniRegex = RegExp(r'^[0-9]{8}[A-Z]$');
      if (dniRegex.hasMatch(sanitized)) {
        return null;
      }
    }
    
    // NIE español: X/Y/Z + 7 dígitos + 1 letra
    if (sanitized.length == 9) {
      final nieRegex = RegExp(r'^[XYZ][0-9]{7}[A-Z]$');
      if (nieRegex.hasMatch(sanitized)) {
        return null;
      }
    }
    
    return 'Ingresa un DNI/NIE válido (8 dígitos + letra o X/Y/Z + 7 dígitos + letra)';
  }
}

