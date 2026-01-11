import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_navbar.dart';
import '../utils/role_helper.dart';
import '../providers/pending_appointments_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'appointments/appointments_screen.dart';
import 'services/services_screen.dart';
import 'finances/finances_screen.dart';
import 'profile/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey();
  
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Cuando la app vuelve al foreground, actualizar contador de pendientes
    if (state == AppLifecycleState.resumed) {
      ref.read(pendingAppointmentsProvider.notifier).refresh();
    }
  }

  // Mapeo de índices visibles a índices reales de pantallas
  int _getRealIndex(int visibleIndex) {
    final isEmployee = RoleHelper.isEmployee(ref);
    
    if (isEmployee) {
      // Para trabajadores: visibleIndex 0 = Citas (real 1), 1 = Servicios (real 2), 2 = Finanzas (real 3), 3 = Perfil (real 4)
      const employeeMapping = [1, 2, 3, 4];
      return employeeMapping[visibleIndex];
    } else {
      // Para dueños: índice visible = índice real
      return visibleIndex;
    }
  }

  int _getVisibleIndex(int realIndex) {
    final isEmployee = RoleHelper.isEmployee(ref);
    
    if (isEmployee) {
      // Mapeo inverso para trabajadores
      const employeeMapping = {1: 0, 2: 1, 3: 2, 4: 3};
      return employeeMapping[realIndex] ?? 0;
    } else {
      return realIndex;
    }
  }

  void _onTabChanged(int visibleIndex) {
    final realIndex = _getRealIndex(visibleIndex);
    final wasDashboard = _selectedIndex == 0 && !RoleHelper.isEmployee(ref);
    
    setState(() {
      _selectedIndex = realIndex;
    });
    
    // Refrescar dashboard solo si se vuelve a mostrar después de estar en otra pestaña
    if (realIndex == 0 && !wasDashboard && !RoleHelper.isEmployee(ref)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _dashboardKey.currentState?.refresh();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEmployee = RoleHelper.isEmployee(ref);
    
    final bgColor = isDark ? const Color(0xFF0A0A0B) : const Color(0xFFFFF1F5);
    
    // Inicializar índice según el rol (solo una vez)
    if (!_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = isEmployee ? 1 : 0; // Employee inicia en Citas (1), Barber en Dashboard (0)
            _initialized = true;
          });
        }
      });
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemMovilTheme.getStatusBarStyle(isDark),
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header fijo - Solo en Dashboard (y solo para Barber)
              if (_selectedIndex == 0 && RoleHelper.isBarber(ref)) const AppHeader(),

              // Contenido
              Expanded(
                child: Builder(
                  builder: (context) {
                    final isEmployee = RoleHelper.isEmployee(ref);
                    final screens = <Widget>[
                      // Índice 0: Dashboard (solo para Barber)
                      isEmployee
                          ? const SizedBox.shrink()
                          : DashboardScreen(
                              key: _dashboardKey,
                              onNavigateToAppointments: () {
                                final visibleIndex = _getVisibleIndex(1);
                                _onTabChanged(visibleIndex);
                              },
                              onNavigateToServices: () {
                                final visibleIndex = _getVisibleIndex(2);
                                _onTabChanged(visibleIndex);
                              },
                              onNavigateToFinances: () {
                                final visibleIndex = _getVisibleIndex(3);
                                _onTabChanged(visibleIndex);
                              },
                            ),
                      // Índice 1: Citas
                      const AppointmentsScreen(),
                      // Índice 2: Servicios (para Barber y Employee, pero Employee solo lectura)
                      const ServicesScreen(),
                      // Índice 3: Finanzas
                      const FinancesScreen(),
                      // Índice 4: Perfil
                      const ProfileScreen(),
                    ];
                    
                    return IndexedStack(
                      index: _selectedIndex,
                      children: screens,
                    );
                  },
                ),
              ),

              // Navbar fijo
              AppNavbar(
                currentIndex: _getVisibleIndex(_selectedIndex),
                onTap: _onTabChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
