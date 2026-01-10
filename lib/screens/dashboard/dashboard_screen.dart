import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../models/dashboard_barber.dart';
import '../../services/api/barber_service.dart';
import '../../utils/money_formatter.dart';
import '../../utils/role_helper.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToAppointments;
  final VoidCallback? onNavigateToServices;
  final VoidCallback? onNavigateToFinances;
  
  const DashboardScreen({
    super.key,
    this.onNavigateToAppointments,
    this.onNavigateToServices,
    this.onNavigateToFinances,
  });

  @override
  ConsumerState<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends ConsumerState<DashboardScreen> {
  BarberDashboardDto? _dashboard;
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _lastRefresh;
  final Set<int> _dismissedAppointmentIds = {}; // IDs de citas ocultas

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> refresh() async {
    if (_isLoading) return;
    final now = DateTime.now();
    if (_lastRefresh != null && now.difference(_lastRefresh!).inSeconds < 2) {
      return;
    }
    _lastRefresh = now;
    await _loadDashboard();
  }
  
  Future<void> _loadDashboard() async {
    // Si es Employee, no cargar dashboard (no disponible)
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
      final service = ref.read(barberServiceProvider);
      final dashboard = await service.getDashboard();
      if (mounted) {
        setState(() {
          _dashboard = dashboard;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF1F2937);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF6B7280);
    final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB);
    final bgColor = isDark ? const Color(0xFF0A0A0B) : const Color(0xFFF9FAFB);
    const accentColor = Color(0xFFEC4899);

    // Si es Employee, mostrar mensaje de que el dashboard no está disponible
    if (RoleHelper.isEmployee(ref)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.trend_up, color: mutedColor, size: 64),
              const SizedBox(height: 16),
              Text(
                'Dashboard no disponible',
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Los trabajadores no tienen acceso al dashboard. Usa las secciones de Citas y Finanzas para gestionar tu trabajo.',
                style: GoogleFonts.inter(
                  color: mutedColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    if (_dashboard == null) {
      return _ErrorState(
        errorMessage: _errorMessage,
        onRetry: _loadDashboard,
        textColor: textColor,
        mutedColor: mutedColor,
        accentColor: accentColor,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: accentColor,
      child: Container(
        color: bgColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Espacio superior para separar del header
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            
            // Stats rápidas horizontales
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildQuickStats(textColor, mutedColor, cardColor, borderColor, accentColor),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Cards de resumen
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSummaryCards(textColor, mutedColor, cardColor, borderColor, accentColor),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Estadísticas adicionales
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildAdditionalStats(textColor, mutedColor, cardColor, borderColor, accentColor),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Próximas citas (solo mostrar si hay citas activas)
            if (_dashboard!.upcomingAppointments
                .where((apt) => 
                    apt.status != 'Completed' && 
                    apt.status != 'Cancelled' &&
                    !_dismissedAppointmentIds.contains(apt.id))
                .isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _buildUpcomingAppointments(textColor, mutedColor, cardColor, borderColor, accentColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accentColor,
  ) {
    final today = _dashboard!.today;
    // Solo mostrar Citas de hoy
    return _QuickStatCard(
      icon: Iconsax.calendar_2,
      value: today.appointments.toString(),
      label: 'Citas hoy',
      color: accentColor,
      textColor: textColor,
      mutedColor: mutedColor,
      cardColor: cardColor,
      borderColor: borderColor,
    );
  }

  Widget _buildSummaryCards(
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accentColor,
  ) {
    final today = _dashboard!.today;
    final month = _dashboard!.thisMonth;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    
    final cardSpacing = isSmallScreen ? 8.0 : 10.0;
    final rowSpacing = isSmallScreen ? 8.0 : 10.0;
    
    return Column(
      children: [
        // Primera fila: Ingresos del día e Ingresos mensuales
        Row(
          children: [
            Expanded(
              child: _QuickStatCard(
                icon: Iconsax.card,
                value: MoneyFormatter.formatCordobas(today.income),
                label: 'Ingresos hoy',
                color: const Color(0xFFEC4899),
                textColor: textColor,
                mutedColor: mutedColor,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
            ),
            SizedBox(width: cardSpacing),
            Expanded(
              child: _QuickStatCard(
                icon: Iconsax.card,
                value: MoneyFormatter.formatCordobas(month.income),
                label: 'Ingresos mes',
                color: const Color(0xFFEC4899),
                textColor: textColor,
                mutedColor: mutedColor,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
            ),
          ],
        ),
        SizedBox(height: rowSpacing),
        // Segunda fila: Egresos del día y Egresos mensuales
        Row(
          children: [
            Expanded(
              child: _QuickStatCard(
                icon: Iconsax.card_remove,
                value: MoneyFormatter.formatCordobas(today.expenses),
                label: 'Egresos hoy',
                color: const Color(0xFFF472B6),
                textColor: textColor,
                mutedColor: mutedColor,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
            ),
            SizedBox(width: cardSpacing),
            Expanded(
              child: _QuickStatCard(
                icon: Iconsax.card_remove,
                value: MoneyFormatter.formatCordobas(month.expenses),
                label: 'Egresos mes',
                color: const Color(0xFFF472B6),
                textColor: textColor,
                mutedColor: mutedColor,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
            ),
          ],
        ),
        SizedBox(height: rowSpacing),
        // Tercera fila: Ganancia neta del día y del mes
        Row(
          children: [
            Expanded(
              child: _QuickStatCard(
                icon: Iconsax.trend_up,
                value: MoneyFormatter.formatCordobas(today.profit),
                label: 'Ganancia hoy',
                color: const Color(0xFFC026D3),
                textColor: textColor,
                mutedColor: mutedColor,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
            ),
            SizedBox(width: cardSpacing),
            Expanded(
              child: _QuickStatCard(
                icon: Iconsax.trend_up,
                value: MoneyFormatter.formatCordobas(month.profit),
                label: 'Ganancia mes',
                color: const Color(0xFFC026D3),
                textColor: textColor,
                mutedColor: mutedColor,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalStats(
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accentColor,
  ) {
    final week = _dashboard!.thisWeek;
    final month = _dashboard!.thisMonth;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Iconsax.trend_up, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Estadísticas Adicionales',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Iconsax.profile_2user,
                  value: month.uniqueClients.toString(),
                  label: 'Clientes únicos',
                  color: const Color(0xFFEC4899),
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: borderColor,
              ),
              Expanded(
                child: _StatItem(
                  icon: Iconsax.card,
                  value: MoneyFormatter.formatCordobas(month.averagePerClient),
                  label: 'Promedio/cliente',
                  color: const Color(0xFFC026D3),
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Iconsax.calendar_2,
                  value: week.appointments.toString(),
                  label: 'Citas esta semana',
                  color: accentColor,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: borderColor,
              ),
              Expanded(
                child: _StatItem(
                  icon: Iconsax.calendar_2,
                  value: month.appointments.toString(),
                  label: 'Citas este mes',
                  color: accentColor,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments(
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accentColor,
  ) {
    final activeAppointments = _dashboard!.upcomingAppointments
        .where((apt) => 
            apt.status != 'Completed' && 
            apt.status != 'Cancelled' &&
            !_dismissedAppointmentIds.contains(apt.id))
        .take(3)
        .toList();

    // Si no hay citas activas, no mostrar nada (ni título ni botón)
    if (activeAppointments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Próximas Citas',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            // Botón "Ver todas" - solo visible cuando hay citas
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onNavigateToAppointments,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver todas',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Iconsax.arrow_right_3,
                        size: 14,
                        color: accentColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...activeAppointments.map((apt) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DismissibleAppointmentCard(
                appointment: apt,
                textColor: textColor,
                mutedColor: mutedColor,
                cardColor: cardColor,
                borderColor: borderColor,
                accentColor: accentColor,
                onDismissed: () {
                  setState(() {
                    _dismissedAppointmentIds.add(apt.id);
                  });
                },
              ),
            )),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color textColor;
  final Color mutedColor;
  final Color cardColor;
  final Color borderColor;

  const _QuickStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.textColor,
    required this.mutedColor,
    required this.cardColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width >= 360 && screenSize.width < 400;
    
    // Ajustar tamaños según el tamaño de pantalla
    final iconSize = isSmallScreen ? 32.0 : (isMediumScreen ? 36.0 : 40.0);
    final iconInnerSize = isSmallScreen ? 18.0 : 20.0;
    final padding = isSmallScreen ? 10.0 : (isMediumScreen ? 12.0 : 14.0);
    final fontSize = isSmallScreen ? 16.0 : (isMediumScreen ? 17.0 : 18.0);
    final labelFontSize = isSmallScreen ? 10.0 : 11.0;
    final spacing = isSmallScreen ? 8.0 : 12.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: iconInnerSize),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: labelFontSize,
                    color: mutedColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DismissibleAppointmentCard extends StatelessWidget {
  final appointment;
  final Color textColor;
  final Color mutedColor;
  final Color cardColor;
  final Color borderColor;
  final Color accentColor;
  final VoidCallback onDismissed;

  const _DismissibleAppointmentCard({
    required this.appointment,
    required this.textColor,
    required this.mutedColor,
    required this.cardColor,
    required this.borderColor,
    required this.accentColor,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('appointment_${appointment.id}'),
      direction: DismissDirection.endToStart, // Solo deslizar de derecha a izquierda
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Iconsax.trash,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Quitar',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (direction) {
        onDismissed();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cita oculta del inicio',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      child: _AppointmentMiniCard(
        appointment: appointment,
        textColor: textColor,
        mutedColor: mutedColor,
        cardColor: cardColor,
        borderColor: borderColor,
        accentColor: accentColor,
      ),
    );
  }
}

class _AppointmentMiniCard extends StatelessWidget {
  final appointment;
  final Color textColor;
  final Color mutedColor;
  final Color cardColor;
  final Color borderColor;
  final Color accentColor;

  const _AppointmentMiniCard({
    required this.appointment,
    required this.textColor,
    required this.mutedColor,
    required this.cardColor,
    required this.borderColor,
    required this.accentColor,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return const Color(0xFFEC4899);
      case 'Pending':
        return const Color(0xFFF59E0B);
      default:
        return mutedColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(appointment.status),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.clientName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Iconsax.clock, size: 11, color: mutedColor),
                    const SizedBox(width: 4),
                    Text(
                      appointment.time,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: mutedColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (appointment.services.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${appointment.services.length} servicio${appointment.services.length > 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(appointment.status),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color textColor;
  final Color mutedColor;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: mutedColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String? errorMessage;
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.info_circle, color: mutedColor, size: 64),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar el dashboard',
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  errorMessage!,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFDC2626),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Iconsax.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
