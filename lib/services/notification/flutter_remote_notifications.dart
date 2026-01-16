import 'dart:async';
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_movil/services/notification/flutter_local_notifications.dart';
import 'package:system_movil/services/notification/fcm_api.dart';
import 'package:system_movil/services/notification/notification_handler.dart';
import 'package:system_movil/services/navigation/navigation_service.dart';
import 'package:system_movil/providers/notifications_provider.dart';

/// Handler para mensajes en background (debe ser top-level)
/// IMPORTANTE: Este handler se ejecuta cuando la app está en background O completamente cerrada
/// Cuando la app está cerrada (terminated), el sistema operativo ya muestra la notificación automáticamente,
/// por lo que NO debemos mostrar una notificación local adicional para evitar duplicados.
/// 
/// NOTA: Este handler NO puede acceder a Riverpod providers directamente porque corre en un isolate separado.
/// La actualización del badge se hará cuando la app se abra y cargue las notificaciones del backend.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log('Mensaje en background handler: ${message.messageId} data=${message.data}');
  
  final type = (message.data['type'] ?? message.data['route'] ?? '')
      .toString()
      .toLowerCase();
  
  // Tipos de notificaciones que NO se muestran
  const suppressedTypes = {'post', 'comment', 'message'};

  if (suppressedTypes.contains(type)) {
    developer.log('Notificación suprimida en background para type="$type"');
    return;
  }

  // ⚠️ IMPORTANTE: NO mostrar notificación local aquí
  // Cuando la app está completamente cerrada (terminated), el sistema operativo
  // ya muestra la notificación automáticamente desde FCM.
  // Si mostramos una notificación local aquí, se duplicaría.
  // 
  // El sistema operativo maneja automáticamente:
  // - Notificaciones cuando la app está cerrada (terminated)
  // - Notificaciones cuando la app está en background
  //
  // Solo necesitamos mostrar notificación local cuando la app está en FOREGROUND,
  // que se maneja en el listener onMessage (línea 111-132).
  //
  // ⚠️ NOTA: No podemos actualizar el badge aquí porque este handler corre en un isolate separado
  // y no tiene acceso a Riverpod. El badge se actualizará cuando la app se abra.
  
  developer.log('Notificación procesada en background handler (sistema mostrará la notificación)');
}

class FlutterRemoteNotifications {
  static Ref? _ref;
  static bool _initialized = false;
  static StreamSubscription<RemoteMessage>? _onMessageSubscription;
  static StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  
  static Future<void> init(FcmApi fcmApi, {Ref? ref}) async {
    // ✅ Protección contra inicialización múltiple
    if (_initialized) {
      developer.log('FCM ya está inicializado, omitiendo inicialización duplicada');
      return;
    }
    
    _ref = ref;
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // ✅ Solicitar permisos (iOS & Android 13+)
    NotificationSettings settings;
    try {
      settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (e, stackTrace) {
      developer.log('Error al solicitar permisos', error: e, stackTrace: stackTrace);
      rethrow;
    }

    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        break;
      case AuthorizationStatus.denied:
        return;
      case AuthorizationStatus.notDetermined:
        return;
      case AuthorizationStatus.provisional:
        break;
    }

    // ✅ Habilitar auto-init de FCM
    await FirebaseMessaging.instance.setAutoInitEnabled(true);

    // ✅ Registrar handler de mensajes en background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // ✅ Obtener token FCM
    String? token = await messaging.getToken();

    // ✅ ESCENARIO 2: Manejar cuando se abre la app desde una notificación (BACKGROUND)
    // Esto se ejecuta cuando la app está en segundo plano y el usuario toca la notificación
    // Cancelar subscription anterior si existe
    await _onMessageOpenedAppSubscription?.cancel();
    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('📱 [BACKGROUND] App abierta desde notificación: ${message.messageId}');
      
      // ✅ Actualizar badge de notificaciones cuando se abre desde background
      if (_ref != null) {
        try {
          _ref!.read(notificationsProvider.notifier).refresh();
        } catch (e) {
          // Error silencioso
        }
      }
      
      final payload = json.encode({
        'type': message.data['type'] ?? message.data['route'] ?? 'home',
        if (message.data.containsKey('deeplink')) 'deeplink': message.data['deeplink'],
        'data': message.data,
      });
      NavigationService.navigateFromPayload(payload);
    });

    // ✅ ESCENARIO 1: Manejar mensajes cuando la app está en FOREGROUND (abierta y visible)
    // Cancelar subscription anterior si existe
    await _onMessageSubscription?.cancel();
    _onMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('📱 [FOREGROUND] Notificación recibida: id=${message.messageId}');
      
      final type = (message.data['type'] ?? message.data['route'] ?? '')
          .toString()
          .toLowerCase();
      const suppressedInForeground = {'post', 'comment', 'message'};

      if (suppressedInForeground.contains(type)) {
        developer.log('Notificación suprimida en foreground para type="$type"');
        return;
      }

      // Procesar notificación (actualizar contadores, refrescar dashboard, etc.)
      NotificationHandler.handleNotification(message);

      // ✅ Mostrar notificación local (el sistema NO la muestra automáticamente en foreground)
      FlutterLocalNotifications.showNotificationFromMessage(message);
    });

    // ✅ ESCENARIO 3: Manejar cold start (app completamente CERRADA)
    // Esto se ejecuta cuando la app está completamente cerrada y el usuario toca la notificación
    // El sistema operativo ya mostró la notificación, solo necesitamos navegar
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      developer.log('📱 [TERMINATED] Cold start desde notificación: ${initialMessage.messageId}');
      
      // ✅ Actualizar badge de notificaciones cuando se abre desde terminated
      if (_ref != null) {
        try {
          _ref!.read(notificationsProvider.notifier).refresh();
        } catch (e) {
          // Error silencioso
        }
      }
      
      final payload = json.encode({
        'type': initialMessage.data['type'] ?? initialMessage.data['route'] ?? 'home',
        if (initialMessage.data.containsKey('deeplink'))
          'deeplink': initialMessage.data['deeplink'],
        'data': initialMessage.data,
      });
      NavigationService.navigateFromPayload(payload);
    }

    // ✅ Sincronizar token inicial con el backend
    if (token != null && token.isNotEmpty) {
      await _syncFcmToken(fcmApi, token);
    } else {
      developer.log('FCM token not available yet; waiting for onTokenRefresh');
    }

    // ✅ Escuchar cambios/refrescos del token
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      developer.log('FCM token refreshed: $newToken');
      if (newToken.isNotEmpty) {
        await _syncFcmToken(fcmApi, newToken);
      }
    });
    
    // ✅ Marcar como inicializado
    _initialized = true;
    developer.log('FCM inicializado correctamente');
  }
  
  /// Resetear estado de inicialización (útil para testing o logout)
  static void reset() {
    _initialized = false;
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    _onMessageSubscription = null;
    _onMessageOpenedAppSubscription = null;
    _ref = null;
  }

  static Future<void> _syncFcmToken(FcmApi fcmApi, String token) async {
    try {
      final stored = await fcmApi.getStoredFcmToken();
      
      if (stored == null || stored.isEmpty) {
        // Registrar dispositivo nuevo
        await fcmApi.createDevice(fcmToken: token);
      } else if (stored != token) {
        // Actualizar token existente
        await fcmApi.refreshDeviceFcmToken(newFcmToken: token);
      }
    } catch (e, s) {
      developer.log('Error syncing device FCM token', error: e, stackTrace: s);
    }
  }
}
