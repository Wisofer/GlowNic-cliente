import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../models/salon.dart';
import '../../services/api/salon_service.dart';
import '../../utils/audio_helper.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final SalonDto profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _businessNameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _businessNameController = TextEditingController(text: widget.profile.businessName ?? '');
    _phoneController = TextEditingController(text: widget.profile.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre es requerido'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El teléfono es requerido'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(salonServiceProvider);
      await service.updateProfile(
        name: _nameController.text.trim(),
        businessName: _businessNameController.text.trim().isEmpty
            ? null
            : _businessNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        // Reproducir audio de éxito
        AudioHelper.playSuccess();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Color(0xFFEC4899),
          ),
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Error al actualizar el perfil';
      if (mounted) {
        // Reproducir audio de error
        AudioHelper.playError();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Reproducir audio de error
        AudioHelper.playError();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
    const accentColor = Color(0xFFEC4899);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Información Personal',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: isDark ? const Color(0xFF0A0A0B) : const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edita tu información personal',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: mutedColor,
              ),
            ),
            const SizedBox(height: 24),

            // Nombre
            _TextField(
              controller: _nameController,
              label: 'Nombre',
              icon: Iconsax.user,
              hintText: 'Tu nombre completo',
              textColor: textColor,
              mutedColor: mutedColor,
              cardColor: cardColor,
              borderColor: borderColor,
              accentColor: accentColor,
            ),
            const SizedBox(height: 16),

            // Nombre del negocio
            _TextField(
              controller: _businessNameController,
              label: 'Nombre del Negocio',
              icon: Iconsax.shop,
              hintText: 'Nombre de tu salón (opcional)',
              textColor: textColor,
              mutedColor: mutedColor,
              cardColor: cardColor,
              borderColor: borderColor,
              accentColor: accentColor,
              optional: true,
            ),
            const SizedBox(height: 16),

            // Teléfono
            _TextField(
              controller: _phoneController,
              label: 'Teléfono',
              icon: Iconsax.call,
              hintText: 'Tu número de teléfono',
              textColor: textColor,
              mutedColor: mutedColor,
              cardColor: cardColor,
              borderColor: borderColor,
              accentColor: accentColor,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),

            // Botón guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Guardar Cambios',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hintText;
  final Color textColor;
  final Color mutedColor;
  final Color cardColor;
  final Color borderColor;
  final Color accentColor;
  final bool optional;
  final TextInputType? keyboardType;

  const _TextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.hintText,
    required this.textColor,
    required this.mutedColor,
    required this.cardColor,
    required this.borderColor,
    required this.accentColor,
    this.optional = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (optional ? ' (Opcional)' : ''),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: textColor,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: mutedColor,
              ),
              prefixIcon: Icon(icon, color: accentColor, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

