import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Tipografía Poppins para toda la app
class SystemMovilTypography {
  // Títulos principales (H1)
  static TextStyle get h1 => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  // Títulos secundarios (H2)
  static TextStyle get h2 => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
  );

  // Subtítulos (H3)
  static TextStyle get h3 => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  // Texto del cuerpo (Body)
  static TextStyle get body => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
  );

  // Texto pequeño (Caption)
  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  // Texto muy pequeño (Small)
  static TextStyle get small => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  // Botones
  static TextStyle get button => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // Labels de formularios
  static TextStyle get label => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  // Enlaces
  static TextStyle get link => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
  );
}

// Paleta de colores para GlowNic - Rosa suave tipo salón de belleza
class SystemMovilColors {
  // Color principal - Rosa suave (elegante, femenino, moderno)
  static const Color primary = Color(0xFFEC4899); // Rosa principal
  static const Color primaryLight = Color(0xFFF472B6); // Rosa claro
  static const Color primaryDark = Color(0xFFDB2777); // Rosa oscuro
  
  // Color secundario - Púrpura (accesorios, detalles)
  static const Color secondary = Color(0xFFC026D3);
  static const Color secondaryLight = Color(0xFFD946EF);
  static const Color secondaryDark = Color(0xFFA21CAF);
  
  // Color de éxito - Rosa más intenso para confirmaciones
  static const Color success = Color(0xFFEC4899);
  static const Color successLight = Color(0xFFF472B6);
  static const Color successDark = Color(0xFFDB2777);
  
  // Colores neutros - Suaves y limpios
  static const Color background = Color(0xFFFFF1F5); // Rosa muy claro de fondo
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1F2937); // Gris oscuro suave
  static const Color onSurfaceVariant = Color(0xFF6B7280); // Gris medio
  static const Color outline = Color(0xFFD1D5DB); // Borde suave
  
  // Colores de estado
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53E3E);
  static const Color info = Color(0xFF17A2B8);
  
  // Colores específicos de la imagen
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color urgentTag = Color(0xFFE53E3E);
  static const Color urgentTagBackground = Color(0xFFFFEBEE);
  static const Color categoryTag = Color(0xFF1976D2);
  static const Color categoryTagBackground = Color(0xFFE3F2FD);
  static const Color timeTag = Color(0xFFFF6B35);
  static const Color timeTagBackground = Color(0xFFFFF3E0);
}

final kColorScheme = ColorScheme.fromSeed(
  seedColor: SystemMovilColors.primary,
  primary: SystemMovilColors.primary,
  secondary: SystemMovilColors.secondary,
  surface: SystemMovilColors.surface,
  background: SystemMovilColors.background,
  error: SystemMovilColors.error,
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onSurface: SystemMovilColors.onSurface,
  onBackground: SystemMovilColors.onSurface,
);

final kDarkColorScheme = ColorScheme.fromSeed(
  brightness: Brightness.dark,
  seedColor: SystemMovilColors.primary,
  primary: SystemMovilColors.primaryLight,
  secondary: SystemMovilColors.secondaryLight,
  surface: const Color(0xFF1A1A1A),
  background: const Color(0xFF121212),
  error: SystemMovilColors.error,
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onSurface: Colors.white,
  onBackground: Colors.white,
);

final lightTheme = ThemeData().copyWith(
  colorScheme: kColorScheme,
  scaffoldBackgroundColor: SystemMovilColors.background,
  useMaterial3: true,
  appBarTheme: const AppBarTheme().copyWith(
    backgroundColor: SystemMovilColors.surface,
    foregroundColor: SystemMovilColors.onSurface,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: SystemMovilTypography.h3.copyWith(
      color: SystemMovilColors.onSurface,
    ),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  ),
  textTheme: GoogleFonts.poppinsTextTheme().copyWith(
    // Títulos principales
    headlineLarge: SystemMovilTypography.h1.copyWith(
      color: SystemMovilColors.onSurface,
    ),
    headlineMedium: SystemMovilTypography.h2.copyWith(
      color: SystemMovilColors.onSurface,
    ),
    headlineSmall: SystemMovilTypography.h3.copyWith(
      color: SystemMovilColors.onSurface,
    ),
    // Títulos de sección
    titleLarge: SystemMovilTypography.h3.copyWith(
      color: SystemMovilColors.onSurface,
    ),
    titleMedium: SystemMovilTypography.caption.copyWith(
      color: SystemMovilColors.onSurface,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: SystemMovilTypography.label.copyWith(
      color: SystemMovilColors.onSurface,
    ),
    // Texto del cuerpo
    bodyLarge: SystemMovilTypography.body.copyWith(
      color: SystemMovilColors.onSurface,
    ),
    bodyMedium: SystemMovilTypography.caption.copyWith(
      color: SystemMovilColors.onSurfaceVariant,
    ),
    bodySmall: SystemMovilTypography.small.copyWith(
      color: SystemMovilColors.onSurfaceVariant,
    ),
    // Labels
    labelLarge: SystemMovilTypography.button.copyWith(
      color: Colors.white,
    ),
    labelMedium: SystemMovilTypography.label.copyWith(
      color: SystemMovilColors.onSurfaceVariant,
    ),
    labelSmall: SystemMovilTypography.small.copyWith(
      color: SystemMovilColors.onSurfaceVariant,
    ),
  ),
  cardTheme: CardThemeData(
    color: SystemMovilColors.surface,
    elevation: 2,
    shadowColor: SystemMovilColors.outline,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: SystemMovilColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: SystemMovilTypography.button,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: SystemMovilColors.primary,
      textStyle: SystemMovilTypography.link,
    ),
  ),
);

