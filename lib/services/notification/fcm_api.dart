import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:system_movil/models/notification_log.dart';
import 'package:system_movil/services/storage/fcm_token_storage.dart';
import 'package:system_movil/services/storage/token_storage.dart';

class _Endpoints {
  // Endpoints según documentación del backend (CORREGIDOS)
  // ✅ Rutas correctas: /api/notifications/*
  static const String devices = '/notifications/devices';
  static const String refreshToken = '/notifications/devices/refresh-token';
  static String deviceDelete(int id) => '/notifications/devices/$id';
  
  static String notificationLogs({int? page, int? pageSize}) {
    final basePath = '/notifications/logs';
    final params = <String, String>{
      if (page != null) 'page': '$page',
      if (pageSize != null) 'pageSize': '$pageSize',
    };
    if (params.isEmpty) return basePath;
    final query = params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '$basePath?$query';
  }
  
  // ✅ Endpoints para gestionar notificaciones (CORREGIDOS)
  static String notificationLogOpened(int id) => '/notifications/logs/$id/opened';
  static String notificationLogDelete(int id) => '/notifications/logs/$id';
  static const String notificationLogOpenedAll = '/notifications/logs/opened-all';
  static const String notificationLogDeleteAll = '/notifications/logs/delete-all';
}

class FcmApi {
  final Dio _dio;
  final FcmTokenStorage _storage;
  final TokenStorage _tokenStorage;

  FcmApi(this._dio, this._storage, this._tokenStorage);

  /// Registrar dispositivo con token FCM
  Future<DeviceDto?> createDevice({required String fcmToken}) async {
    developer.log('📤 [FCM API] Registrando dispositivo con token: ${fcmToken.substring(0, 20)}...');
    
    final access = await _tokenStorage.getAccessToken();
    if (access == null || access.isEmpty) {
      developer.log('❌ [FCM API] No hay token de acceso disponible');
      throw Exception('No access token available to resolve userId.');
    }

    final platform = _detectPlatform();
    developer.log('📤 [FCM API] Plataforma detectada: $platform');
    
    final data = <String, dynamic>{
      'fcmToken': fcmToken,
      'platform': platform,
    };

    final headers = {
      ..._dio.options.headers,
      'Authorization': 'Bearer $access',
    };

    developer.log('📤 [FCM API] Enviando POST a: ${_dio.options.baseUrl}${_Endpoints.devices}');
    developer.log('📤 [FCM API] Datos: $data');

    try {
      final response = await _dio.post(
        _Endpoints.devices,
        data: data,
        options: Options(headers: headers),
      );
      
      developer.log('✅ [FCM API] Respuesta del servidor: ${response.statusCode}');
      developer.log('✅ [FCM API] Datos de respuesta: ${response.data}');
      
      await _storage.saveFcmToken(fcmToken);
      developer.log('💾 [FCM API] Token guardado en almacenamiento seguro');
      
      if (response.data != null) {
        final device = DeviceDto.fromJson(response.data as Map<String, dynamic>);
        developer.log('✅ [FCM API] Dispositivo creado: ID=${device.id}, userId=${device.userId}');
        return device;
      }
      developer.log('⚠️ [FCM API] Respuesta exitosa pero sin datos');
      return null;
    } catch (e) {
      if (e is DioException) {
        final status = e.response?.statusCode;
        developer.log('❌ [FCM API] Error en la petición: $status');
        developer.log('❌ [FCM API] Respuesta: ${e.response?.data}');
        developer.log('❌ [FCM API] URL intentada: ${_dio.options.baseUrl}${_Endpoints.devices}');
        
        if (status == 200 || status == 201) {
          await _storage.saveFcmToken(fcmToken);
          if (e.response?.data != null) {
            return DeviceDto.fromJson(e.response!.data as Map<String, dynamic>);
          }
          return null;
        }
        
        // Para errores del servidor, guardar el token localmente
        // Así podremos intentar registrarlo más tarde cuando el backend esté disponible
        if (status == 404 || status == 403 || status == 500) {
          developer.log('⚠️ [FCM API] Error del servidor ($status), pero guardando token localmente para intentar más tarde');
          await _storage.saveFcmToken(fcmToken);
          return null;
        }
        
        developer.log('❌ [FCM API] Error no manejado: $e');
      } else {
        developer.log('❌ [FCM API] Excepción no esperada: $e');
      }
      
      // Incluso si hay un error, guardar el token localmente
      // El backend puede estar temporalmente no disponible
      try {
        await _storage.saveFcmToken(fcmToken);
        developer.log('💾 [FCM API] Token guardado localmente a pesar del error');
      } catch (_) {
        // Ignorar error al guardar
      }
      
      // No rethrow, simplemente retornar null para no bloquear la inicialización
      return null;
    }
  }

