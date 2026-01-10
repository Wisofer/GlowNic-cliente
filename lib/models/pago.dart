class Pago {
  final int id;
  final double monto;
  final String moneda; // "NIO", "USD", "Ambos"
  final String tipoPago; // "Fisico", "Electronico", "Mixto"
  final String? banco;
  final String? tipoCuenta; // "Dolar", "Cordoba", "Billetera"
  final DateTime? fechaPago;
  
  // Montos físicos (efectivo)
  final double? montoCordobasFisico;
  final double? montoDolaresFisico;
  
  // Montos electrónicos (transferencia/depósito)
  final double? montoCordobasElectronico;
  final double? montoDolaresElectronico;
  
  final double? montoRecibido;
  final double? vuelto;
  final double? tipoCambio;
  final String? observaciones;
  
  // Relaciones
  final FacturaResumenPago? factura;
  final List<FacturaResumenPago>? facturas;

  Pago({
    required this.id,
    required this.monto,
    required this.moneda,
    required this.tipoPago,
    this.banco,
    this.tipoCuenta,
    this.fechaPago,
    this.montoCordobasFisico,
    this.montoDolaresFisico,
    this.montoCordobasElectronico,
    this.montoDolaresElectronico,
    this.montoRecibido,
    this.vuelto,
    this.tipoCambio,
    this.observaciones,
    this.factura,
    this.facturas,
  });

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      id: json['id'] ?? 0,
      monto: (json['monto'] ?? 0).toDouble(),
      moneda: json['moneda'] ?? 'NIO',
      tipoPago: json['tipoPago'] ?? 'Fisico',
      banco: json['banco'],
      tipoCuenta: json['tipoCuenta'],
      fechaPago: json['fechaPago'] != null 
          ? DateTime.tryParse(json['fechaPago']) 
          : null,
      montoCordobasFisico: json['montoCordobasFisico']?.toDouble(),
      montoDolaresFisico: json['montoDolaresFisico']?.toDouble(),
      montoCordobasElectronico: json['montoCordobasElectronico']?.toDouble(),
      montoDolaresElectronico: json['montoDolaresElectronico']?.toDouble(),
      montoRecibido: json['montoRecibido']?.toDouble(),
      vuelto: json['vuelto']?.toDouble(),
      tipoCambio: json['tipoCambio']?.toDouble(),
      observaciones: json['observaciones'],
      factura: json['factura'] != null 
          ? FacturaResumenPago.fromJson(json['factura']) 
          : null,
      facturas: json['facturas'] != null
          ? (json['facturas'] as List).map((e) => FacturaResumenPago.fromJson(e)).toList()
          : null,
    );
  }
}

class FacturaResumenPago {
  final int id;
  final String numero;
  final double monto;
  final ClienteResumenPago? cliente;

  FacturaResumenPago({
    required this.id,
    required this.numero,
    required this.monto,
    this.cliente,
  });

  factory FacturaResumenPago.fromJson(Map<String, dynamic> json) {
    return FacturaResumenPago(
      id: json['id'] ?? 0,
      numero: json['numero'] ?? '',
      monto: (json['monto'] ?? 0).toDouble(),
      cliente: json['cliente'] != null 
          ? ClienteResumenPago.fromJson(json['cliente']) 
          : null,
    );
  }
}

class ClienteResumenPago {
  final int id;
  final String codigo;
  final String nombre;
  final String? telefono;

  ClienteResumenPago({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.telefono,
  });

  factory ClienteResumenPago.fromJson(Map<String, dynamic> json) {
    return ClienteResumenPago(
      id: json['id'] ?? 0,
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      telefono: json['telefono'],
    );
  }
}

class FacturaParaPago {
  final int id;
  final String numero;
  final double monto;
  final DateTime? mesFacturacion;
  final String? mesNombre;
  final String estado;
  final String categoria;
  final double totalPagado;
  final double saldoPendiente;
  final bool puedePagar;
  final ServicioResumenPago? servicio;

  FacturaParaPago({
    required this.id,
    required this.numero,
    required this.monto,
    this.mesFacturacion,
    this.mesNombre,
    required this.estado,
    required this.categoria,
    required this.totalPagado,
    required this.saldoPendiente,
    required this.puedePagar,
    this.servicio,
  });

  factory FacturaParaPago.fromJson(Map<String, dynamic> json) {
    return FacturaParaPago(
      id: json['id'] ?? 0,
      numero: json['numero'] ?? '',
      monto: (json['monto'] ?? 0).toDouble(),
      mesFacturacion: json['mesFacturacion'] != null 
          ? DateTime.tryParse(json['mesFacturacion']) 
          : null,
      mesNombre: json['mesNombre'],
      estado: json['estado'] ?? 'Pendiente',
      categoria: json['categoria'] ?? 'Internet',
      totalPagado: (json['totalPagado'] ?? 0).toDouble(),
      saldoPendiente: (json['saldoPendiente'] ?? json['monto'] ?? 0).toDouble(),
      puedePagar: json['puedePagar'] ?? true,
      servicio: json['servicio'] != null 
          ? ServicioResumenPago.fromJson(json['servicio']) 
          : null,
    );
  }
}

class ServicioResumenPago {
  final int id;
  final String nombre;

  ServicioResumenPago({required this.id, required this.nombre});

  factory ServicioResumenPago.fromJson(Map<String, dynamic> json) {
    return ServicioResumenPago(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
    );
  }
}

class ClienteConFacturas {
  final ClienteResumenPago cliente;
  final List<FacturaParaPago> facturas;
  final ResumenFacturasCliente resumen;

  ClienteConFacturas({
    required this.cliente,
    required this.facturas,
    required this.resumen,
  });

