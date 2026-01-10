import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../models/service.dart';
import '../../services/api/appointment_service.dart';
import '../../services/api/employee_appointment_service.dart';
import '../../services/api/service_service.dart';
import '../../services/api/employee_service_service.dart';
import '../../utils/role_helper.dart';
import '../../utils/audio_helper.dart';
import '../../providers/pending_appointments_provider.dart';

class CreateAppointmentScreen extends ConsumerStatefulWidget {
  const CreateAppointmentScreen({super.key});

  @override
  ConsumerState<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends ConsumerState<CreateAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  
  List<int> _selectedServiceIds = []; // Cambiado a lista para múltiples servicios
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<ServiceDto> _services = [];
  bool _isLoading = false;
  bool _isLoadingServices = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      List<ServiceDto> services;
      
      // Los empleados usan el endpoint /employee/services (solo lectura)
      // Los barberos usan el endpoint /barber/services (con permisos completos)
      if (RoleHelper.isEmployee(ref)) {
        final employeeServiceService = ref.read(employeeServiceServiceProvider);
        services = await employeeServiceService.getServices();
      } else {
        final service = ref.read(serviceServiceProvider);
        services = await service.getServices();
      }
      
      if (mounted) {
        setState(() {
          _services = services.where((s) => s.isActive).toList();
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingServices = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar servicios: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFEC4899),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    // Usar modo input para permitir cualquier minuto (00-59)
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input, // Permite entrada manual de cualquier minuto
      helpText: 'Selecciona la hora (permite cualquier minuto)',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFEC4899),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _createAppointment() async {
    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validar fecha (obligatorio)
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha es obligatoria. Por favor selecciona una fecha.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    
    // Validar hora (obligatorio)
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora es obligatoria. Por favor selecciona una hora.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Usar el servicio correcto según el rol
      if (RoleHelper.isEmployee(ref)) {
        final service = ref.read(employeeAppointmentServiceProvider);
        await service.createAppointment(
          serviceIds: _selectedServiceIds.isEmpty ? null : _selectedServiceIds,
          clientName: _clientNameController.text.trim(),
          clientPhone: _clientPhoneController.text.trim(),
          date: '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
          time: '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        );
      } else {
        final service = ref.read(appointmentServiceProvider);
        await service.createAppointment(
          serviceIds: _selectedServiceIds.isEmpty ? null : _selectedServiceIds,
          clientName: _clientNameController.text.trim(),
          clientPhone: _clientPhoneController.text.trim(),
          date: '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
          time: '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        );
      }

      if (mounted) {
        // Reproducir audio de éxito
        AudioHelper.playSuccess();
        
        // Actualizar contador de pendientes (por si la cita se creó como pendiente)
        ref.read(pendingAppointmentsProvider.notifier).refresh();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita creada exitosamente'),
            backgroundColor: Color(0xFFEC4899),
          ),
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Error al crear la cita';
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
    final bgColor = isDark ? const Color(0xFF0A0A0B) : const Color(0xFFFFF1F5);
    const accentColor = Color(0xFFEC4899);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Nueva Cita',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),
      body: _isLoadingServices
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completa los datos para crear una nueva cita',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _clientNameController,
                      label: 'Nombre del Cliente',
                      hint: 'Ej. Juan Pérez',
                      icon: Iconsax.user,
                      textColor: textColor,
                      mutedColor: mutedColor,
                      borderColor: borderColor,
                      cardColor: cardColor,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _clientPhoneController,
                      label: 'Teléfono del Cliente',
                      hint: 'Ej. 1234567890',
                      icon: Iconsax.call,
                      keyboardType: TextInputType.phone,
                      textColor: textColor,
                      mutedColor: mutedColor,
                      borderColor: borderColor,
                      cardColor: cardColor,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El teléfono es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildServiceSelector(
                      services: _services,
                      selectedServiceIds: _selectedServiceIds,
                      onServiceToggled: (serviceId) {
                        setState(() {
                          if (_selectedServiceIds.contains(serviceId)) {
                            _selectedServiceIds.remove(serviceId);
                          } else {
                            _selectedServiceIds.add(serviceId);
                          }
                        });
                      },
                      textColor: textColor,
                      mutedColor: mutedColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                    ),
                    // Mostrar resumen si hay servicios seleccionados
                    if (_selectedServiceIds.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildServiceSummary(
                        selectedServiceIds: _selectedServiceIds,
                        services: _services,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        accentColor: accentColor,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildDateSelector(
                      label: 'Fecha',
                      date: _selectedDate,
                      onTap: _selectDate,
                      textColor: textColor,
                      mutedColor: mutedColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: 16),
                    _buildTimeSelector(
                      label: 'Hora',
                      time: _selectedTime,
                      onTap: _selectTime,
                      textColor: textColor,
                      mutedColor: mutedColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      accentColor: accentColor,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isLoading || _selectedDate == null || _selectedTime == null) 
                            ? null 
                            : _createAppointment,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Iconsax.add),
                        label: Text(_isLoading ? 'Creando...' : 'Crear Cita'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
    required Color cardColor,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
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
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(color: textColor),
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: mutedColor),
              prefixIcon: Icon(icon, color: mutedColor, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceSelector({
    required List<ServiceDto> services,
    required List<int> selectedServiceIds,
    required Function(int) onServiceToggled,
    required Color textColor,
    required Color mutedColor,
    required Color cardColor,
    required Color borderColor,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Servicios (Opcional)',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        if (services.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              'No hay servicios disponibles',
              style: GoogleFonts.inter(color: mutedColor),
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                final isSelected = selectedServiceIds.contains(service.id);
                return InkWell(
                  onTap: () => onServiceToggled(service.id),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor.withAlpha(20) : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: borderColor,
                          width: index < services.length - 1 ? 1 : 0,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Checkbox
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? accentColor : borderColor,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor.withAlpha(30) : accentColor.withAlpha(10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Iconsax.star1,
                            color: isSelected ? accentColor : mutedColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${service.formattedPrice} • ${service.formattedDuration}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildServiceSummary({
    required List<int> selectedServiceIds,
    required List<ServiceDto> services,
    required Color textColor,
    required Color mutedColor,
    required Color cardColor,
    required Color borderColor,
    required Color accentColor,
  }) {
    final selectedServices = services.where((s) => selectedServiceIds.contains(s.id)).toList();
    final totalPrice = selectedServices.fold<double>(0.0, (sum, s) => sum + s.price);
    final totalDuration = selectedServices.fold<int>(0, (sum, s) => sum + s.durationMinutes);

    String formatDuration(int minutes) {
      if (minutes < 60) {
        return '$minutes min';
      }
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours h';
      }
      return '$hours h $mins min';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: mutedColor,
                ),
              ),
              Text(
                'C\$${totalPrice.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Duración:',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: mutedColor,
                ),
              ),
              Text(
                formatDuration(totalDuration),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required Color textColor,
    required Color mutedColor,
    required Color cardColor,
    required Color borderColor,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(Iconsax.calendar, color: mutedColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Seleccionar fecha',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: date != null ? textColor : mutedColor,
                    ),
                  ),
                ),
                Icon(Iconsax.arrow_right_3, color: mutedColor, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
    required Color textColor,
    required Color mutedColor,
    required Color cardColor,
    required Color borderColor,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(Iconsax.clock, color: mutedColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    time != null
                        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                        : 'Seleccionar hora',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: time != null ? textColor : mutedColor,
                    ),
                  ),
                ),
                Icon(Iconsax.arrow_right_3, color: mutedColor, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

