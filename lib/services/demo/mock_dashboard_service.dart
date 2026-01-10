import '../../models/dashboard_barber.dart';
import 'mock_data.dart';

/// Servicio mock de dashboard para modo demo
class MockDashboardService {
  Future<BarberDashboardDto> getDashboard() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return MockData.mockDashboard;
  }
}