  factory ClienteConFacturas.fromJson(Map<String, dynamic> json) {
    return ClienteConFacturas(
      cliente: ClienteResumenPago.fromJson(json['cliente'] ?? {}),
      facturas: (json['facturas'] as List?)
          ?.map((e) => FacturaParaPago.fromJson(e))
          .toList() ?? [],
      resumen: ResumenFacturasCliente.fromJson(json['resumen'] ?? {}),
    );
  }
}

class ResumenFacturasCliente {
  final int totalFacturas;
  final int facturasPendientes;
  final int facturasPagadas;
  final double saldoTotalPendiente;

  ResumenFacturasCliente({
    required this.totalFacturas,
    required this.facturasPendientes,
    required this.facturasPagadas,
    required this.saldoTotalPendiente,
  });

  factory ResumenFacturasCliente.fromJson(Map<String, dynamic> json) {
    return ResumenFacturasCliente(
      totalFacturas: json['totalFacturas'] ?? 0,
      facturasPendientes: json['facturasPendientes'] ?? 0,
      facturasPagadas: json['facturasPagadas'] ?? 0,
      saldoTotalPendiente: (json['saldoTotalPendiente'] ?? 0).toDouble(),
    );
  }
}

class TipoCambio {
  final double compra;      // Usar cuando cliente paga en dólares
  final double venta;       // Usar para mostrar equivalentes
  final double tipoCambio;  // Por compatibilidad (= venta)
  final String monedaBase;
  final String monedaDestino;
  final String? simboloBase;
  final String? simboloDestino;
  final DateTime? ultimaActualizacion;

  TipoCambio({
    required this.compra,
    required this.venta,
    required this.tipoCambio,
    required this.monedaBase,
    required this.monedaDestino,
    this.simboloBase,
    this.simboloDestino,
    this.ultimaActualizacion,
  });

  factory TipoCambio.fromJson(Map<String, dynamic> json) {
    final venta = (json['venta'] ?? json['tipoCambio'] ?? 36.80).toDouble();
    return TipoCambio(
      compra: (json['compra'] ?? venta).toDouble(),
      venta: venta,
      tipoCambio: (json['tipoCambio'] ?? venta).toDouble(),
      monedaBase: json['monedaBase'] ?? 'USD',
      monedaDestino: json['monedaDestino'] ?? 'NIO',
      simboloBase: json['simboloBase'] ?? '\$',
      simboloDestino: json['simboloDestino'] ?? 'C\$',
      ultimaActualizacion: json['ultimaActualizacion'] != null 
          ? DateTime.tryParse(json['ultimaActualizacion']) 
          : null,
    );
  }
}

class ResumenDia {
  final String? fecha;
  final String? fechaFormateada;
  final int totalPagos;
  final double montoTotal;
  final ResumenPorTipoPago? porTipoPago;
  final List<ResumenPorBanco>? porBanco;

  ResumenDia({
    this.fecha,
    this.fechaFormateada,
    required this.totalPagos,
    required this.montoTotal,
    this.porTipoPago,
    this.porBanco,
  });

  factory ResumenDia.fromJson(Map<String, dynamic> json) {
    return ResumenDia(
      fecha: json['fecha'],
      fechaFormateada: json['fechaFormateada'],
      totalPagos: json['totalPagos'] ?? 0,
      montoTotal: (json['montoTotal'] ?? 0).toDouble(),
      porTipoPago: json['porTipoPago'] != null 
          ? ResumenPorTipoPago.fromJson(json['porTipoPago']) 
          : null,
      porBanco: json['porBanco'] != null
          ? (json['porBanco'] as List).map((e) => ResumenPorBanco.fromJson(e)).toList()
          : null,
    );
  }
}

class ResumenPorTipoPago {
  final TipoPagoStats fisico;
  final TipoPagoStats electronico;
  final TipoPagoStats mixto;

  ResumenPorTipoPago({
    required this.fisico,
    required this.electronico,
    required this.mixto,
  });

  factory ResumenPorTipoPago.fromJson(Map<String, dynamic> json) {
    return ResumenPorTipoPago(
      fisico: TipoPagoStats.fromJson(json['fisico'] ?? {}),
      electronico: TipoPagoStats.fromJson(json['electronico'] ?? {}),
      mixto: TipoPagoStats.fromJson(json['mixto'] ?? {}),
    );
  }
}

class TipoPagoStats {
  final int cantidad;
  final double monto;

  TipoPagoStats({required this.cantidad, required this.monto});

  factory TipoPagoStats.fromJson(Map<String, dynamic> json) {
    return TipoPagoStats(
      cantidad: json['cantidad'] ?? 0,
      monto: (json['monto'] ?? 0).toDouble(),
    );
  }
}

class ResumenPorBanco {
  final String banco;
  final int cantidad;
  final double monto;

  ResumenPorBanco({
    required this.banco,
    required this.cantidad,
    required this.monto,
  });

  factory ResumenPorBanco.fromJson(Map<String, dynamic> json) {
    return ResumenPorBanco(
      banco: json['banco'] ?? '',
      cantidad: json['cantidad'] ?? 0,
      monto: (json['monto'] ?? 0).toDouble(),
    );
  }
}

// Constantes de configuración
class PagosConfig {
  static const List<String> tiposPago = ['Fisico', 'Electronico', 'Mixto'];
  static const List<String> bancos = ['BANPRO', 'LAFISE', 'BAC', 'FICOHSA', 'BDF'];
  static const List<String> tiposCuenta = ['Dolar', 'Cordoba', 'Billetera'];
  
  // Monedas - usar símbolos, no códigos ISO
  static const String cordobas = 'C\$';
  static const String dolares = '\$';
  static const String ambos = 'Ambos';
  static const List<String> monedas = [cordobas, dolares, ambos];
}
