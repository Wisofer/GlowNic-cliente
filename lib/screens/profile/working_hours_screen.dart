import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../models/salon.dart';
import '../../services/api/salon_service.dart';

class WorkingHoursScreen extends ConsumerStatefulWidget {
  const WorkingHoursScreen({super.key});

  @override
  ConsumerState<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends ConsumerState<WorkingHoursScreen> {
  Map<int, _DaySchedule> _schedules = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Mapeo de días de la semana
  final Map<int, String> _dayNames = {
    0: 'Domingo',
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
  };

  @override
  void initState() {
    super.initState();
    _loadWorkingHours();
  }

  Future<void> _loadWorkingHours() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(salonServiceProvider);
      final workingHours = await service.getWorkingHours();

      // Inicializar todos los días (0-6)
      final schedules = <int, _DaySchedule>{};
      for (int day = 0; day < 7; day++) {
        final existing = workingHours.firstWhere(
          (wh) => wh.dayOfWeek == day,
          orElse: () => WorkingHoursDto(
            id: 0,
            dayOfWeek: day,
            startTime: '09:00',
            endTime: '18:00',
            isActive: false,
          ),
        );
        schedules[day] = _DaySchedule(
          id: existing.id,
          day: _dayNames[day]!,
          dayOfWeek: day,
          isActive: existing.isActive,
          startTime: existing.startTime,
          endTime: existing.endTime,
        );
      }

      if (mounted) {
        setState(() {
          _schedules = schedules;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String message = 'Error al cargar los horarios';
      
      if (statusCode == 404) {
        // Si no hay horarios, inicializar con valores por defecto
        final schedules = <int, _DaySchedule>{};
        for (int day = 0; day < 7; day++) {
          schedules[day] = _DaySchedule(
            id: 0,
            day: _dayNames[day]!,
            dayOfWeek: day,
            isActive: day != 0 && day != 6, // Lunes a Viernes activos por defecto
            startTime: '09:00',
            endTime: '18:00',
          );
        }
        if (mounted) {
          setState(() {
            _schedules = schedules;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Error $statusCode: ${e.response?.data?['message'] ?? message}';
          });
        }
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

  Future<void> _saveWorkingHours() async {
    setState(() => _isSaving = true);

    try {
      final service = ref.read(salonServiceProvider);
      
      // Preparar datos para enviar
      // IMPORTANTE según documentación del backend:
      // - dayOfWeek: NÚMERO 0-6 (0=Domingo, 1=Lunes, ..., 6=Sábado)
      // - startTime/endTime: Formato "HH:mm" (NO "HH:mm:ss")
      // - isActive: Boolean (true/false)
      final workingHours = _schedules.values.map((schedule) {
        // Asegurar formato HH:mm (sin segundos)
        final startTime = schedule.startTime.length == 8 
            ? schedule.startTime.substring(0, 5)  // Quitar :00 si tiene segundos
            : schedule.startTime;
        final endTime = schedule.endTime.length == 8 
            ? schedule.endTime.substring(0, 5)  // Quitar :00 si tiene segundos
            : schedule.endTime;
        
        return {
          'dayOfWeek': schedule.dayOfWeek, // Backend espera 0-6 (0=Domingo, 1=Lunes, etc.)
          'startTime': startTime,           // Formato "HH:mm"
          'endTime': endTime,               // Formato "HH:mm"
          'isActive': schedule.isActive,    // Boolean
        };
      }).toList().cast<Map<String, dynamic>>();

      await service.updateWorkingHours(workingHours);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horarios guardados correctamente'),
            backgroundColor: Color(0xFFEC4899),
          ),
        );
        Navigator.pop(context);
      }
    } on DioException catch (e) {
      String message = 'Error al guardar los horarios';
      final statusCode = e.response?.statusCode;
      
      if (e.response?.data != null) {
        if (e.response!.data is Map<String, dynamic>) {
          final errorData = e.response!.data as Map<String, dynamic>;
          message = errorData['message'] ?? message;
          
          if (errorData.containsKey('errors')) {
            final errors = errorData['errors'];
            message = 'Errores de validación: $errors';
          }
        } else if (e.response!.data is String) {
          message = e.response!.data as String;
        }
      }
      
      if (statusCode == 404) {
        message = 'Endpoint no encontrado. Verifica la configuración del servidor.';
      } else if (statusCode == 400) {
        message = 'Datos inválidos. Verifica los horarios ingresados.';
      } else if (statusCode == 401) {
        message = 'Sesión expirada. Por favor, inicia sesión nuevamente.';
      }
      
      
      if (mounted) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Horarios de Trabajo',
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
        body: const Center(child: CircularProgressIndicator(color: accentColor)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Horarios de Trabajo',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveWorkingHours,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  )
                : Text(
                    'Guardar',
                    style: GoogleFonts.inter(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      backgroundColor: isDark ? const Color(0xFF0A0A0B) : const Color(0xFFF9FAFB),
      body: _errorMessage != null && _schedules.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.info_circle, color: mutedColor, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar horarios',
                      style: GoogleFonts.inter(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(
                        color: mutedColor,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadWorkingHours,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configura los días y horarios en los que estás disponible',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Ordenar días: Lunes (1) a Domingo (0)
                  ...([1, 2, 3, 4, 5, 6, 0].map((day) {
                    final schedule = _schedules[day];
                    if (schedule == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DayScheduleCard(
                        schedule: schedule,
                        onToggle: (value) {
                          setState(() {
                            _schedules[day] = schedule.copyWith(isActive: value);
                          });
                        },
                        onStartTimeChanged: (time) {
                          setState(() {
                            _schedules[day] = schedule.copyWith(startTime: time);
                          });
                        },
                        onEndTimeChanged: (time) {
                          setState(() {
                            _schedules[day] = schedule.copyWith(endTime: time);
                          });
                        },
                        textColor: textColor,
                        mutedColor: mutedColor,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        accentColor: accentColor,
                      ),
                    );
                  })),
                ],
              ),
            ),
    );
  }
}

class _DaySchedule {
  final int id;
  final String day;
  final int dayOfWeek;
  final bool isActive;
  final String startTime;
  final String endTime;

  _DaySchedule({
    required this.id,
    required this.day,
    required this.dayOfWeek,
    required this.isActive,
    required this.startTime,
    required this.endTime,
  });

  _DaySchedule copyWith({
    int? id,
    String? day,
    int? dayOfWeek,
    bool? isActive,
    String? startTime,
    String? endTime,
  }) {
    return _DaySchedule(
      id: id ?? this.id,
      day: day ?? this.day,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isActive: isActive ?? this.isActive,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

class _DayScheduleCard extends StatelessWidget {
  final _DaySchedule schedule;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onStartTimeChanged;
  final ValueChanged<String> onEndTimeChanged;
  final Color textColor;
  final Color mutedColor;
  final Color cardColor;
  final Color borderColor;
  final Color accentColor;

  const _DayScheduleCard({
    required this.schedule,
    required this.onToggle,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    required this.textColor,
    required this.mutedColor,
    required this.cardColor,
    required this.borderColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  schedule.day,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              Switch(
                value: schedule.isActive,
                onChanged: onToggle,
                activeColor: accentColor,
              ),
            ],
          ),
          if (schedule.isActive) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: 'Inicio',
                    time: schedule.startTime,
                    onTimeChanged: onStartTimeChanged,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    accentColor: accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePicker(
                    label: 'Fin',
                    time: schedule.endTime,
                    onTimeChanged: onEndTimeChanged,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    accentColor: accentColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final String time;
  final ValueChanged<String> onTimeChanged;
  final Color textColor;
  final Color mutedColor;
  final Color accentColor;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.onTimeChanged,
    required this.textColor,
    required this.mutedColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(time.split(':')[0]),
            minute: int.parse(time.split(':')[1]),
          ),
        );
        if (picked != null) {
          final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onTimeChanged(formatted);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accentColor.withAlpha(10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentColor.withAlpha(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: mutedColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
