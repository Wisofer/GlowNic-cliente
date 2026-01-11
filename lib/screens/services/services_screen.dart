import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../models/service.dart';
import '../../services/api/service_service.dart';
import '../../services/api/employee_service_service.dart';
import '../../utils/role_helper.dart';
import 'create_edit_service_screen.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  List<ServiceDto> _services = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      List<ServiceDto> services;
      
      // Los empleados usan el endpoint /employee/services (solo lectura)
      // Los dueños usan el endpoint /salon/services (con permisos completos)
      if (RoleHelper.isEmployee(ref)) {
        final employeeServiceService = ref.read(employeeServiceServiceProvider);
        services = await employeeServiceService.getServices();
      } else {
        final service = ref.read(serviceServiceProvider);
        services = await service.getServices();
      }
      
      if (mounted) {
        setState(() {
          _services = services;
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
        // 404 significa que no hay servicios, no es un error
        if (mounted) {
          setState(() {
            _services = [];
            _isLoading = false;
            _errorMessage = null;
          });
        }
        return;
      }
      
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = statusCode != null ? 'Error $statusCode: $message' : message;
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _deleteService(ServiceDto service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar servicio',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${service.name}"? Esta acción no se puede deshacer.',
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
              'Eliminar',
              style: GoogleFonts.inter(color: const Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final serviceApi = ref.read(serviceServiceProvider);
      await serviceApi.deleteService(service.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Servicio eliminado exitosamente'),
            backgroundColor: Color(0xFFEC4899),
          ),
        );
        _loadServices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF1F2937);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF6B7280);
    final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFD1D5DB);
    const accentColor = Color(0xFFEC4899);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header compacto
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Servicios',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_services.length} ${_services.length == 1 ? 'servicio' : 'servicios'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: mutedColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Solo mostrar botón de crear para dueños
                  if (RoleHelper.isBarber(ref))
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateEditServiceScreen(),
                            ),
                          );
                          if (result == true) {
                            _loadServices();
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Iconsax.add,
                            color: accentColor,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Lista de servicios
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: accentColor))
                  : _errorMessage != null
                      ? _ErrorState(
                          errorMessage: _errorMessage!,
                          onRetry: _loadServices,
                          textColor: textColor,
                          mutedColor: mutedColor,
                          accentColor: accentColor,
                        )
                      : _services.isEmpty
                          ? _EmptyState(
                              onAddService: RoleHelper.isBarber(ref)
                                  ? () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const CreateEditServiceScreen(),
                                        ),
                                      );
                                      if (result == true) {
                                        _loadServices();
                                      }
                                    }
                                  : null,
                              textColor: textColor,
                              mutedColor: mutedColor,
                              accentColor: accentColor,
                            )
                          : RefreshIndicator(
                              onRefresh: _loadServices,
                              color: accentColor,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _services.length,
                                itemBuilder: (context, index) {
                                  final service = _services[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _ServiceCard(
                                      service: service,
                                      textColor: textColor,
                                      mutedColor: mutedColor,
                                      cardColor: cardColor,
                                      borderColor: borderColor,
                                      accentColor: accentColor,
                                      onEdit: RoleHelper.isBarber(ref)
                                          ? () async {
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => CreateEditServiceScreen(
                                                    service: service,
                                                  ),
                                                ),
                                              );
                                              if (result == true) {
                                                _loadServices();
                                              }
                                            }
                                          : null,
                                      onDelete: RoleHelper.isBarber(ref)
                                          ? () => _deleteService(service)
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback? onAddService;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;

  const _EmptyState({
    this.onAddService,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: mutedColor.withAlpha(10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.star1,
                  color: mutedColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No hay servicios',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                onAddService != null
                    ? 'Agrega tu primer servicio para comenzar'
                    : 'No hay servicios disponibles',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: mutedColor,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (onAddService != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onAddService,
                  icon: const Icon(Iconsax.add, size: 18),
                  label: const Text('Agregar Servicio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;

  const _ErrorState({
    required this.errorMessage,
    required this.onRetry,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.warning_2, color: const Color(0xFFEF4444), size: 48),
              const SizedBox(height: 20),
              Text(
                'Error al cargar',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: mutedColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Iconsax.refresh, size: 18),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceDto service;
  final Color textColor;
  final Color mutedColor;
  final Color cardColor;
  final Color borderColor;
  final Color accentColor;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ServiceCard({
    required this.service,
    required this.textColor,
    required this.mutedColor,
    required this.cardColor,
    required this.borderColor,
    required this.accentColor,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor,
                        accentColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Iconsax.star1,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    // Reservar espacio para los botones (80px = 32px botón + 6px espacio + 32px botón + 10px margen)
                    padding: const EdgeInsets.only(right: 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          service.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Iconsax.clock, size: 12, color: mutedColor),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                service.formattedDuration,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: mutedColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Botones horizontales arriba y precio abajo
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botones horizontales (solo para dueños)
                if (onEdit != null || onDelete != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón editar
                      if (onEdit != null)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onEdit,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: accentColor.withAlpha(15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: accentColor.withAlpha(30),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Iconsax.edit_2,
                                size: 16,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ),
                      if (onEdit != null && onDelete != null) const SizedBox(width: 6),
                      // Botón eliminar
                      if (onDelete != null)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onDelete,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withAlpha(15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFEF4444).withAlpha(30),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Iconsax.trash,
                            size: 16,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Precio abajo
                Text(
                  service.formattedPrice,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                if (!service.isActive)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Inactivo',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
