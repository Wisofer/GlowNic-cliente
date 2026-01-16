import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/notifications_provider.dart';
import '../../models/notification_log.dart';
import '../../services/navigation/navigation_service.dart';
import '../../main_theme.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar notificaciones al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).loadNotifications();
    });
  }

  void _handleNotificationTap(NotificationLogDto notification) {
    // Marcar como leída
    ref.read(notificationsProvider.notifier).markAsRead(notification.id);

    // Navegar según el tipo
    final type = notification.type.toLowerCase();
    final data = notification.parsedPayload;

    if (type == 'appointment') {
      final appointmentId = data['appointmentId'] ?? data['data']?['appointmentId'];
      if (appointmentId != null) {
        // Navegar a citas
        Navigator.of(context).pop(); // Cerrar pantalla de notificaciones
        NavigationService.navigateToHome();
        // TODO: Navegar específicamente a la cita si hay un endpoint para eso
      }
    } else if (type == 'announcement') {
      // Mostrar detalles del anuncio
      _showAnnouncementDialog(notification);
    }
  }

  void _showAnnouncementDialog(NotificationLogDto notification) {
    final data = notification.parsedPayload;
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
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
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
          Icon(
            Iconsax.notification_bing,
            size: 64,
            color: mutedColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay notificaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus notificaciones aparecerán aquí',
            style: TextStyle(
              fontSize: 14,
              color: mutedColor.withOpacity(0.7),
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
    final type = notification.type.toLowerCase();

    // Icono según el tipo
    IconData icon;
    Color iconColor;
    switch (type) {
      case 'appointment':
        icon = Iconsax.calendar;
        iconColor = SystemMovilColors.primary; // Rosa principal
        break;
      case 'announcement':
        icon = Iconsax.notification;
        iconColor = SystemMovilColors.secondary; // Púrpura secundario
        break;
      default:
        icon = Iconsax.info_circle;
        iconColor = mutedColor;
    }

    // Formatear fecha
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDate = dateFormat.format(notification.sentAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isUnread
            ? Border.all(color: SystemMovilColors.primary.withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title.isNotEmpty
                                  ? notification.title
                                  : 'Notificación',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: SystemMovilColors.primary, // Rosa para indicador no leído
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body.isNotEmpty
                            ? notification.body
                            : 'Sin descripción',
                        style: TextStyle(
                          fontSize: 13,
                          color: mutedColor,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 11,
                          color: mutedColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón eliminar
                IconButton(
                  icon: Icon(
                    Iconsax.trash,
                    size: 18,
                    color: mutedColor,
                  ),
                  onPressed: () => _deleteNotification(notification),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
