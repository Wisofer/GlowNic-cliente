import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/appointment.dart';
import '../../models/service.dart';
import '../../services/api/appointment_service.dart';
import '../../services/api/employee_appointment_service.dart';
import '../../services/api/service_service.dart';
import '../../services/api/employee_service_service.dart';
import '../../utils/role_helper.dart';
import '../../utils/jwt_decoder.dart';
import '../../utils/money_formatter.dart';
import '../../utils/audio_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pending_appointments_provider.dart';

class AppointmentDetailScreen extends ConsumerStatefulWidget {
  final AppointmentDto appointment;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
  });

  @override
  ConsumerState<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends ConsumerState<AppointmentDetailScreen> {
  late AppointmentDto _appointment;
  bool _isLoading = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
  }

  Future<void> _updateStatus(String newStatus) async {
    // Si se completa una cita sin servicios, mostrar modal para agregar servicios
    if (newStatus == 'Completed' && _appointment.services.isEmpty) {
      final serviceIds = await _showServiceSelectionDialog();
      if (serviceIds == null) {
        // Usuario canceló, no hacer nada
        return;
      }
      // Continuar con la actualización incluyendo los servicios
      await _updateStatusWithServices(newStatus, serviceIds);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Usar el servicio correcto según el rol
      AppointmentDto updated;
      if (RoleHelper.isEmployee(ref)) {
        final service = ref.read(employeeAppointmentServiceProvider);
        updated = await service.updateAppointment(
          id: _appointment.id,
          status: newStatus,
        );
      } else {
        final service = ref.read(appointmentServiceProvider);
        updated = await service.updateAppointment(
          id: _appointment.id,
          status: newStatus,
        );
      }

      if (mounted) {
        setState(() {
          _appointment = updated;
          _isLoading = false;
        });

        // Reproducir audio de éxito
        AudioHelper.playSuccess();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estado actualizado exitosamente'),
            backgroundColor: Color(0xFFEC4899),
          ),
        );
        
        // Actualizar contador de pendientes si cambió el estado
        if (_appointment.status == 'Pending' && newStatus != 'Pending') {
          // Si era pendiente y ahora no lo es, decrementar contador
          ref.read(pendingAppointmentsProvider.notifier).decrement();
        } else if (_appointment.status != 'Pending' && newStatus == 'Pending') {
          // Si no era pendiente y ahora lo es, incrementar contador
          ref.read(pendingAppointmentsProvider.notifier).increment();
        } else if (newStatus != 'Pending') {
          // Si cambió a otro estado (no pendiente), refrescar contador completo
          ref.read(pendingAppointmentsProvider.notifier).refresh();
        }
        
        // Si se confirmó la cita, ofrecer enviar WhatsApp (solo para Barber)
        if (newStatus == 'Confirmed' && RoleHelper.isBarber(ref)) {
          await _showWhatsAppDialog();
        }
        
        // Notificar que hubo cambios para refrescar otras pantallas
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Error al actualizar el estado';
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _updateStatusWithServices(String newStatus, List<int> serviceIds) async {
    setState(() => _isLoading = true);

    try {
      AppointmentDto updated;
      if (RoleHelper.isEmployee(ref)) {
        final service = ref.read(employeeAppointmentServiceProvider);
        updated = await service.updateAppointment(
          id: _appointment.id,
          status: newStatus,
          serviceIds: serviceIds.isEmpty ? null : serviceIds,
        );
      } else {
        final service = ref.read(appointmentServiceProvider);
        updated = await service.updateAppointment(
          id: _appointment.id,
          status: newStatus,
          serviceIds: serviceIds.isEmpty ? null : serviceIds,
        );
      }

      if (mounted) {
        setState(() {
          _appointment = updated;
          _isLoading = false;
        });

        // Actualizar contador de pendientes si cambió el estado
        if (_appointment.status == 'Pending' && newStatus != 'Pending') {
          ref.read(pendingAppointmentsProvider.notifier).decrement();
        } else if (_appointment.status != 'Pending' && newStatus == 'Pending') {
          ref.read(pendingAppointmentsProvider.notifier).increment();
        } else if (newStatus != 'Pending') {
          ref.read(pendingAppointmentsProvider.notifier).refresh();
        }
        
        // Reproducir audio de éxito
        AudioHelper.playSuccess();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita completada exitosamente'),
            backgroundColor: Color(0xFFEC4899),
          ),
        );
        
        // Notificar que hubo cambios para refrescar otras pantallas
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Error al actualizar el estado';
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<List<int>?> _showServiceSelectionDialog() async {
    try {
      List<ServiceDto> services;
      
      // Los empleados usan el endpoint /employee/services (solo lectura)
      // Los dueños usan el endpoint /salon/services (con permisos completos)
      if (RoleHelper.isEmployee(ref)) {
        final employeeServiceService = ref.read(employeeServiceServiceProvider);
        services = await employeeServiceService.getServices();
      } else {
        final serviceService = ref.read(serviceServiceProvider);
        services = await serviceService.getServices();
      }
      final activeServices = services.where((s) => s.isActive).toList();

      if (activeServices.isEmpty) {
        // Si no hay servicios, permitir completar sin servicios
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Completar sin servicios',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'No hay servicios disponibles. ¿Deseas completar la cita sin servicios?',
              style: GoogleFonts.inter(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar', style: GoogleFonts.inter()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Completar',
                  style: GoogleFonts.inter(color: const Color(0xFFEC4899)),
                ),
              ),
            ],
          ),
        );
        return result == true ? [] : null;
      }

      final selectedServiceIds = <int>[];

      return await showDialog<List<int>>(
        context: context,
        builder: (context) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF1F2937);
          final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF6B7280);
          final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;
          final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFD1D5DB);
          const accentColor = Color(0xFFEC4899);

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  '¿Agregar servicios?',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Selecciona los servicios realizados (opcional)',
                        style: GoogleFonts.inter(fontSize: 13, color: mutedColor),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: activeServices.length,
                          itemBuilder: (context, index) {
                            final service = activeServices[index];
                            final isSelected = selectedServiceIds.contains(service.id);
                            return InkWell(
                              onTap: () {
                                setDialogState(() {
                                  if (isSelected) {
                                    selectedServiceIds.remove(service.id);
                                  } else {
                                    selectedServiceIds.add(service.id);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected ? accentColor.withAlpha(20) : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: borderColor,
                                      width: index < activeServices.length - 1 ? 1 : 0,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isSelected ? accentColor : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSelected ? accentColor : borderColor,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? Icon(Icons.check, color: Colors.white, size: 16)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            service.name,
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${service.formattedPrice} • ${service.formattedDuration}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: mutedColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: Text('Cancelar', style: GoogleFonts.inter()),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, []),
                    child: Text(
                      'Completar sin servicios',
                      style: GoogleFonts.inter(color: mutedColor),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, selectedServiceIds),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Completar',
                      style: GoogleFonts.inter(),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      // Si hay error cargando servicios, permitir completar sin servicios
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Completar sin servicios',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'No se pudieron cargar los servicios. ¿Deseas completar la cita sin servicios?',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: GoogleFonts.inter()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Completar',
                style: GoogleFonts.inter(color: const Color(0xFFEC4899)),
              ),
            ),
          ],
        ),
      );
      return result == true ? [] : null;
    }
  }

  Future<void> _showWhatsAppDialog() async {
    final sendWhatsApp = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '💬',
                style: TextStyle(fontSize: 26),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Enviar confirmación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: const Text(
          '¿Deseas enviar un mensaje de confirmación al cliente por WhatsApp?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
              foregroundColor: Colors.white,
            ),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (sendWhatsApp == true) {
      await _sendWhatsAppMessage();
    }
  }

  Future<void> _sendWhatsAppMessage() async {
    try {
      // Solo el dueño puede enviar WhatsApp (requiere perfil del salón)
      if (RoleHelper.isEmployee(ref)) {
        throw Exception('Los trabajadores no pueden enviar mensajes de WhatsApp');
      }

      final service = ref.read(appointmentServiceProvider);
      final whatsappData = await service.getWhatsAppUrl(_appointment.id);
      
      final url = whatsappData['url'] as String;
      final uri = Uri.parse(url);
      
      // Intentar abrir WhatsApp directamente
      try {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        // Si falla con externalApplication, intentar con platformDefault
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (e2) {
          // Si también falla, intentar con la URL web de WhatsApp
          if (url.contains('whatsapp://')) {
            // Convertir whatsapp:// a https://wa.me/
            final phoneMatch = RegExp(r'phone=([0-9]+)').firstMatch(url);
            final textMatch = RegExp(r'text=([^&]+)').firstMatch(url);
            
            if (phoneMatch != null) {
              String webUrl = 'https://wa.me/${phoneMatch.group(1)}';
              if (textMatch != null) {
                final encodedText = Uri.encodeComponent(textMatch.group(1)!);
                webUrl += '?text=$encodedText';
              }
              
              try {
                await launchUrl(
                  Uri.parse(webUrl),
                  mode: LaunchMode.externalApplication,
                );
                return;
              } catch (e3) {
                // Continuar con el error original
              }
            }
          }
          
          // Si todo falla, mostrar error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No se pudo abrir WhatsApp. Asegúrate de tener WhatsApp instalado.'),
                backgroundColor: const Color(0xFFEF4444),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener URL de WhatsApp: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _deleteAppointment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      // Solo Barber puede eliminar citas
      if (RoleHelper.isEmployee(ref)) {
        throw Exception('Los trabajadores no pueden eliminar citas');
      }

      final service = ref.read(appointmentServiceProvider);
      await service.deleteAppointment(_appointment.id);

      if (mounted) {
        // Si la cita era pendiente, decrementar contador
        if (_appointment.status == 'Pending') {
          ref.read(pendingAppointmentsProvider.notifier).decrement();
        } else {
          // Refrescar contador completo por si acaso
          ref.read(pendingAppointmentsProvider.notifier).refresh();
        }
        
        setState(() => _isDeleting = false);
        // Reproducir audio de éxito
        AudioHelper.playSuccess();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita eliminada exitosamente'),
            backgroundColor: Color(0xFFEC4899),
          ),
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Error al eliminar la cita';
      if (mounted) {
        setState(() => _isDeleting = false);
        // Reproducir audio de error
        AudioHelper.playError();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        // Reproducir audio de error
        AudioHelper.playError();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return const Color(0xFFEC4899);
      case 'Pending':
        return const Color(0xFFF59E0B);
      case 'Cancelled':
        return const Color(0xFFEF4444);
      case 'Completed':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Confirmed':
        return 'Confirmada';
      case 'Pending':
        return 'Pendiente';
      case 'Cancelled':
        return 'Cancelada';
      case 'Completed':
        return 'Completada';
      default:
        return status;
    }
  }

  double _getTotalPrice() {
    if (_appointment.services.isNotEmpty) {
      return _appointment.services.fold<double>(0.0, (sum, service) => sum + service.price);
    }
    return _appointment.servicePrice ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF1F2937);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF6B7280);
    final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB);
    final bgColor = isDark ? const Color(0xFF0A0A0B) : const Color(0xFFFFF1F5);
    const accentColor = Color(0xFFEC4899);
    final statusColor = _getStatusColor(_appointment.status);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Detalles de la Cita',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        actions: [
          // Solo Barber puede eliminar citas
          if (RoleHelper.isBarber(ref)) ...[
            if (_isDeleting)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                onPressed: _deleteAppointment,
                icon: const Icon(Iconsax.trash),
                color: const Color(0xFFEF4444),
              ),
          ],
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Iconsax.tick_circle,
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estado',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: mutedColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getStatusText(_appointment.status),
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Client Info
                  _InfoCard(
                    icon: Iconsax.user,
                    title: 'Cliente',
                    subtitle: _appointment.clientName,
                    trailing: _appointment.clientPhone,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 12),

                  // Services Info
                  if (_appointment.services.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: accentColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Iconsax.star1, color: accentColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Servicios',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: mutedColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: _appointment.services.map((service) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: accentColor.withAlpha(15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: accentColor.withAlpha(30),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                service.name,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: textColor,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                service.formattedPrice,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: accentColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Total:',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: mutedColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    MoneyFormatter.formatCordobas(_getTotalPrice()),
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    _InfoCard(
                      icon: Iconsax.star1,
                      title: 'Servicio',
                      subtitle: (_appointment.serviceName?.isEmpty ?? true) ? 'Sin servicio asignado' : (_appointment.serviceName ?? 'Sin servicio asignado'),
                      trailing: (_appointment.servicePrice ?? 0) > 0 
                          ? 'C\$${_appointment.servicePrice!.toStringAsFixed(2)}'
                          : '-',
                      textColor: textColor,
                      mutedColor: mutedColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                    ),
                  const SizedBox(height: 12),

                  // Date & Time
                  _InfoCard(
                    icon: Iconsax.calendar,
                    title: 'Fecha y Hora',
                    subtitle: _appointment.date,
                    trailing: _appointment.time,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 32),

                  // Status Actions
                  Builder(
                    builder: (context) {
                      final isBarber = RoleHelper.isBarber(ref);
                      final isEmployee = RoleHelper.isEmployee(ref);
                      final authState = ref.read(authNotifierProvider);
                      final currentEmployeeId = isEmployee 
                          ? (int.tryParse(JwtDecoder.getUserId(authState.userToken) ?? '') ?? 
                              int.tryParse(authState.userProfile?.userId ?? ''))
                          : null;
                      
                      // Para empleados: mostrar acciones si la cita está pendiente (sin asignar) o asignada a ellos
                      // Para dueños: mostrar acciones siempre
                      final canShowActions = isBarber || 
                          (isEmployee && (_appointment.employeeId == null || 
                           _appointment.isAssignedTo(currentEmployeeId)));
                      
                      
                      if (!canShowActions) {
                        return const SizedBox.shrink();
                      }
                      
                      // Botones para citas pendientes
                      if (_appointment.status == 'Pending') {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Acciones',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Botón "Aceptar" para empleados (citas sin asignar)
                            if (isEmployee && _appointment.employeeId == null)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _updateStatus('Confirmed'),
                                  icon: const Icon(Iconsax.tick_circle),
                                  label: const Text('Aceptar Cita'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            // Botones para Barber
                            if (isBarber) ...[
                              Builder(
                                builder: (context) {
                                  return SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        _updateStatus('Confirmed');
                                      },
                                      icon: const Icon(Iconsax.tick_circle),
                                      label: const Text('Confirmar Cita'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: accentColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _updateStatus('Cancelled'),
                                  icon: const Icon(Iconsax.close_circle),
                                  label: const Text('Cancelar Cita'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: const BorderSide(color: Color(0xFFEF4444)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      } else {
                      }
                      
                      // Botón para completar citas confirmadas
                      if (_appointment.status == 'Confirmed') {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStatus('Completed'),
                            icon: const Icon(Iconsax.tick_square),
                            label: const Text('Marcar como Completada'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        );
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final Color textColor;
  final Color mutedColor;
  final Color cardColor;
  final Color borderColor;
  final Color accentColor;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.textColor,
    required this.mutedColor,
    required this.cardColor,
    required this.borderColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: mutedColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trailing,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

