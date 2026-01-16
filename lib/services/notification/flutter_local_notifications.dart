import 'dart:developer' as developer;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:system_movil/services/navigation/navigation_service.dart';

const String kHighImportanceChannelId = 'high_importance_channel';
const String kHighImportanceChannelName = 'Notificaciones Importantes';
const String kHighImportanceChannelDescription = 'Canal para notificaciones en primer plano.';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class FlutterLocalNotifications {
  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        developer.log('Notificación pulsada. payload=${response.payload}');
        if (response.payload != null) {
          NavigationService.navigateFromPayload(response.payload);
        }
      },
    );

    // Crear canal de notificaciones para Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      kHighImportanceChannelId,
      kHighImportanceChannelName,
      description: kHighImportanceChannelDescription,
      importance: Importance.high,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Generar ID único para la notificación local basado en messageId y timestamp
  /// Esto evita colisiones de hashCode
  static int _generateNotificationId(RemoteMessage message) {
    final messageId = message.messageId ?? '';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Combinar messageId y timestamp para un ID único
    // Usar los últimos 31 bits para evitar números negativos
    if (messageId.isNotEmpty) {
      return (messageId.hashCode.abs() % 2147483647);
    }
    
    // Si no hay messageId, usar timestamp (mod 31 bits)
    return (timestamp % 2147483647);
  }

  static Future<void> showNotificationFromMessage(RemoteMessage message) async {
    // ✅ Validar que el mensaje tenga contenido
    final n = message.notification;
    final title = n?.title ?? message.data['title'] ?? 'GlowNic';
    final body = n?.body ?? message.data['body'] ?? '';
    
    // Si no hay título ni cuerpo, no mostrar notificación
    if (title.isEmpty && body.isEmpty) {
      developer.log('⚠️ [LocalNotification] Mensaje sin contenido, omitiendo notificación');
      return;
    }

    // Configurar detalles de Android
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      kHighImportanceChannelId,
      kHighImportanceChannelName,
      channelDescription: kHighImportanceChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final payload = json.encode({
      'type': message.data['type'] ?? message.data['route'] ?? 'home',
      'messageId': message.messageId,
      if (message.data.containsKey('deeplink')) 'deeplink': message.data['deeplink'],
      'data': message.data,
    });

    // ✅ Usar ID único basado en messageId en lugar de hashCode
    final notificationId = _generateNotificationId(message);
    
    developer.log('🔔 [LocalNotification] Mostrando notificación: id=$notificationId, messageId=${message.messageId}');
    
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
}
