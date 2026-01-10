class UserProfile {
  final String userId;
  final String userName;
  final String role;
  final String? nombre;
  final String? apellido;
  final String? email;
  final String? phone;
  final String? direccion;
  final String? avatar;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? sexo;
  final String? fechaNacimiento;
  final String? dni;
  final String? lugarNacimiento;
  final String? domicilio;
  final String? estadoCivil;
  final String? ocupacion;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final String? iconImageUrl;
  final String? handle;
  final String? displayName;
  final String? description;
  final String? countryCode;
  final String? nationalNumber;
  final String? country;
  final int? starCount; // Contador de estrellas del usuario
  final bool? hasRated; // Si el usuario actual ya marcó con estrella a este usuario

  UserProfile({
    required this.userId,
    required this.userName,
    required this.role,
    this.nombre,
    this.apellido,
    this.email,
    this.phone,
    this.direccion,
    this.avatar,
    this.latitude,
    this.longitude,
    this.address,
    this.sexo,
    this.fechaNacimiento,
    this.dni,
    this.lugarNacimiento,
    this.domicilio,
    this.estadoCivil,
    this.ocupacion,
    this.profileImageUrl,
    this.coverImageUrl,
    this.iconImageUrl,
    this.handle,
    this.displayName,
    this.description,
    this.countryCode,
    this.nationalNumber,
    this.country,
    this.starCount,
    this.hasRated,
  });

  /// Getter para obtener el nombre completo del usuario
  String get nombreCompleto {
    final parts = <String>[];
    if (nombre != null && nombre!.isNotEmpty) parts.add(nombre!);
    if (apellido != null && apellido!.isNotEmpty) parts.add(apellido!);
    
    if (parts.isNotEmpty) return parts.join(' ');
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (userName.isNotEmpty) return userName;
    return 'Usuario';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    
    try {
      return UserProfile(
        userId: _safeString(json['id']) ?? _safeString(json['userId']) ?? '',
        userName: _safeString(json['userName']) ?? _safeString(json['nombreUsuario']) ?? '',
        role: _safeString(json['rol']) ?? _safeString(json['role']) ?? '',
        nombre: _safeString(json['nombre']),
        apellido: _safeString(json['apellido']),
        email: _safeString(json['email']) ?? _safeString(json['userName']),
        phone: _safeString(json['phone']) ?? _safeString(json['telefono']),
        direccion: _safeString(json['direccion']),
        avatar: _safeString(json['avatar']),
        latitude: _safeToDouble(json['latitude']),
        longitude: _safeToDouble(json['longitude']),
        address: _safeString(json['address']),
        sexo: _safeString(json['sexo']),
        fechaNacimiento: _safeString(json['fechaNacimiento']),
        dni: _safeString(json['dni']),
        lugarNacimiento: _safeString(json['lugarNacimiento']),
        domicilio: _safeString(json['domicilio']),
        estadoCivil: _safeString(json['estadoCivil']),
        ocupacion: _safeString(json['ocupacion']),
        profileImageUrl: _safeString(json['profileImageUrl']),
        coverImageUrl: _safeString(json['coverImageUrl']),
        iconImageUrl: _safeString(json['iconImageUrl']),
        handle: _safeString(json['handle']),
        displayName: _safeString(json['displayName']) ?? _safeString(json['nombreCompleto']),
        description: _safeString(json['description']),
        countryCode: _safeString(json['countryCode']),
        nationalNumber: _safeString(json['nationalNumber']),
        country: _safeString(json['country']),
        starCount: _safeToInt(json['starCount'] ?? json['star_count']),
        hasRated: _safeToBool(json['hasRated'] ?? json['has_rated'] ?? json['hasRatedUser'] ?? json['has_rated_user']),
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'userName': userName,
      'rol': role,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'phone': phone,
      'direccion': direccion,
      'avatar': avatar,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'sexo': sexo,
      'fechaNacimiento': fechaNacimiento,
      'dni': dni,
      'lugarNacimiento': lugarNacimiento,
      'domicilio': domicilio,
      'estadoCivil': estadoCivil,
      'ocupacion': ocupacion,
      'profileImageUrl': profileImageUrl,
      'coverImageUrl': coverImageUrl,
      'iconImageUrl': iconImageUrl,
      'handle': handle,
      'displayName': displayName,
      'description': description,
      'countryCode': countryCode,
      'nationalNumber': nationalNumber,
      'country': country,
      'starCount': starCount,
      'hasRated': hasRated,
    };
  }

  @override
  String toString() {
    return 'UserProfile(userId: $userId, userName: $userName, role: $role, nombre: $nombre, apellido: $apellido)';
  }
}

// Helper function para convertir de forma segura a bool
bool? _safeToBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase().trim();
    if (lower == 'true' || lower == '1' || lower == 'yes') return true;
    if (lower == 'false' || lower == '0' || lower == 'no') return false;
  }
  return null;
}

// Helper function para convertir de forma segura a int
int? _safeToInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

// Helper function para convertir de forma segura a double
double? _safeToDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

// Helper function para convertir de forma segura a String
String? _safeString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}