final darkTheme = ThemeData().copyWith(
  brightness: Brightness.dark,
  colorScheme: kDarkColorScheme,
  scaffoldBackgroundColor: const Color(0xFF121212),
  textTheme: GoogleFonts.poppinsTextTheme().copyWith(
    // Títulos principales
    headlineLarge: SystemMovilTypography.h1.copyWith(
      color: Colors.white,
    ),
    headlineMedium: SystemMovilTypography.h2.copyWith(
      color: Colors.white,
    ),
    headlineSmall: SystemMovilTypography.h3.copyWith(
      color: Colors.white,
    ),
    // Títulos de sección
    titleLarge: SystemMovilTypography.h3.copyWith(
      color: Colors.white,
    ),
    titleMedium: SystemMovilTypography.caption.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: SystemMovilTypography.label.copyWith(
      color: Colors.white,
    ),
    // Texto del cuerpo
    bodyLarge: SystemMovilTypography.body.copyWith(
      color: Colors.white,
    ),
    bodyMedium: SystemMovilTypography.caption.copyWith(
      color: Colors.white70,
    ),
    bodySmall: SystemMovilTypography.small.copyWith(
      color: Colors.white60,
    ),
    // Labels
    labelLarge: SystemMovilTypography.button.copyWith(
      color: Colors.white,
    ),
    labelMedium: SystemMovilTypography.label.copyWith(
      color: Colors.white70,
    ),
    labelSmall: SystemMovilTypography.small.copyWith(
      color: Colors.white60,
    ),
  ),
  appBarTheme: const AppBarTheme().copyWith(
    backgroundColor: const Color(0xFF1A1A1A),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: SystemMovilTypography.h3.copyWith(
      color: Colors.white,
    ),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF1A1A1A),
    elevation: 4,
    shadowColor: Colors.black,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: SystemMovilColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: SystemMovilTypography.button,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: SystemMovilColors.primary,
      textStyle: SystemMovilTypography.link,
    ),
  ),
);

// Clase de compatibilidad para mantener el código existente
class SystemMovilTextStyles {
  static TextStyle get headlineLarge => SystemMovilTypography.h1.copyWith(
    color: SystemMovilColors.onSurface,
  );

  static TextStyle get headlineMedium => SystemMovilTypography.h2.copyWith(
    color: SystemMovilColors.onSurface,
  );

  static TextStyle get headlineSmall => SystemMovilTypography.h3.copyWith(
    color: SystemMovilColors.onSurface,
  );

  static TextStyle get titleLarge => SystemMovilTypography.h3.copyWith(
    color: SystemMovilColors.onSurface,
  );

  static TextStyle get titleMedium => SystemMovilTypography.caption.copyWith(
    color: SystemMovilColors.onSurface,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get titleSmall => SystemMovilTypography.label.copyWith(
    color: SystemMovilColors.onSurface,
  );

  static TextStyle get bodyLarge => SystemMovilTypography.body.copyWith(
    color: SystemMovilColors.onSurface,
  );

  static TextStyle get bodyMedium => SystemMovilTypography.caption.copyWith(
    color: SystemMovilColors.onSurfaceVariant,
  );

  static TextStyle get bodySmall => SystemMovilTypography.small.copyWith(
    color: SystemMovilColors.onSurfaceVariant,
  );

  static TextStyle get labelLarge => SystemMovilTypography.button.copyWith(
    color: Colors.white,
  );

  static TextStyle get labelMedium => SystemMovilTypography.label.copyWith(
    color: SystemMovilColors.onSurfaceVariant,
  );

  static TextStyle get labelSmall => SystemMovilTypography.small.copyWith(
    color: SystemMovilColors.onSurfaceVariant,
  );

  static TextStyle get buttonLarge => SystemMovilTypography.button.copyWith(
    color: Colors.white,
  );

  static TextStyle get buttonMedium => SystemMovilTypography.button.copyWith(
    fontSize: 14,
    color: Colors.white,
  );

  static TextStyle get buttonSmall => SystemMovilTypography.button.copyWith(
    fontSize: 12,
    color: Colors.white,
  );
}

class SystemMovilTheme {
  static ThemeData get lightTheme => lightTheme;
  
  // Helper para obtener el SystemUiOverlayStyle - siempre modo claro
  static SystemUiOverlayStyle getStatusBarStyle(bool isDark) {
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF1F5),
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );
  }
}