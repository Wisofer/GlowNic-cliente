import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../models/finance.dart';
import '../../services/api/barber_service.dart';
import '../../services/api/employee_finance_service.dart';
import '../../utils/money_formatter.dart';
import '../../utils/role_helper.dart';
import 'income_screen.dart';
import 'expenses_screen.dart';

class FinancesScreen extends ConsumerStatefulWidget {
  const FinancesScreen({super.key});

  @override
  ConsumerState<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends ConsumerState<FinancesScreen> {
  FinanceSummaryDto? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    // Si es Employee, calcular resumen desde ingresos y egresos
    if (RoleHelper.isEmployee(ref)) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        
        final employeeService = ref.read(employeeFinanceServiceProvider);
        final incomeResponse = await employeeService.getIncome(
          startDate: startOfMonth,
          endDate: endOfMonth,
        );
        final expensesResponse = await employeeService.getExpenses(
          startDate: startOfMonth,
          endDate: endOfMonth,
        );
        
        final incomeThisMonth = incomeResponse.items.fold<double>(0.0, (sum, item) => sum + item.amount);
        final expensesThisMonth = expensesResponse.items.fold<double>(0.0, (sum, item) => sum + item.amount);
        final profitThisMonth = incomeThisMonth - expensesThisMonth;
        
        final totalIncomeResponse = await employeeService.getIncome();
        final totalExpensesResponse = await employeeService.getExpenses();
        
        final totalIncome = totalIncomeResponse.items.fold<double>(0.0, (sum, item) => sum + item.amount);
        final totalExpenses = totalExpensesResponse.items.fold<double>(0.0, (sum, item) => sum + item.amount);
        final netProfit = totalIncome - totalExpenses;
        
        if (mounted) {
          setState(() {
            _summary = FinanceSummaryDto(
              incomeThisMonth: incomeThisMonth,
              expensesThisMonth: expensesThisMonth,
              profitThisMonth: profitThisMonth,
              totalIncome: totalIncome,
              totalExpenses: totalExpenses,
              netProfit: netProfit,
            );
            _isLoading = false;
            _errorMessage = null;
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
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final service = ref.read(barberServiceProvider);
      final summary = await service.getFinanceSummary();
      if (mounted) {
        setState(() {
          _summary = summary;
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

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    if (_summary == null) {
      return _ErrorState(
        errorMessage: _errorMessage,
        onRetry: _loadSummary,
        textColor: textColor,
        mutedColor: mutedColor,
        accentColor: accentColor,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSummary,
      color: accentColor,
      child: Container(
        color: bgColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(
                  'Finanzas',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            // Card principal con ganancia del mes
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildProfitCard(textColor, mutedColor, accentColor),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Stats del mes
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildMonthStats(textColor, mutedColor, cardColor, borderColor, accentColor),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Accesos rápidos
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildQuickAccess(textColor, mutedColor, cardColor, borderColor, accentColor),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Resumen total
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _buildTotalSummary(textColor, mutedColor, cardColor, borderColor, accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildProfitCard(Color textColor, Color mutedColor, Color accentColor) {
    final profit = _summary!.profitThisMonth;
    final isPositive = profit >= 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPositive
              ? [accentColor, accentColor.withOpacity(0.8)]
              : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? accentColor : const Color(0xFFEF4444)).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPositive ? Iconsax.arrow_up_2 : Iconsax.arrow_down_2,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Ganancia del Mes',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            MoneyFormatter.formatCordobas(profit.abs()),
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPositive ? 'Ingresos superan egresos' : 'Egresos superan ingresos',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthStats(
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accentColor,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final cardSpacing = isSmallScreen ? 8.0 : 10.0;
    
    return Row(
      children: [
        Expanded(
          child: _FinanceMiniCard(
            icon: Iconsax.arrow_down,
            value: MoneyFormatter.formatCordobas(_summary!.incomeThisMonth),
            label: 'Ingresos',
            color: const Color(0xFF22C55E),
            textColor: textColor,
            mutedColor: mutedColor,
            cardColor: cardColor,
            borderColor: borderColor,
          ),
        ),
        SizedBox(width: cardSpacing),
        Expanded(
          child: _FinanceMiniCard(
            icon: Iconsax.arrow_up,
            value: MoneyFormatter.formatCordobas(_summary!.expensesThisMonth),
            label: 'Egresos',
            color: const Color(0xFFEF4444),
            textColor: textColor,
            mutedColor: mutedColor,
            cardColor: cardColor,
            borderColor: borderColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccess(
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accesos Rápidos',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAccessButton(
                title: 'Ingresos',
                icon: Iconsax.arrow_down,
                color: const Color(0xFF22C55E),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const IncomeScreen()),
                  );
                },
                textColor: textColor,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAccessButton(
                title: 'Egresos',
                icon: Iconsax.arrow_up,
                color: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ExpensesScreen()),
                  );
                },
                textColor: textColor,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalSummary(
    Color textColor,
    Color mutedColor,
    Color cardColor,
    Color borderColor,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Iconsax.chart_2, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Resumen Total',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryItem(
            label: 'Ingresos Totales',
            value: MoneyFormatter.formatCordobas(_summary!.totalIncome),
            color: const Color(0xFF22C55E),
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 12),
          _SummaryItem(
            label: 'Egresos Totales',
            value: MoneyFormatter.formatCordobas(_summary!.totalExpenses),
            color: const Color(0xFFEF4444),
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ganancia Neta',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Text(
                  MoneyFormatter.formatCordobas(_summary!.netProfit),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
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
}

class _FinanceMiniCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color textColor;
  final Color mutedColor;
  final Color cardColor;
  final Color borderColor;

  const _FinanceMiniCard({
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
    final iconSize = isSmallScreen ? 30.0 : (isMediumScreen ? 33.0 : 36.0);
    final iconInnerSize = isSmallScreen ? 16.0 : 18.0;
    final padding = isSmallScreen ? 10.0 : (isMediumScreen ? 12.0 : 14.0);
    final fontSize = isSmallScreen ? 14.0 : (isMediumScreen ? 15.0 : 16.0);
    final labelFontSize = isSmallScreen ? 10.0 : 11.0;
    final iconSpacing = isSmallScreen ? 10.0 : 12.0;
    
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: Colors.white, size: iconInnerSize),
          ),
          SizedBox(height: iconSpacing),
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
    );
  }
}

class _QuickAccessButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Color textColor;
  final Color cardColor;
  final Color borderColor;

  const _QuickAccessButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.textColor,
    required this.cardColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              Icon(Iconsax.arrow_right_3, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;
  final Color mutedColor;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: mutedColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
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
            Icon(Iconsax.wallet, color: mutedColor, size: 64),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar la información',
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
