import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import '../../models/help_support.dart';
import '../../services/api/help_support_service.dart';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  HelpSupportDto? _helpSupport;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHelpSupport();
  }

  Future<void> _loadHelpSupport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(helpSupportServiceProvider);
      final helpSupport = await service.getHelpSupport();
      
      if (mounted) {
        setState(() {
          _helpSupport = helpSupport;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Error al cargar la ayuda';
      
      if (statusCode == 404) {
        message = 'Endpoint no encontrado. Verifica la configuración del servidor.';
      } else if (e.response?.data is Map) {
        message = e.response?.data['message'] ?? message;
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
          'Ayuda y Soporte',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : _helpSupport == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.info_circle, color: mutedColor, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'No se pudo cargar la ayuda',
                          style: GoogleFonts.inter(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                              color: mutedColor,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadHelpSupport,
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
              : RefreshIndicator(
                  onRefresh: _loadHelpSupport,
                  color: accentColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Contactar soporte
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accentColor.withAlpha(20),
                                accentColor.withAlpha(10),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: accentColor.withAlpha(30)),
                          ),
                          child: Column(
                            children: [
                              Icon(Iconsax.headphone, color: accentColor, size: 40),
                              const SizedBox(height: 12),
                              Text(
                                '¿Necesitas ayuda?',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Contáctanos y te responderemos lo antes posible',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: mutedColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _launchUrl('mailto:${_helpSupport!.contact.email}?subject=Soporte GlowNic'),
                                      icon: const Icon(Iconsax.sms, size: 18),
                                      label: const Text('Email'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        side: BorderSide(color: accentColor),
                                        foregroundColor: accentColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _launchUrl(_helpSupport!.contact.website),
                                      icon: const Icon(Iconsax.global, size: 18),
                                      label: const Text('Sitio Web'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: accentColor,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_helpSupport!.contact.phones.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                ..._helpSupport!.contact.phones.map((phone) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: InkWell(
                                        onTap: () => _launchUrl('tel:$phone'),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Iconsax.call, size: 16, color: accentColor),
                                            const SizedBox(width: 8),
                                            Text(
                                              phone,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: accentColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Preguntas frecuentes
                        Text(
                          'Preguntas Frecuentes',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._helpSupport!.faqs.map((faq) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _FaqCard(
                                faq: faq,
                                textColor: textColor,
                                mutedColor: mutedColor,
                                cardColor: cardColor,
                                borderColor: borderColor,
                                accentColor: accentColor,
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _FaqCard extends StatefulWidget {
  final FaqDto faq;
  final Color textColor;
  final Color mutedColor;
  final Color cardColor;
  final Color borderColor;
  final Color accentColor;

  const _FaqCard({
    required this.faq,
    required this.textColor,
    required this.mutedColor,
    required this.cardColor,
    required this.borderColor,
    required this.accentColor,
  });

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.borderColor),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.faq.question,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: widget.textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    _isExpanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                    color: widget.mutedColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.faq.answer,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: widget.mutedColor,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

