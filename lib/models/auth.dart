import 'barber.dart';

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class LoginResponse {
  final String token;
  final String refreshToken;
  final UserDto user;
  final String role;

  LoginResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
    required this.role,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        token: json['token'] ?? '',
        refreshToken: json['refreshToken'] ?? json['token'] ?? '', // Fallback al token si no hay refreshToken
        user: UserDto.fromJson(json['user']),
        role: json['role'],
      );
}

class UserDto {
  final int id;
  final String email;
  final String role;
  final BarberDto? barber;

  UserDto({
    required this.id,
    required this.email,
    required this.role,
    this.barber,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        id: json['id'],
        email: json['email'],
        role: json['role'],
        barber: json['barber'] != null ? BarberDto.fromJson(json['barber']) : null,
      );
}

class QrResponse {
  final String url;
  final String qrCode; // Base64 PNG

  QrResponse({
    required this.url,
    required this.qrCode,
  });

  factory QrResponse.fromJson(Map<String, dynamic> json) => QrResponse(
        url: json['url'],
        qrCode: json['qrCode'],
      );
}

