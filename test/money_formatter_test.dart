import 'package:flutter_test/flutter_test.dart';
import 'package:system_movil/utils/money_formatter.dart';

void main() {
  group('MoneyFormatter - Redondeo de Córdobas', () {
    test('roundToInt redondea correctamente valores con decimales', () {
      expect(MoneyFormatter.roundToInt(120.76), equals(121));
      expect(MoneyFormatter.roundToInt(120.24), equals(120));
      expect(MoneyFormatter.roundToInt(120.50), equals(121));
      expect(MoneyFormatter.roundToInt(120.49), equals(120));
      expect(MoneyFormatter.roundToInt(920.50), equals(921));
      expect(MoneyFormatter.roundToInt(613.33), equals(613));
    });

    test('roundToDouble redondea a double', () {
      expect(MoneyFormatter.roundToDouble(120.76), equals(121.0));
      expect(MoneyFormatter.roundToDouble(120.24), equals(120.0));
      expect(MoneyFormatter.roundToDouble(920.50), equals(921.0));
    });

    test('format retorna string sin decimales', () {
      expect(MoneyFormatter.format(120.76), equals('121'));
      expect(MoneyFormatter.format(120.24), equals('120'));
      expect(MoneyFormatter.format(920.50), equals('921'));
      expect(MoneyFormatter.format(613.33), equals('613'));
    });

    test('formatCordobas formatea con símbolo C\$ y sin decimales', () {
      expect(MoneyFormatter.formatCordobas(120.76), equals('C\$121'));
      expect(MoneyFormatter.formatCordobas(120.24), equals('C\$120'));
      expect(MoneyFormatter.formatCordobas(920.50), equals('C\$921'));
      expect(MoneyFormatter.formatCordobas(613.33), equals('C\$613'));
      expect(MoneyFormatter.formatCordobas(1000.00), equals('C\$1000'));
    });
  });

  group('MoneyFormatter - Formato de Dólares con Decimales', () {
    test('formatDolares mantiene 2 decimales', () {
      expect(MoneyFormatter.formatDolares(50.76), equals('\$50.76'));
      expect(MoneyFormatter.formatDolares(21.5), equals('\$21.50'));
      expect(MoneyFormatter.formatDolares(25.03), equals('\$25.03'));
      expect(MoneyFormatter.formatDolares(11.50), equals('\$11.50'));
      expect(MoneyFormatter.formatDolares(15.1), equals('\$15.10'));
      expect(MoneyFormatter.formatDolares(31.0), equals('\$31.00'));
      expect(MoneyFormatter.formatDolares(25.0), equals('\$25.00'));
    });

    test('formatDolares NO redondea, solo formatea', () {
      expect(MoneyFormatter.formatDolares(21.51), equals('\$21.51'));
      expect(MoneyFormatter.formatDolares(21.49), equals('\$21.49'));
      expect(MoneyFormatter.formatDolares(50.999), equals('\$51.00')); // toStringAsFixed(2) redondea visualmente
    });
  });

  group('MoneyFormatter - Formato por Moneda', () {
    test('formatByMoneda usa formato correcto según moneda', () {
      // Córdobas
      expect(MoneyFormatter.formatByMoneda(120.76, 'C\$'), equals('C\$121'));
      expect(MoneyFormatter.formatByMoneda(920.50, 'C\$'), equals('C\$921'));
      
      // Dólares
      expect(MoneyFormatter.formatByMoneda(21.5, r'$'), equals('\$21.50'));
      expect(MoneyFormatter.formatByMoneda(25.03, r'$'), equals('\$25.03'));
      expect(MoneyFormatter.formatByMoneda(50.76, 'USD'), equals('\$50.76'));
    });
  });

  group('MoneyFormatter - Parse y Redondeo', () {
    test('parseAndRound parsea y redondea córdobas', () {
      expect(MoneyFormatter.parseAndRound('120.76'), equals(121.0));
      expect(MoneyFormatter.parseAndRound('120.24'), equals(120.0));
      expect(MoneyFormatter.parseAndRound('920.50'), equals(921.0));
      expect(MoneyFormatter.parseAndRound('613.33'), equals(613.0));
    });

    test('parseAndRound retorna null para valores inválidos', () {
      expect(MoneyFormatter.parseAndRound(null), isNull);
      expect(MoneyFormatter.parseAndRound(''), isNull);
      expect(MoneyFormatter.parseAndRound('abc'), isNull);
      expect(MoneyFormatter.parseAndRound('123.abc'), isNull);
    });
  });

  group('MoneyFormatter - Tipo de Cambio', () {
    test('formatTipoCambio mantiene 2 decimales', () {
      expect(MoneyFormatter.formatTipoCambio(36.80), equals('36.80'));
      expect(MoneyFormatter.formatTipoCambio(36.32), equals('36.32'));
      expect(MoneyFormatter.formatTipoCambio(36.5), equals('36.50'));
      expect(MoneyFormatter.formatTipoCambio(36.789), equals('36.79'));
    });
  });

  group('MoneyFormatter - Casos de Prueba Reales', () {
    test('Caso 1: Pago Físico en Córdobas', () {
      final total = 920.50;
      final recibido = 1000.00;
      
      final totalRedondeado = MoneyFormatter.roundToDouble(total);
      final recibidoRedondeado = MoneyFormatter.roundToDouble(recibido);
      final vuelto = MoneyFormatter.roundToDouble(recibidoRedondeado - totalRedondeado);
      
      expect(totalRedondeado, equals(921.0));
      expect(recibidoRedondeado, equals(1000.0));
      expect(vuelto, equals(79.0));
      expect(MoneyFormatter.formatCordobas(vuelto), equals('C\$79'));
    });

    test('Caso 2: Pago Físico en Dólares', () {
      const tcVenta = 36.80;
      final totalCordobas = 920.50;
      final totalRedondeado = MoneyFormatter.roundToDouble(totalCordobas);
      
      // Equivalente en dólares (NO se redondea el dólar, solo se formatea)
      final equivalenteDolares = totalRedondeado / tcVenta; // 921 / 36.80 = 25.032608...
      final recibidoDolares = 25.50;
      
      // Conversión a córdobas para calcular vuelto
      final recibidoEnCordobas = recibidoDolares * tcVenta; // 938.40
      final vuelto = MoneyFormatter.roundToDouble(recibidoEnCordobas - totalRedondeado);
      
      expect(totalRedondeado, equals(921.0));
      expect(equivalenteDolares, closeTo(25.03, 0.01));
      expect(MoneyFormatter.formatDolares(recibidoDolares), equals('\$25.50'));
      expect(vuelto, equals(17.0)); // 938.40 - 921 = 17.40 → 17
      expect(MoneyFormatter.formatCordobas(vuelto), equals('C\$17'));
    });

    test('Caso 3: Pago Mixto (Córdobas + Dólares)', () {
      const tcVenta = 36.80;
      final totalCordobas = 920.50;
      final totalRedondeado = MoneyFormatter.roundToDouble(totalCordobas);
      
      final recibidoCordobas = MoneyFormatter.roundToDouble(500.30); // 500
      final recibidoDolares = 11.50; // NO se redondea
      
      // Total recibido en córdobas
      final totalRecibidoEnCordobas = recibidoCordobas + (recibidoDolares * tcVenta);
      final totalRecibidoRedondeado = MoneyFormatter.roundToDouble(totalRecibidoEnCordobas);
      final vuelto = MoneyFormatter.roundToDouble(totalRecibidoRedondeado - totalRedondeado);
      
      expect(totalRedondeado, equals(921.0));
      expect(recibidoCordobas, equals(500.0));
      expect(recibidoDolares, equals(11.50));
      expect(MoneyFormatter.formatDolares(recibidoDolares), equals('\$11.50'));
      expect(totalRecibidoEnCordobas, closeTo(923.20, 0.01)); // 500 + (11.50 * 36.80)
      expect(totalRecibidoRedondeado, equals(923.0));
      expect(vuelto, equals(2.0)); // 923 - 921 = 2
      expect(MoneyFormatter.formatCordobas(vuelto), equals('C\$2'));
    });

    test('Caso 4: Pago Electrónico en Dólares', () {
      const tcVenta = 36.80;
      final totalCordobas = 920.50;
      final totalRedondeado = MoneyFormatter.roundToDouble(totalCordobas);
      
      // Equivalente en dólares (para pago electrónico)
      final montoDolaresElectronico = totalRedondeado / tcVenta;
      
      expect(totalRedondeado, equals(921.0));
      expect(montoDolaresElectronico, closeTo(25.03, 0.01));
      expect(MoneyFormatter.formatDolares(montoDolaresElectronico), equals('\$25.03'));
    });
  });

  group('MoneyFormatter - Valores Extremos', () {
    test('Maneja valores muy pequeños', () {
      expect(MoneyFormatter.formatCordobas(0.49), equals('C\$0'));
      expect(MoneyFormatter.formatCordobas(0.50), equals('C\$1'));
      expect(MoneyFormatter.formatDolares(0.01), equals('\$0.01'));
    });

    test('Maneja valores muy grandes', () {
      expect(MoneyFormatter.formatCordobas(999999.76), equals('C\$1000000'));
      expect(MoneyFormatter.formatDolares(999999.99), equals('\$999999.99'));
    });

    test('Maneja valores negativos', () {
      expect(MoneyFormatter.formatCordobas(-120.76), equals('C\$-121'));
      expect(MoneyFormatter.formatDolares(-50.76), equals('\$-50.76'));
    });

    test('Maneja cero', () {
      expect(MoneyFormatter.formatCordobas(0.0), equals('C\$0'));
      expect(MoneyFormatter.formatDolares(0.0), equals('\$0.00'));
    });
  });
}