  /// Actualizar token FCM del dispositivo
  Future<void> refreshDeviceFcmToken({required String newFcmToken}) async {
    developer.log('🔄 [FCM API] Actualizando token FCM...');
    
    final access = await _tokenStorage.getAccessToken();
    if (access == null || access.isEmpty) {
      developer.log('❌ [FCM API] No hay token de acceso disponible');
      throw Exception('No access token available');
    }

    // Según la documentación: Body: { "fcmToken": "string" }
    final data = <String, dynamic>{
      'fcmToken': newFcmToken,
    };

    final headers = {
      ..._dio.options.headers,
      'Authorization': 'Bearer $access',
    };

    developer.log('📤 [FCM API] Enviando POST a: ${_dio.options.baseUrl}${_Endpoints.refreshToken}');
    developer.log('📤 [FCM API] Datos: $data');

    try {
      final response = await _dio.post(
        _Endpoints.refreshToken,
        data: data,
        options: Options(headers: headers),
      );
      
      developer.log('✅ [FCM API] Token actualizado exitosamente: ${response.statusCode}');
      await _storage.saveFcmToken(newFcmToken);
      developer.log('💾 [FCM API] Nuevo token guardado en almacenamiento seguro');
    } catch (e) {
      if (e is DioException) {
        final status = e.response?.statusCode;
        developer.log('❌ [FCM API] Error actualizando token: $status');
        developer.log('❌ [FCM API] Respuesta: ${e.response?.data}');
      }
      rethrow;
    }
  }

  /// Obtener token FCM almacenado
  Future<String?> getStoredFcmToken() => _storage.getFcmToken();

