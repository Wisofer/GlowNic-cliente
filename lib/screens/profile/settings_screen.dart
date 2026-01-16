import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/settings/settings_notifier.dart';
import '../../providers/auth_provider.dart';

import '../../utils/audio_helper.dart';
import '../../utils/snackbar_helper.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  NotificationSettings? _notificationSettings;
  bool _isCheckingPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermissions();
  }

  Future<void> _checkNotificationPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
    });

    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      setState(() {
        _notificationSettings = settings;
        _isCheckingPermissions = false;
      });
    } catch (e) {
      setState(() {
        _isCheckingPermissions = false;
      });
    }
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      final authState = ref.read(authNotifierProvider);
      if (!authState.isAuthenticated || authState.isDemoMode) {
        SnackbarHelper.showError(
          title: 'Error',
          message: 'Debes estar autenticado para activar notificaciones',
        );
        return;
      }

      // Solicitar permisos
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      setState(() {
        _notificationSettings = settings;
      });

      // Si se otorgaron permisos, inicializar FCM
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Inicializar notificaciones a través del provider
        await ref.read(authNotifierProvider.notifier).initializeNotifications();

        SnackbarHelper.showSuccess(
          title: 'Notificaciones activadas',
          message: 'Ahora recibirás notificaciones push',
        );
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        // En Android, abrir configuración del sistema
        if (await Permission.notification.isPermanentlyDenied) {
          SnackbarHelper.showError(
            title: 'Permisos denegados',
            message:
                'Por favor, activa las notificaciones desde la configuración del sistema',
          );
          // Abrir configuración del sistema
          await openAppSettings();
        } else {
          SnackbarHelper.showError(
            title: 'Permisos denegados',
            message: 'No se pudieron activar las notificaciones',
          );
        }
      }
    } catch (e) {
      SnackbarHelper.showError(
        title: 'Error',
        message: 'No se pudieron solicitar los permisos: $e',
      );
    }
  }

  String _getNotificationStatusText() {
    if (_isCheckingPermissions) {
      return 'Verificando...';
    }

    if (_notificationSettings == null) {
      return 'No disponible';
    }

    switch (_notificationSettings!.authorizationStatus) {
      case AuthorizationStatus.authorized:
        return 'Activo';
      case AuthorizationStatus.provisional:
        return 'Activo (provisional)';
      case AuthorizationStatus.denied:
        return 'Desactivado';
      case AuthorizationStatus.notDetermined:
        return 'No configurado';
      default:
        return 'Desconocido';
    }
  }

  Color _getNotificationStatusColor(bool isDark) {
    if (_notificationSettings == null) {
      return isDark ? const Color(0xFF71717A) : const Color(0xFF6B7280);
    }

    switch (_notificationSettings!.authorizationStatus) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return const Color(0xFF10B981); // Verde
      case AuthorizationStatus.denied:
        return const Color(0xFFEF4444); // Rojo
      default:
        return isDark ? const Color(0xFF71717A) : const Color(0xFF6B7280);
    }
  }

  bool _isNotificationEnabled() {
    if (_notificationSettings == null) {
      return false;
    }
    return _notificationSettings!.authorizationStatus ==
            AuthorizationStatus.authorized ||
        _notificationSettings!.authorizationStatus ==
            AuthorizationStatus.provisional;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark
        ? const Color(0xFFFAFAFA)
        : const Color(0xFF1F2937);
    final mutedColor = isDark
        ? const Color(0xFF71717A)
        : const Color(0xFF6B7280);
    final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF27272A)
        : const Color(0xFFE5E7EB);
    const accentColor = Color(0xFFEC4899);

    final settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configuración',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: isDark
          ? const Color(0xFF0A0A0B)
          : const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personaliza tu experiencia',
              style: GoogleFonts.inter(fontSize: 14, color: mutedColor),
            ),
            const SizedBox(height: 24),

            // Apariencia
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Apariencia',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingOption(
                    icon: Iconsax.moon,
                    title: 'Modo Oscuro',
                    subtitle: settings.themeMode == ThemeMode.dark
                        ? 'Tema oscuro activado'
                        : settings.themeMode == ThemeMode.light
                        ? 'Tema claro activado'
                        : 'Siguiendo configuración del sistema',
                    trailing: Switch(
                      value: settings.themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        ref
                            .read(settingsNotifierProvider.notifier)
                            .setThemeMode(
                              value ? ThemeMode.dark : ThemeMode.light,
                            );
                      },
                      activeColor: accentColor,
                    ),
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Notificaciones
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notificaciones',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingOption(
                    icon: Iconsax.notification,
                    title: 'Notificaciones Push',
                    subtitle: _getNotificationStatusText(),
                    trailing: _isNotificationEnabled()
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getNotificationStatusColor(
                                isDark,
                              ).withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _getNotificationStatusColor(isDark),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Activo',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _getNotificationStatusColor(isDark),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : TextButton(
                            onPressed: _requestNotificationPermissions,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Activar',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ),
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                  const SizedBox(height: 12),
                  _SettingOption(
                    icon: Iconsax.sound,
                    title: 'Sonidos',
                    subtitle: settings.soundsEnabled
                        ? 'Activados'
                        : 'Desactivados',
                    trailing: Switch(
                      value: settings.soundsEnabled,
                      onChanged: (value) {
                        ref
                            .read(settingsNotifierProvider.notifier)
                            .setSoundsEnabled(value);
                        // Actualizar AudioHelper inmediatamente
                        AudioHelper.setEnabled(value);
                      },
                      activeColor: accentColor,
                    ),
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Idioma
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Idioma',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingOption(
                    icon: Iconsax.global,
                    title: 'Idioma de la Aplicación',
                    subtitle: 'Español',
                    trailing: Icon(
                      Iconsax.arrow_right_3,
                      color: mutedColor.withAlpha(100),
                      size: 18,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Esta funcionalidad estará disponible'),
                          backgroundColor: accentColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color textColor;
  final Color mutedColor;

  const _SettingOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final widget = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFEC4899), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: mutedColor),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );

    return widget;
  }
}
