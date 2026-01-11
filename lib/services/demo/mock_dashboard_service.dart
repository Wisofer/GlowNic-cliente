import '../../models/dashboard_salon.dart';
import 'mock_data.dart';

/// Servicio mock de dashboard para modo demo
class MockDashboardService {
  Future<SalonDashboardDto> getDashboard() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return MockData.mockDashboard;
  }
}

