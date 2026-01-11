import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../models/salon.dart';
import '../../services/api/salon_service.dart';
import '../../providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'qr_code_screen.dart';
import 'change_password_screen.dart';
import 'about_screen.dart';
import 'working_hours_screen.dart';
import 'quick_stats_screen.dart';
import 'help_support_screen.dart';
import 'export_data_screen.dart';
import 'settings_screen.dart';
import 'employees_screen.dart';
import '../../utils/role_helper.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_option.dart';
import 'widgets/profile_error_state.dart';
import '../reports/employee_reports_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  SalonDto? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Si es Employee, no cargar perfil del dueño (no disponible)
    if (RoleHelper.isEmployee(ref)) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final service = ref.read(salonServiceProvider);
      final profile = await service.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final errorData = e.response?.data;
      
      String message;
      if (errorData is Map<String, dynamic>) {
        message = errorData['message'] ?? e.message ?? 'Error desconocido';
      } else if (errorData is String) {
        message = errorData;
      } else {
        message = e.message ?? 'Error desconocido';
      }
      
      if (statusCode == 404) {
        message = 'Endpoint no encontrado. Verifica la configuración del servidor.';
      }
      
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = statusCode != null ? 'Error $statusCode: $message' : message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _exitDemoMode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Salir del Modo Demo',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Estás seguro de que deseas salir del modo demo?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB84D),
            ),
            child: Text('Salir del Demo', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.logout();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cerrar Sesión',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: Text('Cerrar Sesión', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF1F2937);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF6B7280);
    final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB);
    const accentColor = Color(0xFFEC4899);

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    // Si es Employee, mostrar perfil con mismo diseño que dueño
    if (RoleHelper.isEmployee(ref)) {
      final authState = ref.read(authNotifierProvider);
      final userProfile = authState.userProfile;
      
      return RefreshIndicator(
        onRefresh: _loadProfile,
        color: accentColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header mejorado para empleados
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF1A1A1A),
                            const Color(0xFF0F0F0F),
                          ]
                        : [
                            const Color(0xFFFFF1F5),
                            Colors.white,
                          ],
                  ),
                  border: Border(
                    bottom: BorderSide(color: borderColor, width: 1),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar compacto
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accentColor,
                                const Color(0xFFDB2777),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(2),
                          child: ClipOval(
                            child: Container(
                              color: Colors.white,
                              child: Image.asset(
                                'assets/images/logo5.png',
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/logo5.png',
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Información compacta sin cajas
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                userProfile?.nombreCompleto ?? 'Trabajador',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                  height: 1.2,
                                ),
                              ),
                              if (userProfile?.email != null && (userProfile?.email?.isNotEmpty ?? false)) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Iconsax.sms, size: 14, color: mutedColor),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        userProfile?.email ?? '',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: mutedColor,
                                          height: 1.3,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Opciones disponibles para trabajadores
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    // Cambiar Contraseña
                    ProfileOption(
                      icon: Iconsax.lock,
                      title: 'Cambiar Contraseña',
                      subtitle: 'Actualiza tu contraseña de acceso',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                      textColor: textColor,
                      mutedColor: mutedColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: 10),

                    // Ayuda y Soporte
                    ProfileOption(
                      icon: Iconsax.message_question,
                      title: 'Ayuda y Soporte',
                      subtitle: 'Preguntas frecuentes y contacto',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpSupportScreen(),
                          ),
                        );
                      },
                      textColor: textColor,
                      mutedColor: mutedColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: 10),

                    // Configuración
                    ProfileOption(
                      icon: Iconsax.setting_2,
                      title: 'Configuración',
                      subtitle: 'Tema, notificaciones e idioma',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      textColor: textColor,
                      mutedColor: mutedColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: 10),

                    // Acerca de
                    ProfileOption(
                      icon: Iconsax.info_circle,
                      title: 'Acerca de',
                      subtitle: 'Información sobre la aplicación y desarrolladores',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutScreen(),
                          ),
                        );
                      },
                      textColor: textColor,
                      mutedColor: mutedColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                    ),
                  ],
                ),
              ),

              // Botón cerrar sesión
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: borderColor, width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 16),
                  child: ProfileOption(
                    icon: Iconsax.logout,
                    title: 'Cerrar Sesión',
                    subtitle: 'Salir de tu cuenta',
                    onTap: _logout,
                    textColor: const Color(0xFFEF4444),
                    mutedColor: const Color(0xFFEF4444),
                    cardColor: cardColor,
                    borderColor: Colors.transparent,
                    accentColor: const Color(0xFFEF4444),
                    isDestructive: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_profile == null) {
      return ProfileErrorState(
        errorMessage: _errorMessage,
        onRetry: _loadProfile,
        textColor: textColor,
        mutedColor: mutedColor,
        accentColor: accentColor,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: accentColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header con perfil
            ProfileHeader(
              profile: _profile!,
              onProfileUpdated: _loadProfile,
              textColor: textColor,
              mutedColor: mutedColor,
              cardColor: cardColor,
              borderColor: borderColor,
              accentColor: accentColor,
            ),

            // Indicador de modo demo
            if (ref.watch(authNotifierProvider).isDemoMode)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB84D), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB84D).withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Iconsax.info_circle,
                        color: Color(0xFFFFB84D),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Modo Demo',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Estás viendo datos de demostración',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF92400E).withAlpha(200),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Opciones del menú
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Información Personal
                  ProfileOption(
                    icon: Iconsax.profile_circle,
                    title: 'Información Personal',
                    subtitle: 'Nombre, negocio, teléfono',
                    onTap: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(profile: _profile!),
                        ),
                      );
                      if (updated == true) {
                        _loadProfile();
                      }
                    },
                    textColor: textColor,
                    mutedColor: mutedColor,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 10),

                  // Código QR (solo para Barber)
                  if (RoleHelper.isBarber(ref)) ...[
                    ProfileOption(
                      icon: Iconsax.scan_barcode,
                      title: 'Código QR',
                      subtitle: 'Comparte tu QR para que los clientes agenden citas',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QrCodeScreen(profile: _profile!),
                          ),
                        );
                      },
                      textColor: textColor,
                      mutedColor: mutedColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Cambiar Contraseña
                  ProfileOption(
                    icon: Iconsax.lock,
                    title: 'Cambiar Contraseña',
                    subtitle: 'Actualiza tu contraseña de acceso',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                    textColor: textColor,
                    mutedColor: mutedColor,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 10),

                  // URL Pública (solo para Barber)
                  if (RoleHelper.isBarber(ref)) ...[
                    ProfileOption(
                      icon: Iconsax.link,
                      title: 'URL Pública',
                      subtitle: _profile!.qrUrl,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _profile!.qrUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('URL copiada al portapapeles'),
                            backgroundColor: accentColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      textColor: textColor,
                      mutedColor: mutedColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Horarios de Trabajo (solo para Barber)
                  if (RoleHelper.isBarber(ref)) ...[
                    ProfileOption(
                      icon: Iconsax.clock,
                      title: 'Horarios de Trabajo',
                      subtitle: 'Configurar días y horarios disponibles',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WorkingHoursScreen(),
                          ),
                        );
                      },
                      textColor: textColor,
                      mutedColor: mutedColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Trabajadores (solo para Barber)
                  if (RoleHelper.isBarber(ref)) ...[
                    ProfileOption(
                      icon: Iconsax.people,
                      title: 'Trabajadores',
                      subtitle: 'Gestionar empleados y trabajadores',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmployeesScreen(),
                          ),
                        );
                      },
                      textColor: textColor,
                      mutedColor: mutedColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Estadísticas Rápidas (solo para Barber)
                  if (RoleHelper.isBarber(ref)) ...[
                    ProfileOption(
                      icon: Iconsax.chart_2,
                      title: 'Estadísticas Rápidas',
                      subtitle: 'Resumen de citas, ingresos y clientes',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuickStatsScreen(),
                          ),
                        );
                      },
                      textColor: textColor,
                      mutedColor: mutedColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Reportes de Empleados (solo para Barber)
                  if (RoleHelper.isBarber(ref)) ...[
                    ProfileOption(
                      icon: Iconsax.chart_21,
                      title: 'Reportes de Empleados',
                      subtitle: 'Análisis de rendimiento y actividad',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmployeeReportsScreen(),
                          ),
                        );
                      },
                      textColor: textColor,
                      mutedColor: mutedColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Ayuda y Soporte
                  ProfileOption(
                    icon: Iconsax.message_question,
                    title: 'Ayuda y Soporte',
                    subtitle: 'Preguntas frecuentes y contacto',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportScreen(),
                        ),
                      );
                    },
                    textColor: textColor,
                    mutedColor: mutedColor,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 10),

                  // Exportar Datos (solo para Barber)
                  if (RoleHelper.isBarber(ref)) ...[
                    ProfileOption(
                      icon: Iconsax.document_download,
                      title: 'Exportar Datos',
                      subtitle: 'Exportar reportes y crear backup',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExportDataScreen(),
                          ),
                        );
                      },
                      textColor: textColor,
                      mutedColor: mutedColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Configuración
                  ProfileOption(
                    icon: Iconsax.setting_2,
                    title: 'Configuración',
                    subtitle: 'Tema, notificaciones e idioma',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    textColor: textColor,
                    mutedColor: mutedColor,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 10),

                  // Acerca de
                  ProfileOption(
                    icon: Iconsax.info_circle,
                    title: 'Acerca de',
                    subtitle: 'Información sobre la aplicación y desarrolladores',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                    textColor: textColor,
                    mutedColor: mutedColor,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    accentColor: accentColor,
                  ),
                ],
              ),
            ),

            // Botón cerrar sesión
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: borderColor, width: 1),
                  ),
                ),
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  children: [
                    // Botón Salir del Demo (solo si está en modo demo)
                    if (ref.watch(authNotifierProvider).isDemoMode) ...[
                      ProfileOption(
                        icon: Iconsax.logout_1,
                        title: 'Salir del Demo',
                        subtitle: 'Volver a la pantalla de inicio de sesión',
                        onTap: _exitDemoMode,
                        textColor: const Color(0xFFFFB84D),
                        mutedColor: const Color(0xFFFFB84D),
                        cardColor: cardColor,
                        borderColor: Colors.transparent,
                        accentColor: const Color(0xFFFFB84D),
                        isDestructive: false,
                      ),
                      const SizedBox(height: 10),
                    ],
                    // Botón Cerrar Sesión
                    ProfileOption(
                      icon: Iconsax.logout,
                      title: 'Cerrar Sesión',
                      subtitle: 'Salir de tu cuenta',
                      onTap: _logout,
                      textColor: const Color(0xFFEF4444),
                      mutedColor: const Color(0xFFEF4444),
                      cardColor: cardColor,
                      borderColor: Colors.transparent,
                      accentColor: const Color(0xFFEF4444),
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