  /// Obtener lista de dispositivos del usuario
  Future<List<DeviceDto>> getMyDevices() async {
    developer.log('📥 [FCM API] Obteniendo dispositivos del usuario...');
    
    final access = await _tokenStorage.getAccessToken();
    if (access == null || access.isEmpty) {
      developer.log('❌ [FCM API] No hay token de acceso disponible');
      throw Exception('No access token available');
    }

    final headers = {
      ..._dio.options.headers,
      'Authorization': 'Bearer $access',
    };

    developer.log('📤 [FCM API] Enviando GET a: ${_dio.options.baseUrl}${_Endpoints.devices}');

    try {
      final response = await _dio.get(
        _Endpoints.devices,
        options: Options(headers: headers),
      );

      developer.log('✅ [FCM API] Respuesta del servidor: ${response.statusCode}');

      if (response.data is List) {
        final devices = (response.data as List)
            .map((item) => DeviceDto.fromJson(item as Map<String, dynamic>))
            .toList();
        developer.log('✅ [FCM API] Dispositivos obtenidos: ${devices.length}');
        return devices;
      }
      
      // Si la respuesta viene envuelta en un objeto
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] is List) {
          final devices = (data['data'] as List)
              .map((item) => DeviceDto.fromJson(item as Map<String, dynamic>))
              .toList();
          developer.log('✅ [FCM API] Dispositivos obtenidos: ${devices.length}');
          return devices;
        }
      }
      
      developer.log('⚠️ [FCM API] Respuesta con formato inesperado');
      return [];
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      developer.log('❌ [FCM API] Error obteniendo dispositivos: $status');
      developer.log('❌ [FCM API] Respuesta: ${e.response?.data}');
      
      if (status == 404) {
        developer.log('ℹ️ [FCM API] No se encontraron dispositivos');
        return [];
      }
      rethrow;
    }
  }

  /// Eliminar un dispositivo específico
  Future<void> deleteDevice(int deviceId) async {
    developer.log('🗑️ [FCM API] Eliminando dispositivo con ID: $deviceId');
    
    final access = await _tokenStorage.getAccessToken();
    if (access == null || access.isEmpty) {
      developer.log('❌ [FCM API] No hay token de acceso disponible');
      throw Exception('No access token available');
    }

    final headers = {
      ..._dio.options.headers,
      'Authorization': 'Bearer $access',
    };

    final endpoint = _Endpoints.deviceDelete(deviceId);
    developer.log('📤 [FCM API] Enviando DELETE a: ${_dio.options.baseUrl}$endpoint');

    try {
      await _dio.delete(
        endpoint,
        options: Options(headers: headers),
      );
      developer.log('✅ [FCM API] Dispositivo eliminado exitosamente');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      developer.log('❌ [FCM API] Error eliminando dispositivo: $status');
      developer.log('❌ [FCM API] Respuesta: ${e.response?.data}');
      rethrow;
    }
  }

  /// Detectar plataforma actual
  String _detectPlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'web';
    }
  }

  /// Obtener historial de notificaciones del usuario
  Future<List<NotificationLogDto>> getNotificationLogs({
    int page = 1,
    int pageSize = 50,
  }) async {
    final access = await _tokenStorage.getAccessToken();
    if (access == null || access.isEmpty) {
      throw Exception('No access token available');
    }

    final headers = {
      ..._dio.options.headers,
      'Authorization': 'Bearer $access',
    };

    try {
      final endpoint = _Endpoints.notificationLogs(page: page, pageSize: pageSize);
      
      final response = await _dio.get(
        endpoint,
        options: Options(headers: headers),
      );

      if (response.data is List) {
        return (response.data as List)
            .map((item) => NotificationLogDto.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      rethrow;
    }
  }

  /// Marcar notificación como leída
  Future<void> markNotificationAsOpened(int notificationLogId) async {
    final access = await _tokenStorage.getAccessToken();
    if (access == null || access.isEmpty) {
      throw Exception('No access token available');
    }

    final headers = {
      ..._dio.options.headers,
      'Authorization': 'Bearer $access',
    };

    final endpoint = _Endpoints.notificationLogOpened(notificationLogId);

    try {
      await _dio.post(
        endpoint,
        data: {'id': notificationLogId},
        options: Options(headers: headers),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar notificación
  Future<void> deleteNotificationLog(int notificationLogId) async {
    final access = await _tokenStorage.getAccessToken();
    if (access == null || access.isEmpty) {
      throw Exception('No access token available');
    }

    final headers = {
      ..._dio.options.headers,
      'Authorization': 'Bearer $access',
    };

    final endpoint = _Endpoints.notificationLogDelete(notificationLogId);

    try {
      await _dio.delete(
        endpoint,
        options: Options(headers: headers),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Marcar todas las notificaciones como leídas
  Future<void> markAllNotificationsAsOpened() async {
    final access = await _tokenStorage.getAccessToken();
    if (access == null || access.isEmpty) {
      throw Exception('No access token available');
    }

    final headers = {
      ..._dio.options.headers,
      'Authorization': 'Bearer $access',
    };

    final endpoint = _Endpoints.notificationLogOpenedAll;

    try {
      await _dio.post(
        endpoint,
        data: {},
        options: Options(headers: headers),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar todas las notificaciones
  Future<void> deleteAllNotificationLogs() async {
    developer.log('🗑️ [FCM API] Eliminando todas las notificaciones...');
    
    final access = await _tokenStorage.getAccessToken();
    if (access == null || access.isEmpty) {
      developer.log('❌ [FCM API] No hay token de acceso disponible');
      throw Exception('No access token available');
    }

    final headers = {
      ..._dio.options.headers,
      'Authorization': 'Bearer $access',
    };

    final endpoint = _Endpoints.notificationLogDeleteAll;
    developer.log('📤 [FCM API] Enviando DELETE a: ${_dio.options.baseUrl}$endpoint');

    try {
      await _dio.delete(
        endpoint,
        options: Options(headers: headers),
      );
      developer.log('✅ [FCM API] Todas las notificaciones eliminadas exitosamente');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      developer.log('❌ [FCM API] Error eliminando todas las notificaciones: $status');
      developer.log('❌ [FCM API] Respuesta: ${e.response?.data}');
      rethrow;
    }
  }
}
