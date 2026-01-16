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

  static Future<void> showNotificationFromMessage(RemoteMessage message) async {
    final n = message.notification;
    final title = n?.title ?? message.data['title'] ?? 'GlowNic';
    final body = n?.body ?? message.data['body'] ?? '';
    // TODO: Usar imageUrl y avatarUrl para mostrar imágenes en notificaciones
    // final imageUrl = n?.android?.imageUrl ?? n?.apple?.imageUrl ?? message.data['image'];
    // final avatarUrl = message.data['avatar'];

    // Configurar detalles de Android
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      kHighImportanceChannelId,
      kHighImportanceChannelName,
      channelDescription: kHighImportanceChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      showWhen: true,
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
      if (message.data.containsKey('deeplink')) 'deeplink': message.data['deeplink'],
      'data': message.data,
    });

    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
}
