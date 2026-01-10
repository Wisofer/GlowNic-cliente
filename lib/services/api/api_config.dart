class ApiConfig {
  // URL base del backend - API GlowNic
  static const String baseUrl = 'https://glownic.encuentrame.org/api';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers por defecto
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Requested-With': 'XMLHttpRequest', // Algunos servidores esperan esto para identificar requests AJAX
  };
}
