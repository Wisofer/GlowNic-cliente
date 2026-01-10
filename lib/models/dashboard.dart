class DashboardData {
  final ClientesStats clientes;
  final FacturasStats facturas;
  final IngresosStats ingresos;
  final DateTime? fecha;

  DashboardData({
    required this.clientes,
    required this.facturas,
    required this.ingresos,
    this.fecha,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      clientes: ClientesStats.fromJson(json['clientes'] ?? {}),
      facturas: FacturasStats.fromJson(json['facturas'] ?? {}),
      ingresos: IngresosStats.fromJson(json['ingresos'] ?? {}),
      fecha: json['fecha'] != null ? DateTime.tryParse(json['fecha']) : null,
    );
  }
}

class ClientesStats {
  final int total;
  final int activos;
  final int nuevosEsteMes;

  ClientesStats({
    required this.total,
    required this.activos,
    required this.nuevosEsteMes,
  });

  factory ClientesStats.fromJson(Map<String, dynamic> json) {
    return ClientesStats(
      total: json['total'] ?? 0,
      activos: json['activos'] ?? 0,
      nuevosEsteMes: json['nuevosEsteMes'] ?? 0,
    );
  }
}

class FacturasStats {
  final int total;
  final int pendientes;
  final int pagadas;
  final double montoPendiente;
  final double montoPagado;

  FacturasStats({
    required this.total,
    required this.pendientes,
    required this.pagadas,
    required this.montoPendiente,
    required this.montoPagado,
  });

  factory FacturasStats.fromJson(Map<String, dynamic> json) {
    return FacturasStats(
      total: json['total'] ?? 0,
      pendientes: json['pendientes'] ?? 0,
      pagadas: json['pagadas'] ?? 0,
      montoPendiente: (json['montoPendiente'] ?? 0).toDouble(),
      montoPagado: (json['montoPagado'] ?? 0).toDouble(),
    );
  }
}

class IngresosStats {
  final double total;
  final double mesActual;

  IngresosStats({
    required this.total,
    this.mesActual = 0,
  });

  factory IngresosStats.fromJson(Map<String, dynamic> json) {
    return IngresosStats(
      total: (json['total'] ?? 0).toDouble(),
      mesActual: (json['mesActual'] ?? 0).toDouble(),
    );
  }
}

