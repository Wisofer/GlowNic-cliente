import '../../models/service.dart';
import 'mock_data.dart';

/// Servicio mock de servicios para modo demo
class MockServiceService {
  Future<List<ServiceDto>> getServices() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockData.mockServices;
  }

  Future<ServiceDto> createService({
    required String name,
    required double price,
    required int durationMinutes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    return ServiceDto(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      price: price,
      durationMinutes: durationMinutes,
      isActive: true,
    );
  }

  Future<ServiceDto> updateService({
    required int id,
    String? name,
    double? price,
    int? durationMinutes,
    bool? isActive,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final existing = MockData.mockServices.firstWhere(
      (s) => s.id == id,
      orElse: () => MockData.mockServices.first,
    );
    
    return ServiceDto(
      id: existing.id,
      name: name ?? existing.name,
      price: price ?? existing.price,
      durationMinutes: durationMinutes ?? existing.durationMinutes,
      isActive: isActive ?? existing.isActive,
    );
  }

  Future<void> deleteService(int id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Simular eliminación
  }
}

