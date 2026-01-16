import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_log.dart';
import '../providers/auth_provider.dart';
import '../providers/providers.dart';

/// Estado de las notificaciones
class NotificationsState {
  final List<NotificationLogDto> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  NotificationsState copyWith({
    List<NotificationLogDto>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// Notifier para gestionar las notificaciones
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(this.ref) : super(NotificationsState()) {
    if (_isAuthenticated()) {
      loadNotifications();
    }
  }

  final Ref ref;

  bool _isAuthenticated() {
    final authState = ref.read(authNotifierProvider);
    return authState.isAuthenticated && !authState.isDemoMode;
  }

  /// Cargar notificaciones
  Future<void> loadNotifications({bool showLoading = true}) async {
    if (!_isAuthenticated()) return;

    if (showLoading) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final fcmApi = ref.read(fcmApiProvider);
      final notifications = await fcmApi.getNotificationLogs(page: 1, pageSize: 50);

      final unreadCount = notifications.where((n) => n.status == 'sent').length;

      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
        unreadCount: unreadCount,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Marcar notificación como leída
  Future<void> markAsRead(int notificationId) async {
    if (!_isAuthenticated()) return;

    try {
      final fcmApi = ref.read(fcmApiProvider);
      await fcmApi.markNotificationAsOpened(notificationId);
      
      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notificationId && n.status == 'sent') {
          return NotificationLogDto(
            id: n.id,
            status: 'opened',
            payload: n.payload,
            sentAt: n.sentAt,
            deviceId: n.deviceId,
            templateId: n.templateId,
            userId: n.userId,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();

      final unreadCount = updatedNotifications.where((n) => n.status == 'sent').length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      // Si falla el backend, al menos actualizar localmente
      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notificationId && n.status == 'sent') {
          return NotificationLogDto(
            id: n.id,
            status: 'opened',
            payload: n.payload,
            sentAt: n.sentAt,
            deviceId: n.deviceId,
            templateId: n.templateId,
            userId: n.userId,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();

      final unreadCount = updatedNotifications.where((n) => n.status == 'sent').length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    }
  }

  /// Eliminar notificación
  Future<void> deleteNotification(int notificationId) async {
    if (!_isAuthenticated()) return;

    try {
      final fcmApi = ref.read(fcmApiProvider);
      await fcmApi.deleteNotificationLog(notificationId);
      
      final updatedNotifications = state.notifications
          .where((n) => n.id != notificationId)
          .toList();

      final unreadCount = updatedNotifications.where((n) => n.status == 'sent').length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      // Si falla el backend, al menos actualizar localmente
      final updatedNotifications = state.notifications
          .where((n) => n.id != notificationId)
          .toList();

      final unreadCount = updatedNotifications.where((n) => n.status == 'sent').length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    }
  }

  /// Marcar todas como leídas
  Future<void> markAllAsRead() async {
    if (!_isAuthenticated()) return;

    try {
      final fcmApi = ref.read(fcmApiProvider);
      await fcmApi.markAllNotificationsAsOpened();
      
      final updatedNotifications = state.notifications.map((n) {
        if (n.status == 'sent') {
          return NotificationLogDto(
            id: n.id,
            status: 'opened',
            payload: n.payload,
            sentAt: n.sentAt,
            deviceId: n.deviceId,
            templateId: n.templateId,
            userId: n.userId,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (e) {
      // Si falla el backend, al menos actualizar localmente
      final updatedNotifications = state.notifications.map((n) {
        if (n.status == 'sent') {
          return NotificationLogDto(
            id: n.id,
            status: 'opened',
            payload: n.payload,
            sentAt: n.sentAt,
            deviceId: n.deviceId,
            templateId: n.templateId,
            userId: n.userId,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    }
  }

  /// Refrescar notificaciones
  Future<void> refresh() async {
    await loadNotifications(showLoading: false);
  }
}

/// Provider de notificaciones
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref);
});
