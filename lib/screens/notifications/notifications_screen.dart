import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/notifications_provider.dart';
import '../../models/notification_log.dart';
import '../../services/navigation/navigation_service.dart';
import '../../screens/appointments/appointments_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).loadNotifications();
    });
  }

  void _handleNotificationTap(NotificationLogDto notification) {
    ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    final type = notification.type.toLowerCase();
    final data = notification.parsedPayload;

    if (type == 'appointment' || type == 'cita') {
      final appointmentId = data['appointmentId'] ?? data['data']?['appointmentId'];
      if (appointmentId != null) {
        Navigator.of(context).pop();
        NavigationService.navigateTo(const AppointmentsScreen());
      }
    } else if (type == 'announcement' || type == 'announcement') {
      _showAnnouncementDialog(notification);
    } else {
      // Navegar al home por defecto
      Navigator.of(context).pop();
      NavigationService.navigateToHome();
    }
  }

  void _showAnnouncementDialog(NotificationLogDto notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _deleteNotification(NotificationLogDto notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar notificación'),
        content: const Text('¿Estás seguro de que deseas eliminar esta notificación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(notificationsProvider.notifier).deleteNotification(notification.id);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notificationsState = ref.watch(notificationsProvider);

    final bgColor = isDark ? const Color(0xFF0A0A0B) : const Color(0xFFF9FAFB);
    final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF1F2937);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left_2, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notificaciones',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        actions: [
          if (notificationsState.unreadCount > 0)
            TextButton(
              onPressed: () {
                ref.read(notificationsProvider.notifier).markAllAsRead();
              },
              child: Text(
                'Marcar todas',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          IconButton(
            icon: Icon(Iconsax.refresh, color: textColor),
            onPressed: () {
              ref.read(notificationsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: notificationsState.isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : notificationsState.notifications.isEmpty
              ? _buildEmptyState(mutedColor)
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(notificationsProvider.notifier).refresh();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notificationsState.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notificationsState.notifications[index];
                      return _buildNotificationItem(
                        notification,
                        cardColor,
                        textColor,
                        mutedColor,
                        isDark,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(Color mutedColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.notification_bing, size: 64, color: mutedColor),
          const SizedBox(height: 16),
          Text(
            'No hay notificaciones',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationLogDto notification,
    Color cardColor,
    Color textColor,
    Color mutedColor,
    bool isDark,
  ) {
    final isUnread = notification.status == 'sent';
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread
              ? const Color(0xFF10B981).withOpacity(0.3)
              : (isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB)),
          width: isUnread ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isUnread
                ? const Color(0xFF10B981).withOpacity(0.1)
                : mutedColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Iconsax.notification,
            color: isUnread ? const Color(0xFF10B981) : mutedColor,
            size: 24,
          ),
        ),
        title: Text(
          notification.title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: mutedColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(notification.sentAt),
              style: GoogleFonts.inter(
                fontSize: 10,
                color: mutedColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(Iconsax.more, color: mutedColor, size: 20),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Marcar como leída'),
              onTap: () {
                Future.delayed(Duration.zero, () {
                  ref.read(notificationsProvider.notifier).markAsRead(notification.id);
                });
              },
            ),
            PopupMenuItem(
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onTap: () {
                Future.delayed(Duration.zero, () {
                  _deleteNotification(notification);
                });
              },
            ),
          ],
        ),
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }
}
