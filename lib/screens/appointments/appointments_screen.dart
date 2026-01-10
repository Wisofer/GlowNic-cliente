import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../models/appointment.dart';
import '../../services/api/appointment_service.dart';
import '../../services/api/employee_appointment_service.dart';
import '../../utils/role_helper.dart';
import '../../utils/jwt_decoder.dart';
import '../../utils/money_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pending_appointments_provider.dart';
import 'create_appointment_screen.dart';
import 'appointment_detail_screen.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  List<AppointmentDto> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTab = 0; // 0 = Hoy, 1 = Pendientes
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadAppointments();
    // Actualizar contador de pendientes al entrar a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pendingAppointmentsProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      
      // Configurar filtros según el tab seleccionado
      String? date;
      String? status;
      
      if (_selectedTab == 0) {
        // Tab "Hoy" - mostrar citas de hoy
        final today = DateTime.now();
        date = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      } else if (_selectedTab == 1) {
        // Tab "Pendientes" - mostrar solo pendientes
        status = 'Pending';
      }
      
      // Usar el servicio correcto según el rol
      List<AppointmentDto> appointments;
      if (RoleHelper.isEmployee(ref)) {
        final service = ref.read(employeeAppointmentServiceProvider);
        appointments = await service.getAppointments(
          date: date,
          status: status,
        );
      } else {
        final service = ref.read(appointmentServiceProvider);
        appointments = await service.getAppointments(
          date: date,
          status: status,
        );
      }
      
      if (mounted) {
        setState(() {
          _appointments = appointments;
          _isLoading = false;
          _errorMessage = null;
        });
        // Actualizar contador de pendientes
        ref.read(pendingAppointmentsProvider.notifier).refresh();
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final errorData = e.response?.data;
      
      // Si es 404, el servicio ya retornó lista vacía, así que no deberíamos llegar aquí
      // Pero por si acaso, manejamos el caso
      if (statusCode == 404) {
        if (mounted) {
          setState(() {
            _appointments = [];
            _isLoading = false;
            _errorMessage = null;
          });
        }
        return;
      }
      
      String message;
      if (errorData is Map<String, dynamic>) {
        message = errorData['message'] ?? e.message ?? 'Error desconocido';
      } else if (errorData is String) {
        message = errorData;
      } else {
        message = e.message ?? 'Error desconocido';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width >= 360 && size.width < 600;
    
    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF1F2937);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF6B7280);
    final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB);
    final bgColor = isDark ? const Color(0xFF0A0A0B) : const Color(0xFFFFF1F5);
    const accentColor = Color(0xFFEC4899);

    // Valores responsive
    final double horizontalPadding = isSmallScreen ? 16 : (isMediumScreen ? 18 : 20);
    final double verticalSpacing = isSmallScreen ? 10 : 12;
    final double titleFontSize = isSmallScreen ? 20 : (isMediumScreen ? 22 : 24);
    final double subtitleFontSize = isSmallScreen ? 11 : 12;
    final double iconSize = isSmallScreen ? 32 : 36;
    final double iconInnerSize = isSmallScreen ? 16 : 18;
    final double listPadding = isSmallScreen ? 12 : 16;
    final double cardSpacing = isSmallScreen ? 10 : 12;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header limpio
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, isSmallScreen ? 12 : 16, horizontalPadding, verticalSpacing),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Citas',
                          style: GoogleFonts.inter(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 1 : 2),
                        Text(
                          _selectedTab == 0 ? 'Citas de hoy' : 'Citas pendientes',
                          style: GoogleFonts.inter(
                            fontSize: subtitleFontSize,
                            color: mutedColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Icono de historial
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppointmentHistoryScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: mutedColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Iconsax.document_text,
                          color: textColor,
                          size: iconInnerSize,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 10),
                  // Botón agregar cita
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateAppointmentScreen(),
                          ),
                        );
                        if (result == true) {
                          _loadAppointments();
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Iconsax.add,
                          color: accentColor,
                          size: iconInnerSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs estilo línea inferior
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: _LineTabBar(
                selectedIndex: _selectedTab,
                onTabSelected: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                tabs: const ['Hoy', 'Pendientes'],
                accentColor: accentColor,
                textColor: textColor,
                mutedColor: mutedColor,
                isSmallScreen: isSmallScreen,
              ),
            ),
            SizedBox(height: verticalSpacing),

            // PageView con deslizamiento horizontal
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedTab = index;
                  });
                  _loadAppointments();
                },
                children: [
                  // Página 0: Hoy
                  _buildAppointmentsList(
                    context: context,
                    isLoading: _isLoading,
                    errorMessage: _errorMessage,
                    appointments: _appointments,
                    selectedTab: 0,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    accentColor: accentColor,
                    bgColor: bgColor,
                    isSmallScreen: isSmallScreen,
                    listPadding: listPadding,
                    cardSpacing: cardSpacing,
                    onRetry: _loadAppointments,
                    onRefresh: _loadAppointments,
                  ),
                  // Página 1: Pendientes
                  _buildAppointmentsList(
                    context: context,
                    isLoading: _isLoading,
                    errorMessage: _errorMessage,
                    appointments: _appointments,
                    selectedTab: 1,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    accentColor: accentColor,
                    bgColor: bgColor,
                    isSmallScreen: isSmallScreen,
                    listPadding: listPadding,
                    cardSpacing: cardSpacing,
                    onRetry: _loadAppointments,
                    onRefresh: _loadAppointments,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList({
    required BuildContext context,
    required bool isLoading,
    required String? errorMessage,
    required List<AppointmentDto> appointments,
    required int selectedTab,
    required Color textColor,
    required Color mutedColor,
    required Color cardColor,
    required Color borderColor,
    required Color accentColor,
    required Color bgColor,
    required bool isSmallScreen,
    required double listPadding,
    required double cardSpacing,
    required VoidCallback onRetry,
    required Future<void> Function() onRefresh,
  }) {
    return isLoading
        ? Center(child: CircularProgressIndicator(color: accentColor))
        : errorMessage != null
            ? _ErrorState(
                errorMessage: errorMessage,
                onRetry: onRetry,
                textColor: textColor,
                mutedColor: mutedColor,
                accentColor: accentColor,
                isSmallScreen: isSmallScreen,
              )
            : appointments.isEmpty
                ? _EmptyState(
                    selectedTab: selectedTab,
                    onAddAppointment: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateAppointmentScreen(),
                        ),
                      );
                      if (result == true) {
                        _loadAppointments();
                      }
                    },
                    textColor: textColor,
                    mutedColor: mutedColor,
                    accentColor: accentColor,
                    isSmallScreen: isSmallScreen,
                  )
                : RefreshIndicator(
                    onRefresh: onRefresh,
                    color: accentColor,
                    child: ListView.builder(
                      padding: EdgeInsets.all(listPadding),
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        final apt = appointments[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: cardSpacing),
                          child: _AppointmentCard(
                            appointment: apt,
                            textColor: textColor,
                            mutedColor: mutedColor,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            accentColor: accentColor,
                            isSmallScreen: isSmallScreen,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AppointmentDetailScreen(
                                    appointment: apt,
                                  ),
                                ),
                              );
                              if (result == true) {
                                _loadAppointments();
                              }
                            },
                          ),
                        );
                      },
                    ),
                  );
  }
}

