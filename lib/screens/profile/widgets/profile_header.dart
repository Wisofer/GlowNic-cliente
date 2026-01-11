import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/salon.dart';
import '../edit_profile_screen.dart';

class ProfileHeader extends StatelessWidget {
  final SalonDto profile;
  final VoidCallback onProfileUpdated;
  final Color textColor;
  final Color mutedColor;
  final Color cardColor;
  final Color borderColor;
  final Color accentColor;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
    required this.textColor,
    required this.mutedColor,
    required this.cardColor,
    required this.borderColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1A1A),
                  const Color(0xFF0F0F0F),
                ]
              : [
                  const Color(0xFFFFF1F5),
                  Colors.white,
                ],
        ),
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar compacto
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor,
                      const Color(0xFFDB2777),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: Container(
                    color: Colors.white,
                    child: Image.asset(
                      'assets/images/logo5.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/logo5.png',
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Información compacta sin cajas
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              height: 1.2,
                            ),
                          ),
                        ),
                        // Botón editar compacto
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProfileScreen(profile: profile),
                                ),
                              );
                              if (updated == true) {
                                onProfileUpdated();
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: accentColor.withAlpha(10),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Iconsax.edit_2,
                                color: accentColor,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (profile.email != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Iconsax.sms, size: 14, color: mutedColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              profile.email!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: mutedColor,
                                height: 1.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Iconsax.call, size: 14, color: mutedColor),
                        const SizedBox(width: 6),
                        Text(
                          profile.phone,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: mutedColor,
                            height: 1.3,
                          ),
                        ),
                      ],
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
}
