import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../models/salon.dart';
import '../../models/auth.dart';
import '../../services/api/salon_service.dart';

class QrCodeScreen extends ConsumerStatefulWidget {
  final SalonDto profile;

  const QrCodeScreen({super.key, required this.profile});

  @override
  ConsumerState<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends ConsumerState<QrCodeScreen> {
  QrResponse? _qrData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQrCode();
  }

  Future<void> _loadQrCode() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(salonServiceProvider);
      final qrData = await service.getQrCode();
      if (mounted) {
        setState(() {
          _qrData = qrData;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data?['message'] ?? 'Error al cargar el QR'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _shareQr() async {
    if (_qrData == null) return;
    
    try {
      // Decodificar el Base64 del QR
      final base64String = _qrData!.qrCode;
      
      // Remover el prefijo "data:image/png;base64," si existe
      final cleanBase64 = base64String.contains(',') 
          ? base64String.split(',').last 
          : base64String;
      
      // Decodificar Base64 a bytes
      final bytes = base64Decode(cleanBase64);
      
      // Obtener directorio temporal
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png');
      
      // Escribir el archivo
      await file.writeAsBytes(bytes);
      
      // Crear XFile para compartir
      final xFile = XFile(file.path);
      
      // Texto del mensaje
      final message = 'Escanea este código QR para agendar tu cita con ${widget.profile.name}\n\n${_qrData!.url}';
      
      // Compartir la imagen PNG con el mensaje
      await Share.shareXFiles(
        [xFile],
        text: message,
        subject: 'Código QR - ${widget.profile.businessName ?? widget.profile.name}',
      );
      
      // Limpiar archivo temporal después de compartir (opcional, se limpia automáticamente)
      // await file.delete();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir el QR: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
          'Código QR',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading && _qrData != null)
            IconButton(
              icon: const Icon(Iconsax.refresh),
              onPressed: _loadQrCode,
              tooltip: 'Actualizar',
            ),
        ],
      ),
      backgroundColor: isDark ? const Color(0xFF0A0A0B) : const Color(0xFFF9FAFB),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : _qrData == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.info_circle, color: mutedColor, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'No se pudo cargar el código QR',
                          style: GoogleFonts.inter(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadQrCode,
                          icon: const Icon(Iconsax.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Información
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Comparte este código QR',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tus clientes pueden escanear este código para agendar citas directamente',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: mutedColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accentColor.withAlpha(50),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withAlpha(20),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: _qrData!.url,
                          version: QrVersions.auto,
                          size: 280,
                          backgroundColor: Colors.white,
                          foregroundColor: accentColor,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Información del negocio
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.profile.businessName ?? widget.profile.name,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _qrData!.url,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: mutedColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botón de compartir
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _shareQr,
                          icon: const Icon(Iconsax.send_2, size: 18),
                          label: const Text('Compartir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

