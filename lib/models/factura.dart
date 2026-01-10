class Factura {
  final int id;
  final String numero;
  final ClienteResumen? cliente;
  final ServicioResumen? servicio;
  final double monto;
  final String estado; // "Pendiente" o "Pagada"
  final String categoria; // "Internet" o "Streaming"
  final DateTime? fechaCreacion;
  final DateTime? mesFacturacion;

  Factura({
    required this.id,
    required this.numero,
    this.cliente,
    this.servicio,
    required this.monto,
    required this.estado,
    required this.categoria,
    this.fechaCreacion,
    this.mesFacturacion,
  });

  factory Factura.fromJson(Map<String, dynamic> json) {
    return Factura(
      id: json['id'] ?? 0,
      numero: json['numero'] ?? '',
      cliente: json['cliente'] != null 
          ? ClienteResumen.fromJson(json['cliente']) 
          : null,
      servicio: json['servicio'] != null 
          ? ServicioResumen.fromJson(json['servicio']) 
          : null,
      monto: (json['monto'] ?? 0).toDouble(),
      estado: json['estado'] ?? 'Pendiente',
      categoria: json['categoria'] ?? 'Internet',
      fechaCreacion: json['fechaCreacion'] != null 
          ? DateTime.tryParse(json['fechaCreacion']) 
          : null,
      mesFacturacion: json['mesFacturacion'] != null 
          ? DateTime.tryParse(json['mesFacturacion']) 
          : null,
    );
  }

  bool get isPendiente => estado == 'Pendiente';
  bool get isPagada => estado == 'Pagada';

  String get mesFormateado {
    if (mesFacturacion == null) return '';
    const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                   'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${meses[mesFacturacion!.month - 1]} ${mesFacturacion!.year}';
  }
}

class ClienteResumen {
  final int id;
  final String codigo;
  final String nombre;
  final String? telefono;

  ClienteResumen({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.telefono,
  });

  factory ClienteResumen.fromJson(Map<String, dynamic> json) {
    return ClienteResumen(
      id: json['id'] ?? 0,
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      telefono: json['telefono'],
    );
  }
}

class ServicioResumen {
  final int id;
  final String nombre;

  ServicioResumen({
    required this.id,
    required this.nombre,
  });

  factory ServicioResumen.fromJson(Map<String, dynamic> json) {
    return ServicioResumen(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
    );
  }
}

