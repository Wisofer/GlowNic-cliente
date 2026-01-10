/// Utilidades para formatear valores monetarios redondeados a enteros
/// Todos los valores monetarios se redondean a números enteros sin decimales
/// Formato nicaragüense: separadores de miles con coma (21,000)
class MoneyFormatter {
  // Formateador de números con separadores de miles (formato nicaragüense)
  // Formato personalizado: comas para miles, sin decimales
  static String _formatWithCommas(int value) {
    if (value < 1000) {
      return value.toString();
    }
    
    final String valueStr = value.toString();
    final int length = valueStr.length;
    final StringBuffer buffer = StringBuffer();
    
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(valueStr[i]);
    }
    
    return buffer.toString();
  }
  /// Redondea un valor double a entero
  /// Ejemplo: 120.76 -> 121, 120.24 -> 120
  static int roundToInt(double value) {
    return value.round();
  }

  /// Convierte un valor double a double redondeado
  /// Útil para cálculos internos
  static double roundToDouble(double value) {
    return value.round().toDouble();
  }

  /// Formatea un número con separadores de miles (formato nicaragüense)
  /// Ejemplo: 500 -> "500", 1500 -> "1,500", 21000 -> "21,000", 1234567 -> "1,234,567"
  static String formatWithThousands(int value) {
    return _formatWithCommas(value);
  }

  /// Formatea un valor como string sin decimales con separadores de miles
  /// Ejemplo: 120.76 -> "121", 1200.24 -> "1,200", 21000 -> "21,000"
  static String format(double value) {
    final rounded = roundToInt(value);
    return formatWithThousands(rounded);
  }

  /// Formatea un valor con símbolo de córdobas (C$) y separadores de miles
  /// Ejemplo: 120.76 -> "C$121", 1200.24 -> "C$1,200", 21000 -> "C$21,000"
  static String formatCordobas(double value) {
    return 'C\$${format(value)}';
  }

  /// Formatea un valor con símbolo de dólares ($)
  /// Los dólares mantienen decimales (NO se redondean)
  /// Ejemplo: 50.76 -> "$50.76", 21.5 -> "$21.50"
  static String formatDolares(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  /// Formatea un valor con símbolo según la moneda
  /// moneda puede ser "C$", "$", o "Ambos"
  /// Córdobas: se redondean a enteros
  /// Dólares: mantienen 2 decimales
  static String formatByMoneda(double value, String moneda) {
    if (moneda == r'$' || moneda == 'USD') {
      return formatDolares(value);
    }
    return formatCordobas(value);
  }

  /// Parsea un string a double y lo redondea
  /// Útil para inputs de usuario
  static double? parseAndRound(String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = double.tryParse(value);
    if (parsed == null) return null;
    return roundToDouble(parsed);
  }

  /// Formatea para mostrar tipo de cambio (puede tener decimales en TC)
  /// Pero para valores monetarios siempre se redondea
  static String formatTipoCambio(double value) {
    // El tipo de cambio se puede mostrar con 2 decimales
    // pero cuando se usa en cálculos se redondea el resultado
    return value.toStringAsFixed(2);
  }
}
