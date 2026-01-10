import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:badges/badges.dart' as badges;
import '../utils/role_helper.dart';
import '../providers/pending_appointments_provider.dart';

class AppNavbar extends ConsumerWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const AppNavbar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
  });

  static const _allItems = [
    _NavItem(icon: Iconsax.heart, activeIcon: Iconsax.heart5, label: 'Inicio', id: 'dashboard'),
    _NavItem(icon: Iconsax.calendar, activeIcon: Iconsax.calendar_tick, label: 'Citas', id: 'appointments'),
    _NavItem(icon: Iconsax.brush_1, activeIcon: Iconsax.brush, label: 'Servicios', id: 'services'),
    _NavItem(icon: Iconsax.card, activeIcon: Iconsax.card_send, label: 'Finanzas', id: 'finances'),
    _NavItem(icon: Iconsax.user, activeIcon: Iconsax.user_square, label: 'Perfil', id: 'profile'),
  ];

  List<_NavItem> _getVisibleItems(WidgetRef ref) {
    final isEmployee = RoleHelper.isEmployee(ref);
    
    if (isEmployee) {
      // Trabajadores ven: Citas, Servicios (solo lectura), Finanzas, Perfil
      return _allItems.where((item) => 
        item.id == 'appointments' || 
        item.id == 'services' ||
        item.id == 'finances' || 
        item.id == 'profile'
      ).toList();
    } else {
      // Barberos ven todas las opciones: Inicio, Citas, Servicios, Finanzas, Perfil
      return _allItems;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFD1D5DB);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF6B7280);
    const accentColor = Color(0xFFEC4899); // Rosa suave

    final visibleItems = _getVisibleItems(ref);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(visibleItems.length, (index) {
              final item = visibleItems[index];
              final isActive = index == currentIndex;
              
              // Obtener contador de pendientes solo para el tab de citas
              final pendingCount = item.id == 'appointments' 
                  ? ref.watch(pendingAppointmentsProvider)
                  : 0;

              return _NavItemWidget(
                icon: isActive ? item.activeIcon : item.icon,
                label: item.label,
                isActive: isActive,
                activeColor: accentColor,
                inactiveColor: mutedColor,
                onTap: () => onTap?.call(index),
                badgeCount: item.id == 'appointments' ? pendingCount : 0,
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String id;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.id,
  });
}

class _NavItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback? onTap;
  final int badgeCount;

  const _NavItemWidget({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withAlpha(15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge solo si hay citas pendientes
            badgeCount > 0
                ? badges.Badge(
                    badgeContent: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    badgeStyle: badges.BadgeStyle(
                      badgeColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.all(4),
                      borderRadius: BorderRadius.circular(8),
                      elevation: 0,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  )
                : Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
