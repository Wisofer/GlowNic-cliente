import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../main_theme.dart';
import '../../services/storage/credentials_storage.dart';
import '../../utils/audio_helper.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _userFocused = false;
  bool _passFocused = false;
  bool _rememberCredentials = false;

  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();
  final _credentialsStorage = CredentialsStorage();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _userFocus.addListener(() => setState(() => _userFocused = _userFocus.hasFocus));
    _passFocus.addListener(() => setState(() => _passFocused = _passFocus.hasFocus));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final credentials = await _credentialsStorage.loadCredentials();
      if (credentials['username'] != null && credentials['password'] != null) {
        setState(() {
          _userController.text = credentials['username']!;
          _passwordController.text = credentials['password']!;
          _rememberCredentials = true;
        });
      }
    } catch (e) {
      // Ignorar errores al cargar
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final success = await authNotifier.login(
        _userController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (!success) {
        final authState = ref.read(authNotifierProvider);
        // Reproducir audio de error
        AudioHelper.playError();
        
        setState(() {
          _errorMessage = authState.errorMessage ?? 'Credenciales inválidas';
        });
      } else {
        // Reproducir audio de éxito
        AudioHelper.playSuccess();
        
        if (_rememberCredentials) {
          await _credentialsStorage.saveCredentials(
            _userController.text.trim(),
            _passwordController.text,
          );
        } else {
          await _credentialsStorage.clearCredentials();
        }
      }
    } catch (e) {
      // Reproducir audio de error
      AudioHelper.playError();
      
      setState(() {
        _errorMessage = 'Error de conexión';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _enterDemoMode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.enableDemoMode();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al entrar en modo demo: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const accentColor = Color(0xFFEC4899); // Rosa suave
    
    // Variables responsive
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;
    
    // Tamaños responsive
    final titleFontSize = isSmallScreen ? 24.0 : (isMediumScreen ? 26.0 : 28.0);
    final subtitleFontSize = isSmallScreen ? 12.0 : 14.0;
    final horizontalPadding = isSmallScreen ? 20.0 : (isMediumScreen ? 24.0 : 32.0);
    final topSpacing = isSmallScreen ? 20.0 : (screenHeight < 700 ? 30.0 : 40.0);
    final fieldSpacing = isSmallScreen ? 12.0 : 16.0;
    final buttonHeight = isSmallScreen ? 48.0 : 52.0;
    const accentLight = Color(0xFFF472B6);
    const bgColor = Color(0xFFFFF1F5);
    const cardColor = Colors.white;
    const textColor = Color(0xFF1F2937);
    const mutedColor = Color(0xFF6B7280);
    const borderColor = Color(0xFFD1D5DB);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemMovilTheme.getStatusBarStyle(false),
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // Fondo decorativo con gradiente
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withAlpha(5),
                      accentLight.withAlpha(10),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),

            // Elementos decorativos elegantes y femeninos
            Positioned(
              top: -50,
              right: -50,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animationController.value * 0.1,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accentColor.withAlpha(20),
                            accentColor.withAlpha(5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Icon(
                        Iconsax.star1,
                        color: accentColor.withAlpha(30),
                        size: 80,
                      ),
                    ),
                  );
                },
              ),
            ),

            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentLight.withAlpha(15),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Icon(
                  Iconsax.heart,
                  color: accentLight.withAlpha(20),
                  size: 60,
                ),
              ),
            ),

            // Contenido principal
            SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: topSpacing),

                      // Formulario minimalista sin card
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Título minimalista centrado
                            Text(
                              'Bienvenida',
                              style: GoogleFonts.inter(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 6),
                            Text(
                              'Inicia sesión para continuar',
                              style: GoogleFonts.inter(
                                fontSize: subtitleFontSize,
                                color: mutedColor,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isSmallScreen ? 20 : 28),

                            // Error message
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Iconsax.warning_2, color: Color(0xFFDC2626), size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: const Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Campo Email
                            _buildTextField(
                              context: context,
                              label: 'Email',
                              controller: _userController,
                              focusNode: _userFocus,
                              isFocused: _userFocused,
                              icon: Iconsax.sms,
                              keyboardType: TextInputType.emailAddress,
                              hintText: 'tu@email.com',
                              validator: (v) => v == null || v.isEmpty ? 'El email es requerido' : null,
                              accentColor: accentColor,
                              accentLight: accentLight,
                              textColor: textColor,
                              mutedColor: mutedColor,
                              borderColor: borderColor,
                              cardColor: cardColor,
                            ),

                            SizedBox(height: fieldSpacing),

                            // Campo Contraseña
                            _buildTextField(
                              context: context,
                              label: 'Contraseña',
                              controller: _passwordController,
                              focusNode: _passFocus,
                              isFocused: _passFocused,
                              icon: Iconsax.lock,
                              obscureText: _obscurePassword,
                              hintText: '••••••••',
                              validator: (v) => v == null || v.isEmpty ? 'La contraseña es requerida' : null,
                              accentColor: accentColor,
                              accentLight: accentLight,
                              textColor: textColor,
                              mutedColor: mutedColor,
                              borderColor: borderColor,
                              cardColor: cardColor,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                child: Icon(
                                  _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                                  color: mutedColor,
                                  size: 20,
                                ),
                              ),
                            ),

                            SizedBox(height: fieldSpacing),

                            // Recordar credenciales
                            Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _rememberCredentials,
                                    onChanged: (value) {
                                      setState(() => _rememberCredentials = value ?? false);
                                    },
                                    activeColor: accentColor,
                                    checkColor: Colors.white,
                                    side: BorderSide(
                                      color: _rememberCredentials ? accentColor : borderColor,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _rememberCredentials = !_rememberCredentials);
                                    },
                                    child: Text(
                                      'Recordar credenciales',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: isSmallScreen ? 24 : 28),

                          // Botón de login
                          SizedBox(
                            width: double.infinity,
                                height: buttonHeight,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: accentColor.withAlpha(150),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                      child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                              'Iniciar Sesión',
                                          style: GoogleFonts.inter(
                                                fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                          ),
                                        ),
                                            const SizedBox(width: 10),
                                            const Icon(Iconsax.arrow_right_3, size: 20),
                                      ],
                                    ),
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 20 : 24),

                          // Texto clickeable para ver demo
                          Center(
                            child: GestureDetector(
                              onTap: _isLoading ? null : _enterDemoMode,
                              child: Text(
                                'Ver demo',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _isLoading ? mutedColor.withAlpha(100) : accentColor,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Footer
                      Column(
                        children: [
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: isSmallScreen ? 6 : 8,
                            runSpacing: isSmallScreen ? 8 : 10,
                            children: [
                              _buildFeatureBadge(Iconsax.calendar_2, 'Citas', accentColor, mutedColor, borderColor),
                              _buildFeatureBadge(Iconsax.star1, 'Servicios', accentColor, mutedColor, borderColor),
                              _buildFeatureBadge(Iconsax.wallet, 'Finanzas', accentColor, mutedColor, borderColor),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 20 : 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Desarrollado por ',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: mutedColor.withAlpha(150),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  try {
                                    final uri = Uri.parse('https://www.cowib.es');
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } catch (e) {
                                    // Si no se puede abrir, intentar con el navegador por defecto
                                    try {
                                      final uri = Uri.parse('https://www.cowib.es');
                                      await launchUrl(uri, mode: LaunchMode.platformDefault);
                                    } catch (e2) {
                                      // Error al abrir URL
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('No se pudo abrir la página: ${e2.toString()}'),
                                            backgroundColor: const Color(0xFFEF4444),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                child: Text(
                                  'COWIB',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: isSmallScreen ? 24 : (screenHeight < 700 ? 32 : 40)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required IconData icon,
    required Color accentColor,
    required Color accentLight,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
    required Color cardColor,
    String? hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    required BuildContext context,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final inputFontSize = isSmallScreen ? 14.0 : 15.0;
    final hintFontSize = isSmallScreen ? 13.0 : 14.0;
    final iconSize = isSmallScreen ? 20.0 : 22.0;
    final inputPadding = isSmallScreen ? 12.0 : 14.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFocused ? accentColor : borderColor.withAlpha(100),
              width: isFocused ? 2 : 1.5,
            ),
            color: isFocused ? accentLight.withAlpha(20) : Colors.white.withAlpha(250),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: accentColor.withAlpha(15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            style: GoogleFonts.inter(
              fontSize: inputFontSize,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.inter(
                fontSize: hintFontSize,
                color: mutedColor.withAlpha(150),
              ),
              prefixIcon: Icon(
                icon,
                color: isFocused ? accentColor : mutedColor,
                size: iconSize,
              ),
              suffixIcon: suffixIcon != null
                  ? Padding(
                      padding: EdgeInsets.only(right: isSmallScreen ? 12 : 16),
                      child: suffixIcon,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: inputPadding,
                vertical: inputPadding,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label, Color accentColor, Color mutedColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withAlpha(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
