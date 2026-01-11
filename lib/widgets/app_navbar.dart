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
    _NavItem(icon: Iconsax.home, activeIcon: Iconsax.home_2, label: 'Inicio', id: 'dashboard'),
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
      // Dueños ven todas las opciones: Inicio, Citas, Servicios, Finanzas, Perfil
      return _allItems;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    
    // Responsive: detectar tamaño de pantalla
    final isSmallScreen = size.width < 360;
    final isTablet = size.width >= 600;
    
    // Tamaños adaptativos según dispositivo
    final iconSize = isSmallScreen ? 18.0 : (isTablet ? 24.0 : 20.0);
    final fontSize = isSmallScreen ? 8.0 : (isTablet ? 11.0 : 9.0);
    final horizontalPadding = isSmallScreen ? 6.0 : (isTablet ? 16.0 : 10.0);
    final verticalPadding = isSmallScreen ? 3.0 : (isTablet ? 6.0 : 4.0);
    final itemSpacing = isSmallScreen ? 2.0 : (isTablet ? 5.0 : 3.0);
    final containerPadding = isSmallScreen ? 6.0 : (isTablet ? 12.0 : 8.0);

    final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFD1D5DB);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF6B7280);
    const accentColor = Color(0xFFEC4899); // Rosa suave

    final visibleItems = _getVisibleItems(ref);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
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
          padding: EdgeInsets.symmetric(horizontal: containerPadding, vertical: containerPadding * 0.75),
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
                iconSize: iconSize,
                fontSize: fontSize,
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding,
                itemSpacing: itemSpacing,
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
  final double iconSize;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double itemSpacing;

  const _NavItemWidget({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    this.onTap,
    this.badgeCount = 0,
    this.iconSize = 20.0,
    this.fontSize = 9.0,
    this.horizontalPadding = 10.0,
    this.verticalPadding = 4.0,
    this.itemSpacing = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withAlpha(15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge solo si hay citas pendientes
            badgeCount > 0
                ? badges.Badge(
                    badgeContent: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: GoogleFonts.inter(
                        fontSize: fontSize * 0.9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    badgeStyle: badges.BadgeStyle(
                      badgeColor: const Color(0xFFEF4444),
                      padding: EdgeInsets.all(fontSize * 0.3),
                      borderRadius: BorderRadius.circular(8),
                      elevation: 0,
                    ),
                    child: Icon(icon, color: color, size: iconSize),
                  )
                : Icon(icon, color: color, size: iconSize),
            SizedBox(height: itemSpacing),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: fontSize,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
