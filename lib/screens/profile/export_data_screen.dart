import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import '../../services/api/export_service.dart';

class ExportDataScreen extends ConsumerStatefulWidget {
  const ExportDataScreen({super.key});

  @override
  ConsumerState<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends ConsumerState<ExportDataScreen> {
  bool _isExporting = false;
  String? _exportingType;

  Future<void> _exportReport(String type, String format) async {
    setState(() {
      _isExporting = true;
      _exportingType = type;
    });

    try {
      final service = ref.read(exportServiceProvider);
      File? file;

      switch (type) {
        case 'Citas':
          file = await service.exportAppointments(format: format);
          break;
        case 'Financiero':
          file = await service.exportFinances(format: format);
          break;
        case 'Clientes':
          file = await service.exportClients(format: format);
          break;
        case 'Backup Completo':
          file = await service.exportBackup();
          break;
      }

      if (mounted && file != null) {
        setState(() {
          _isExporting = false;
          _exportingType = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte de $type generado exitosamente'),
            backgroundColor: const Color(0xFFEC4899),
          ),
        );

        // Compartir archivo
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Reporte $type - GlowNic',
        );
      }
    } on DioException catch (e) {
      String message = 'Error al exportar el reporte';
      
      // Manejar diferentes tipos de respuesta de error
      if (e.response?.data != null) {
        try {
          // Si data es una lista de bytes (Uint8List), decodificarla
          if (e.response!.data is List<int>) {
            final bytes = e.response!.data as List<int>;
            final jsonString = utf8.decode(bytes);
            final jsonData = json.decode(jsonString);
            message = jsonData['message'] ?? message;
          } 
          // Si data es un Map, extraer el mensaje directamente
          else if (e.response!.data is Map) {
            message = e.response!.data['message'] ?? message;
          }
          // Si data es un String, usarlo directamente
          else if (e.response!.data is String) {
            message = e.response!.data;
          }
        } catch (decodeError) {
          // Si falla la decodificación, usar mensaje por defecto
          message = 'Error del servidor. Por favor, intenta más tarde.';
        }
      }
      
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportingType = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportingType = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _showFormatDialog(String type) async {
    final format = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Seleccionar Formato',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.document),
              title: const Text('CSV'),
              onTap: () => Navigator.pop(context, 'csv'),
            ),
            ListTile(
              leading: const Icon(Iconsax.document),
              title: const Text('Excel'),
              onTap: () => Navigator.pop(context, 'excel'),
            ),
            if (type != 'Backup Completo')
              ListTile(
                leading: const Icon(Iconsax.document),
                title: const Text('PDF'),
                onTap: () => Navigator.pop(context, 'pdf'),
              ),
          ],
        ),
      ),
    );

    if (format != null) {
      await _exportReport(type, format);
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
          'Exportar Datos',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: isDark ? const Color(0xFF0A0A0B) : const Color(0xFFFFF1F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exporta tus datos y reportes',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: mutedColor,
              ),
            ),
            const SizedBox(height: 24),

            // Exportar reportes
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reportes',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ExportOption(
                    icon: Iconsax.document_download,
                    title: 'Reporte de Citas',
                    subtitle: 'Exporta todas tus citas del mes',
                    onTap: () => _showFormatDialog('Citas'),
                    isLoading: _isExporting && _exportingType == 'Citas',
                    textColor: textColor,
                    mutedColor: mutedColor,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 12),
                  _ExportOption(
                    icon: Iconsax.wallet_money,
                    title: 'Reporte Financiero',
                    subtitle: 'Exporta ingresos y egresos',
                    onTap: () => _showFormatDialog('Financiero'),
                    isLoading: _isExporting && _exportingType == 'Financiero',
                    textColor: textColor,
                    mutedColor: mutedColor,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 12),
                  _ExportOption(
                    icon: Iconsax.profile_2user,
                    title: 'Reporte de Clientes',
                    subtitle: 'Exporta lista de clientes',
                    onTap: () => _showFormatDialog('Clientes'),
                    isLoading: _isExporting && _exportingType == 'Clientes',
                    textColor: textColor,
                    mutedColor: mutedColor,
                    accentColor: accentColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Backup de datos
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backup',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea una copia de seguridad de todos tus datos',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_isExporting && _exportingType == 'Backup Completo') ? null : () => _exportReport('Backup Completo', 'json'),
                      icon: (_isExporting && _exportingType == 'Backup Completo')
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Iconsax.document_cloud),
                      label: Text((_isExporting && _exportingType == 'Backup Completo') ? 'Exportando...' : 'Crear Backup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLoading;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLoading = false,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    )
                  : Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLoading ? 'Exportando...' : subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLoading)
              Icon(Iconsax.arrow_right_3, color: mutedColor, size: 18),
          ],
        ),
      ),
    );
  }
}

