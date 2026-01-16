import 'dart:convert';

/// Modelo de dispositivo según documentación del backend
class DeviceDto {
  final int id;
  final String fcmToken;
  final String platform; // "android" o "ios"
  final DateTime? lastActiveAt;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeviceDto({
    required this.id,
    required this.fcmToken,
    required this.platform,
    this.lastActiveAt,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeviceDto.fromJson(Map<String, dynamic> json) {
    return DeviceDto(
      id: json['id'] ?? 0,
      fcmToken: json['fcmToken'] ?? '',
      platform: json['platform'] ?? '',
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'])
          : null,
      userId: json['userId'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Modelo de log de notificación según documentación del backend
class NotificationLogDto {
  final int id;
  final String status; // "sent", "opened", "failed"
  final String payload; // JSON string con el payload
  final DateTime sentAt;
  final int? deviceId;
  final int? templateId;
  final int userId;
  final DateTime createdAt;

  NotificationLogDto({
    required this.id,
    required this.status,
    required this.payload,
    required this.sentAt,
    this.deviceId,
    this.templateId,
    required this.userId,
    required this.createdAt,
  });

  factory NotificationLogDto.fromJson(Map<String, dynamic> json) {
    return NotificationLogDto(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'sent',
      payload: json['payload'] ?? '{}',
      sentAt: DateTime.parse(json['sentAt'] ?? DateTime.now().toIso8601String()),
      deviceId: json['deviceId'],
      templateId: json['templateId'],
      userId: json['userId'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Obtener datos parseados del payload
  Map<String, dynamic> get parsedPayload {
    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Obtener título de la notificación
  String get title {
    final data = parsedPayload;
    return data['title'] ?? data['notification']?['title'] ?? 'Notificación';
  }

  /// Obtener cuerpo de la notificación
  String get body {
    final data = parsedPayload;
    return data['body'] ?? data['notification']?['body'] ?? data['message'] ?? '';
  }

  /// Obtener tipo de notificación
  String get type {
    final data = parsedPayload;
    return data['type'] ?? data['route'] ?? 'unknown';
  }
}
