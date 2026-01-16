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

  /// Obtener título del payload
  String get title {
    final data = parsedPayload;
    return data['title'] ?? data['notification']?['title'] ?? '';
  }

  /// Obtener cuerpo del payload
  String get body {
    final data = parsedPayload;
    return data['body'] ?? data['notification']?['body'] ?? '';
  }

  /// Obtener tipo de notificación
  String get type {
    final data = parsedPayload;
    return data['type'] ?? data['data']?['type'] ?? '';
  }
}

class NotificationTemplateDto {
  final int id;
  final String type;
  final String title;
  final String body;

  NotificationTemplateDto({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
  });

  factory NotificationTemplateDto.fromJson(Map<String, dynamic> json) {
    return NotificationTemplateDto(
      id: json['id'] ?? json['notificationTemplate']?['id'] ?? 0,
      type: json['type'] ?? json['notificationTemplate']?['type'] ?? '',
      title: json['title'] ?? json['notificationTemplate']?['title'] ?? '',
      body: json['body'] ?? json['notificationTemplate']?['body'] ?? '',
    );
  }
}

class NotificationLogResponse {
  final NotificationLogDto notificationLog;
  final NotificationTemplateDto? notificationTemplate;

  NotificationLogResponse({
    required this.notificationLog,
    this.notificationTemplate,
  });

  factory NotificationLogResponse.fromJson(Map<String, dynamic> json) {
    return NotificationLogResponse(
      notificationLog: NotificationLogDto.fromJson(json),
      notificationTemplate: json['notificationTemplate'] != null
          ? NotificationTemplateDto.fromJson(json)
          : null,
    );
  }
}

class NotificationLogsPageResponse {
  final List<NotificationLogResponse> result;
  final int totalCount;
  final int pageNumber;
  final int pageSize;

  NotificationLogsPageResponse({
    required this.result,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
  });

  factory NotificationLogsPageResponse.fromJson(Map<String, dynamic> json) {
    return NotificationLogsPageResponse(
      result: (json['result'] as List<dynamic>?)
              ?.map((item) => NotificationLogResponse.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['totalCount'] ?? 0,
      pageNumber: json['pageNumber'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
    );
  }
}
