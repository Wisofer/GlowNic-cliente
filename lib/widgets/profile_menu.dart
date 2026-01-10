import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class ProfileMenu {
  static void show(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProfileMenuSheet(
        ref: ref,
      ),
    );
  }
}

class _ProfileMenuSheet extends StatelessWidget {
  final WidgetRef ref;

  const _ProfileMenuSheet({
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);
    
    final user = ref.watch(authNotifierProvider).userProfile;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // User info
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Iconsax.user, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nombreCompleto ?? 'Usuario',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Text(
                      user?.role ?? 'Operador',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Divider(color: borderColor),
          const SizedBox(height: 16),

          // Menu options
          _MenuOption(
            icon: Iconsax.user_edit,
            title: 'Editar perfil',
            color: textColor,
            mutedColor: mutedColor,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
          _MenuOption(
            icon: Iconsax.setting_2,
            title: 'Configuración',
            color: textColor,
            mutedColor: mutedColor,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
          _MenuOption(
            icon: Iconsax.info_circle,
            title: 'Acerca de',
            color: textColor,
            mutedColor: mutedColor,
            onTap: () => Navigator.pop(context),
          ),

          const SizedBox(height: 16),
          Divider(color: borderColor),
          const SizedBox(height: 16),

          // Logout
          _MenuOption(
            icon: Iconsax.logout,
            title: 'Cerrar sesión',
            color: const Color(0xFFDC2626),
            mutedColor: mutedColor,
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context, ref, cardColor, textColor, mutedColor);
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref, 
      Color cardColor, Color textColor, Color mutedColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cerrar sesión',
          style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w600),
        ),
        content: Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: GoogleFonts.inter(color: mutedColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.inter(color: mutedColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Salir', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Color mutedColor;
  final VoidCallback onTap;

  const _MenuOption({
    required this.icon,
    required this.title,
    required this.color,
    required this.mutedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          Icon(Iconsax.arrow_right_3, color: mutedColor, size: 18),
        ],
      ),
    );
  }
}