class _LineTabBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;
  final List<String> tabs;
  final Color accentColor;
  final Color textColor;
  final Color mutedColor;
  final bool isSmallScreen;

  const _LineTabBar({
    required this.selectedIndex,
    required this.onTabSelected,
    required this.tabs,
    required this.accentColor,
    required this.textColor,
    required this.mutedColor,
    this.isSmallScreen = false,
  });

  @override
  State<_LineTabBar> createState() => _LineTabBarState();
}

class _LineTabBarState extends State<_LineTabBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_LineTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: widget.tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value;
            final isSelected = index == widget.selectedIndex;
            
            return Expanded(
              child: GestureDetector(
                onTap: () => widget.onTabSelected(index),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: widget.isSmallScreen ? 8 : 10),
                  child: Column(
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: widget.isSmallScreen ? 13 : 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? widget.textColor : widget.mutedColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: widget.isSmallScreen ? 5 : 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        height: 1.5,
                        decoration: BoxDecoration(
                          color: isSelected ? widget.accentColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final int selectedTab;
  final VoidCallback onAddAppointment;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final bool isSmallScreen;

  const _EmptyState({
    required this.selectedTab,
    required this.onAddAppointment,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    this.isSmallScreen = false,
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
                  Iconsax.calendar_remove,
                  color: mutedColor,
                  size: 56,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No hay citas',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                selectedTab == 0
                    ? 'No tienes citas programadas para hoy'
                    : 'No tienes citas pendientes',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: mutedColor,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAddAppointment,
                icon: const Icon(Iconsax.add, size: 18),
                label: const Text('Agregar Cita'),
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

class _ErrorState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;
  final bool isSmallScreen;

  const _ErrorState({
    required this.errorMessage,
    required this.onRetry,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = isSmallScreen ? 24 : 40;
    final double verticalPadding = isSmallScreen ? 40 : 60;
    final double iconSize = isSmallScreen ? 48 : 56;
    final double titleFontSize = isSmallScreen ? 16 : 18;
    final double subtitleFontSize = isSmallScreen ? 12 : 13;
    
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.warning_2, color: const Color(0xFFEF4444), size: iconSize),
              SizedBox(height: isSmallScreen ? 16 : 20),
              Text(
                'Error al cargar',
                style: GoogleFonts.inter(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              SizedBox(height: isSmallScreen ? 4 : 6),
              Text(
                errorMessage,
                style: GoogleFonts.inter(
                  fontSize: subtitleFontSize,
                  color: mutedColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(Iconsax.refresh, size: isSmallScreen ? 16 : 18),
                label: Text(
                  'Reintentar',
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 14 : 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 20,
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends ConsumerWidget {
  final AppointmentDto appointment;
  final Color textColor;
  final Color mutedColor;
  final Color cardColor;
  final Color borderColor;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isSmallScreen;

  const _AppointmentCard({
    required this.appointment,
    required this.textColor,
    required this.mutedColor,
    required this.cardColor,
    required this.borderColor,
    required this.accentColor,
    required this.onTap,
    this.isSmallScreen = false,
  });

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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Confirmed':
        return Iconsax.tick_circle;
      case 'Pending':
        return Iconsax.clock;
      case 'Cancelled':
        return Iconsax.close_circle;
      case 'Completed':
        return Iconsax.tick_square;
      default:
        return Iconsax.info_circle;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSmall = isSmallScreen;
    final statusColor = _getStatusColor(appointment.status);
    final dateTime = appointment.dateTime;
    final isToday = dateTime.year == DateTime.now().year &&
        dateTime.month == DateTime.now().month &&
        dateTime.day == DateTime.now().day;
    
    // Verificar si es mi cita (para empleados)
    bool isMyAppointment = false;
    final isEmployee = RoleHelper.isEmployee(ref);
    if (isEmployee) {
      final authState = ref.read(authNotifierProvider);
      final currentEmployeeId = int.tryParse(JwtDecoder.getUserId(authState.userToken) ?? '') ?? 
                                int.tryParse(authState.userProfile?.userId ?? '');
      isMyAppointment = appointment.isAssignedTo(currentEmployeeId);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isEmployee && isMyAppointment) ? accentColor.withOpacity(0.5) : borderColor, 
            width: 1
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: isSmall ? 36 : 40,
                    height: isSmall ? 36 : 40,
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
                      Iconsax.calendar_2,
                      color: Colors.white,
                      size: isSmall ? 18 : 20,
                    ),
                  ),
                  SizedBox(width: isSmall ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.clientName,
                          style: GoogleFonts.inter(
                            fontSize: isSmall ? 14 : 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: isSmall ? 2 : 3),
                        // Mostrar todos los servicios o el primero si no hay lista
                        if (appointment.services.isNotEmpty)
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: appointment.services.take(3).map((service) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accentColor.withAlpha(15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  service.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: accentColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList()
                              ..addAll(
                                appointment.services.length > 3
                                    ? [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: mutedColor.withAlpha(15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '+${appointment.services.length - 3}',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: mutedColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ]
                                    : [],
                              ),
                          )
                        else if (appointment.serviceName != null && appointment.serviceName!.isNotEmpty)
                          Row(
                            children: [
                              Icon(Iconsax.star1, size: isSmall ? 11 : 12, color: mutedColor),
                              SizedBox(width: isSmall ? 4 : 5),
                              Expanded(
                                child: Text(
                                  appointment.serviceName ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: isSmall ? 11 : 12,
                                    color: mutedColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            'Sin servicio',
                            style: GoogleFonts.inter(
                              fontSize: isSmall ? 11 : 12,
                              color: mutedColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 8 : 10,
                      vertical: isSmall ? 4 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(appointment.status),
                          size: isSmall ? 11 : 12,
                          color: statusColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _getStatusText(appointment.status),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmall ? 10 : 12),
              Container(
                padding: EdgeInsets.all(isSmall ? 8 : 10),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmall ? 5 : 6),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Iconsax.clock,
                        color: accentColor,
                        size: isSmall ? 14 : 16,
                      ),
                    ),
                    SizedBox(width: isSmall ? 8 : 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isToday ? 'Hoy' : _formatDate(appointment.date),
                            style: GoogleFonts.inter(
                              fontSize: isSmall ? 12 : 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: isSmall ? 1 : 2),
                          Text(
                            appointment.time,
                            style: GoogleFonts.inter(
                              fontSize: isSmall ? 11 : 12,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmall ? 8 : 10,
                        vertical: isSmall ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.dollar_circle, size: isSmall ? 12 : 14, color: accentColor),
                          SizedBox(width: isSmall ? 3 : 4),
                          Text(
                            MoneyFormatter.formatCordobas(_getTotalPrice(appointment)),
                            style: GoogleFonts.inter(
                              fontSize: isSmall ? 13 : 16,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getTotalPrice(AppointmentDto appointment) {
    if (appointment.services.isNotEmpty) {
      return appointment.services.fold<double>(0.0, (sum, service) => sum + service.price);
    }
    return appointment.servicePrice ?? 0.0;
  }

  String _formatDate(String date) {
    final parts = date.split('-');
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return '${parts[2]} ${months[int.parse(parts[1]) - 1]}';
  }
}

/// Pantalla de historial completo de citas
class AppointmentHistoryScreen extends ConsumerStatefulWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  ConsumerState<AppointmentHistoryScreen> createState() => _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends ConsumerState<AppointmentHistoryScreen> {
  List<AppointmentDto> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<AppointmentDto> appointments;
      if (RoleHelper.isEmployee(ref)) {
        final service = ref.read(employeeAppointmentServiceProvider);
        appointments = await service.getHistory();
      } else {
        final service = ref.read(appointmentServiceProvider);
        appointments = await service.getHistory();
      }

      // Ordenar por fecha más reciente primero
      appointments.sort((a, b) {
        final dateA = DateTime.parse('${a.date} ${a.time}');
        final dateB = DateTime.parse('${b.date} ${b.time}');
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _appointments = appointments;
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Historial de Citas',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : _errorMessage != null
              ? _ErrorState(
                  errorMessage: _errorMessage!,
                  onRetry: _loadHistory,
                  textColor: textColor,
                  mutedColor: mutedColor,
                  accentColor: accentColor,
                )
              : _appointments.isEmpty
                  ? _EmptyHistoryState(
                      textColor: textColor,
                      mutedColor: mutedColor,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      color: accentColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _appointments.length,
                        itemBuilder: (context, index) {
                          final apt = _appointments[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AppointmentCard(
                              appointment: apt,
                              textColor: textColor,
                              mutedColor: mutedColor,
                              cardColor: cardColor,
                              borderColor: borderColor,
                              accentColor: accentColor,
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AppointmentDetailScreen(
                                      appointment: apt,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _loadHistory();
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  final Color textColor;
  final Color mutedColor;

  const _EmptyHistoryState({
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.document_text,
              color: mutedColor,
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              'No hay historial',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aún no tienes citas en el historial',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: mutedColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
