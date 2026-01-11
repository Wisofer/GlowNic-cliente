import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../models/employee_reports.dart';
import '../../models/employee.dart';
import '../../services/api/employee_reports_service.dart';
import '../../services/api/employee_service.dart';
import '../../utils/money_formatter.dart';
import '../../utils/role_helper.dart';
import 'package:intl/intl.dart';

class EmployeeReportsScreen extends ConsumerStatefulWidget {
  const EmployeeReportsScreen({super.key});

  @override
  ConsumerState<EmployeeReportsScreen> createState() => _EmployeeReportsScreenState();
}

class _EmployeeReportsScreenState extends ConsumerState<EmployeeReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  // Filtros
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedEmployeeId;
  List<EmployeeDto> _employees = [];

  // Datos de reportes
  EmployeeAppointmentsReportDto? _appointmentsReport;
  EmployeeIncomeReportDto? _incomeReport;
  EmployeeExpensesReportDto? _expensesReport;
  EmployeeActivityReportDto? _activityReport;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index;
        });
      }
    });
    _loadEmployees();
    _loadCurrentReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    if (RoleHelper.isEmployee(ref)) return;

    try {
      final service = ref.read(employeeServiceProvider);
      final employees = await service.getEmployees();
      if (mounted) {
        setState(() {
          _employees = employees;
        });
      }
    } catch (e) {
      // Error al cargar empleados, continuar sin filtro
    }
  }

  Future<void> _loadCurrentReport() async {
    if (RoleHelper.isEmployee(ref)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reportsService = ref.read(employeeReportsServiceProvider);

      switch (_selectedTab) {
        case 0:
          _appointmentsReport = await reportsService.getAppointmentsReport(
            startDate: _startDate,
            endDate: _endDate,
            employeeId: _selectedEmployeeId,
          );
          break;
        case 1:
          _incomeReport = await reportsService.getIncomeReport(
            startDate: _startDate,
            endDate: _endDate,
            employeeId: _selectedEmployeeId,
          );
          break;
        case 2:
          _expensesReport = await reportsService.getExpensesReport(
            startDate: _startDate,
            endDate: _endDate,
            employeeId: _selectedEmployeeId,
          );
          break;
        case 3:
          _activityReport = await reportsService.getActivityReport(
            startDate: _startDate,
            endDate: _endDate,
          );
          break;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Error al cargar el reporte';
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 1);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: now,
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFEC4899),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadCurrentReport();
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedEmployeeId = null;
    });
    _loadCurrentReport();
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

    // Si es Employee, mostrar mensaje
    if (RoleHelper.isEmployee(ref)) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(
            'Reportes de Empleados',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: cardColor,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.chart_2, color: mutedColor, size: 64),
                const SizedBox(height: 16),
                Text(
                  'No disponible',
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los reportes de empleados solo están disponibles para el dueño del salón.',
                  style: GoogleFonts.inter(
                    color: mutedColor,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Reportes de Empleados',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() => _selectedTab = index);
            _loadCurrentReport();
          },
          labelColor: accentColor,
          unselectedLabelColor: mutedColor,
          indicatorColor: accentColor,
          tabs: const [
            Tab(text: 'Citas', icon: Icon(Iconsax.calendar_2, size: 20)),
            Tab(text: 'Ingresos', icon: Icon(Iconsax.wallet_add, size: 20)),
            Tab(text: 'Egresos', icon: Icon(Iconsax.wallet_minus, size: 20)),
            Tab(text: 'Actividad', icon: Icon(Iconsax.chart_2, size: 20)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filtros
          _buildFilters(textColor, mutedColor, cardColor, borderColor, accentColor),
          
          // Contenido del reporte
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: accentColor))
                : _errorMessage != null
                    ? _buildErrorState(_errorMessage!, textColor, mutedColor, accentColor)
                    : _buildReportContent(textColor, mutedColor, cardColor, borderColor, accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Iconsax.calendar, color: accentColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _startDate != null && _endDate != null
                                ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                                : 'Seleccionar rango de fechas',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _startDate != null ? textColor : mutedColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_selectedTab != 3) // No mostrar filtro de empleado en actividad
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedEmployeeId,
                        isExpanded: true,
                        hint: Text(
                          'Todos los empleados',
                          style: GoogleFonts.inter(fontSize: 13, color: mutedColor),
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              'Todos los empleados',
                              style: GoogleFonts.inter(fontSize: 13, color: textColor),
                            ),
                          ),
                          ..._employees.map((emp) {
                            return DropdownMenuItem<int?>(
                              value: emp.id,
                              child: Text(
                                emp.name,
                                style: GoogleFonts.inter(fontSize: 13, color: textColor),
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedEmployeeId = value);
                          _loadCurrentReport();
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_startDate != null || _selectedEmployeeId != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: Icon(Iconsax.close_circle, size: 16, color: mutedColor),
                label: Text(
                  'Limpiar filtros',
                  style: GoogleFonts.inter(fontSize: 12, color: mutedColor),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, Color textColor, Color mutedColor, Color accentColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2, color: const Color(0xFFEF4444), size: 56),
            const SizedBox(height: 16),
            Text(
              'Error al cargar',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.inter(fontSize: 14, color: mutedColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCurrentReport,
              icon: const Icon(Iconsax.refresh, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent(
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accentColor,
  ) {
    switch (_selectedTab) {
      case 0:
        return _buildAppointmentsReport(textColor, mutedColor, cardColor, borderColor, accentColor);
      case 1:
        return _buildIncomeReport(textColor, mutedColor, cardColor, borderColor, accentColor);
      case 2:
        return _buildExpensesReport(textColor, mutedColor, cardColor, borderColor, accentColor);
      case 3:
        return _buildActivityReport(textColor, mutedColor, cardColor, borderColor, accentColor);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAppointmentsReport(
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accentColor,
  ) {
    if (_appointmentsReport == null) {
      return Center(
        child: Text(
          'No hay datos disponibles',
          style: GoogleFonts.inter(color: mutedColor),
        ),
      );
    }

    final report = _appointmentsReport!;

    return RefreshIndicator(
      onRefresh: _loadCurrentReport,
      color: accentColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen general
            _buildSummaryCard(
              'Total de Citas',
              report.totalAppointments.toString(),
              Iconsax.calendar_2,
              accentColor,
              textColor,
              mutedColor,
              cardColor,
              borderColor,
            ),
            const SizedBox(height: 16),

            // Gráfico de barras simple (estados)
            if (report.byEmployee.isNotEmpty) ...[
              Text(
                'Citas por Estado',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatusChart(report.byEmployee, textColor, mutedColor, cardColor, borderColor, accentColor),
              const SizedBox(height: 24),
            ],

            // Tabla de empleados
            Text(
              'Detalle por Empleado',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            ...report.byEmployee.map((emp) => _buildEmployeeAppointmentCard(
                  emp,
                  textColor,
                  mutedColor,
                  cardColor,
                  borderColor,
                  accentColor,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeReport(
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accentColor,
  ) {
    if (_incomeReport == null) {
      return Center(
        child: Text(
          'No hay datos disponibles',
          style: GoogleFonts.inter(color: mutedColor),
        ),
      );
    }

    final report = _incomeReport!;

    return RefreshIndicator(
      onRefresh: _loadCurrentReport,
      color: accentColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen general
            _buildSummaryCard(
              'Ingresos Totales',
              MoneyFormatter.format(report.totalIncome),
              Iconsax.wallet_add,
              accentColor,
              textColor,
              mutedColor,
              cardColor,
              borderColor,
            ),
            const SizedBox(height: 16),

            // Gráfico de distribución
            if (report.byEmployee.isNotEmpty) ...[
              Text(
                'Distribución de Ingresos',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildIncomeChart(report.byEmployee, textColor, mutedColor, cardColor, borderColor, accentColor),
              const SizedBox(height: 24),
            ],

            // Tabla de empleados
            Text(
              'Detalle por Empleado',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            ...report.byEmployee.map((emp) => _buildEmployeeIncomeCard(
                  emp,
                  textColor,
                  mutedColor,
                  cardColor,
                  borderColor,
                  accentColor,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesReport(
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accentColor,
  ) {
    if (_expensesReport == null) {
      return Center(
        child: Text(
          'No hay datos disponibles',
          style: GoogleFonts.inter(color: mutedColor),
        ),
      );
    }

    final report = _expensesReport!;

    return RefreshIndicator(
      onRefresh: _loadCurrentReport,
      color: accentColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen general
            _buildSummaryCard(
              'Egresos Totales',
              MoneyFormatter.format(report.totalExpenses),
              Iconsax.wallet_minus,
              const Color(0xFFEF4444),
              textColor,
              mutedColor,
              cardColor,
              borderColor,
            ),
            const SizedBox(height: 16),

            // Tabla de empleados
            Text(
              'Detalle por Empleado',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            ...report.byEmployee.map((emp) => _buildEmployeeExpenseCard(
                  emp,
                  textColor,
                  mutedColor,
                  cardColor,
                  borderColor,
                  accentColor,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityReport(
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accentColor,
  ) {
    if (_activityReport == null) {
      return Center(
        child: Text(
          'No hay datos disponibles',
          style: GoogleFonts.inter(color: mutedColor),
        ),
      );
    }

    final report = _activityReport!;

    if (report.employees.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.chart_2, color: mutedColor, size: 64),
              const SizedBox(height: 16),
              Text(
                'No hay datos',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No hay empleados con actividad en el período seleccionado.',
                style: GoogleFonts.inter(fontSize: 14, color: mutedColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCurrentReport,
      color: accentColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actividad de Empleados',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            ...report.employees.map((emp) => _buildEmployeeActivityCard(
                  emp,
                  textColor,
                  mutedColor,
                  cardColor,
                  borderColor,
                  accentColor,
                )),
          ],
        ),
      ),
    );
  }

  // Widgets auxiliares para construir las tarjetas y gráficos
  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
  ) {
    return Container(
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
              color: iconColor.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: mutedColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChart(
    List<EmployeeAppointmentStats> employees,
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accentColor,
  ) {
    // Calcular totales
    int totalCompleted = 0;
    int totalPending = 0;
    int totalConfirmed = 0;
    int totalCancelled = 0;

    for (var emp in employees) {
      totalCompleted += emp.completed;
      totalPending += emp.pending;
      totalConfirmed += emp.confirmed;
      totalCancelled += emp.cancelled;
    }

    final total = totalCompleted + totalPending + totalConfirmed + totalCancelled;
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            'No hay citas en el período seleccionado',
            style: GoogleFonts.inter(color: mutedColor),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _buildBarItem('Completadas', totalCompleted, total, accentColor, textColor, mutedColor),
          const SizedBox(height: 12),
          _buildBarItem('Confirmadas', totalConfirmed, total, const Color(0xFFEC4899), textColor, mutedColor),
          const SizedBox(height: 12),
          _buildBarItem('Pendientes', totalPending, total, const Color(0xFFF59E0B), textColor, mutedColor),
          const SizedBox(height: 12),
          _buildBarItem('Canceladas', totalCancelled, total, const Color(0xFFEF4444), textColor, mutedColor),
        ],
      ),
    );
  }

  Widget _buildBarItem(String label, int value, int total, Color color, Color textColor, Color mutedColor) {
    final percentage = total > 0 ? (value / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
            ),
            Text(
              '$value (${(percentage * 100).toStringAsFixed(1)}%)',
              style: GoogleFonts.inter(fontSize: 13, color: mutedColor),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withAlpha(30),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeChart(
    List<EmployeeIncomeStats> employees,
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accentColor,
  ) {
    final total = employees.fold<double>(0.0, (sum, emp) => sum + emp.totalIncome);
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            'No hay ingresos en el período seleccionado',
            style: GoogleFonts.inter(color: mutedColor),
          ),
        ),
      );
    }

    final colors = [
      accentColor,
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: employees.asMap().entries.map((entry) {
          final index = entry.key;
          final emp = entry.value;
          final percentage = total > 0 ? (emp.totalIncome / total) : 0.0;
          final color = colors[index % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        emp.employeeName,
                        style: GoogleFonts.inter(fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      MoneyFormatter.format(emp.totalIncome),
                      style: GoogleFonts.inter(fontSize: 13, color: mutedColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: color.withAlpha(30),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmployeeAppointmentCard(
    EmployeeAppointmentStats emp,
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Iconsax.user, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.employeeName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '${emp.total} citas totales',
                      style: GoogleFonts.inter(fontSize: 12, color: mutedColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Completadas', emp.completed.toString(), const Color(0xFFEC4899)),
              ),
              Expanded(
                child: _buildStatItem('Confirmadas', emp.confirmed.toString(), const Color(0xFF6366F1)),
              ),
              Expanded(
                child: _buildStatItem('Pendientes', emp.pending.toString(), const Color(0xFFF59E0B)),
              ),
              Expanded(
                child: _buildStatItem('Canceladas', emp.cancelled.toString(), const Color(0xFFEF4444)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ingresos totales:',
                  style: GoogleFonts.inter(fontSize: 13, color: mutedColor),
                ),
                Text(
                  MoneyFormatter.format(emp.totalIncome),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeIncomeCard(
    EmployeeIncomeStats emp,
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Iconsax.wallet_add, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.employeeName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '${emp.count} transacciones',
                      style: GoogleFonts.inter(fontSize: 12, color: mutedColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('De citas', MoneyFormatter.format(emp.fromAppointments), accentColor),
              ),
              Expanded(
                child: _buildStatItem('Manuales', MoneyFormatter.format(emp.manual), const Color(0xFF6366F1)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: GoogleFonts.inter(fontSize: 13, color: mutedColor),
                ),
                Text(
                  MoneyFormatter.format(emp.totalIncome),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeExpenseCard(
    EmployeeExpenseStats emp,
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Iconsax.wallet_minus, color: Color(0xFFEF4444), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.employeeName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '${emp.count} transacciones',
                      style: GoogleFonts.inter(fontSize: 12, color: mutedColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (emp.categories.isNotEmpty) ...[
            Text(
              'Por categoría:',
              style: GoogleFonts.inter(fontSize: 12, color: mutedColor, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...emp.categories.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: GoogleFonts.inter(fontSize: 13, color: textColor),
                    ),
                    Text(
                      MoneyFormatter.format(entry.value),
                      style: GoogleFonts.inter(fontSize: 13, color: mutedColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withAlpha(10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: GoogleFonts.inter(fontSize: 13, color: mutedColor),
                ),
                Text(
                  MoneyFormatter.format(emp.totalExpenses),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeActivityCard(
    EmployeeActivityStats emp,
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accentColor,
  ) {
    final netColor = emp.netContribution >= 0 ? accentColor : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Iconsax.user, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          emp.employeeName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        if (!emp.isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: mutedColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Inactivo',
                              style: GoogleFonts.inter(fontSize: 10, color: mutedColor),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (emp.email.isNotEmpty)
                      Text(
                        emp.email,
                        style: GoogleFonts.inter(fontSize: 12, color: mutedColor),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Completadas', emp.appointmentsCompleted.toString(), accentColor),
              ),
              Expanded(
                child: _buildStatItem('Pendientes', emp.appointmentsPending.toString(), const Color(0xFFF59E0B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Ingresos', MoneyFormatter.format(emp.totalIncome), accentColor),
              ),
              Expanded(
                child: _buildStatItem('Egresos', MoneyFormatter.format(emp.totalExpenses), const Color(0xFFEF4444)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: netColor.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: netColor.withAlpha(30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Contribución neta:',
                  style: GoogleFonts.inter(fontSize: 13, color: mutedColor),
                ),
                Text(
                  MoneyFormatter.format(emp.netContribution),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: netColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 14, color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

