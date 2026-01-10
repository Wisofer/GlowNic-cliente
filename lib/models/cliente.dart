class Cliente {
  final int id;
  final String codigo;
  final String nombre;
  final String? telefono;
  final String? email;
  final String? cedula;
  final bool activo;
  final int totalFacturas;
  final DateTime? fechaCreacion;
  final String? observaciones;

  Cliente({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.telefono,
    this.email,
    this.cedula,
    this.activo = true,
    this.totalFacturas = 0,
    this.fechaCreacion,
    this.observaciones,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] ?? 0,
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      telefono: json['telefono'],
      email: json['email'],
      cedula: json['cedula'],
      activo: json['activo'] ?? true,
      totalFacturas: json['totalFacturas'] ?? 0,
      fechaCreacion: json['fechaCreacion'] != null 
          ? DateTime.tryParse(json['fechaCreacion']) 
          : null,
      observaciones: json['observaciones'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'cedula': cedula,
      'activo': activo,
      'observaciones': observaciones,
    };
  }

  String get iniciales {
    final parts = nombre.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }
}

