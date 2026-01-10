import '../../models/barber.dart';
import '../../models/dashboard_barber.dart';
import '../../models/finance.dart';
import 'mock_data.dart';

/// Servicio mock de barbero para modo demo
class MockBarberService {
  Future<BarberDashboardDto> getDashboard() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return MockData.mockDashboard;
  }

  Future<BarberDto> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockData.mockBarberProfile;
  }

  Future<FinanceSummaryDto> getFinanceSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Datos mock de finanzas
    return FinanceSummaryDto(
      incomeThisMonth: 25500.00,
      expensesThisMonth: 4500.00,
      profitThisMonth: 21000.00,
      totalIncome: 25500.00,
      totalExpenses: 4500.00,
      netProfit: 21000.00,
    );
  }

  Future<BarberDto> updateProfile({
    String? name,
    String? businessName,
    String? phone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    final existing = MockData.mockBarberProfile;
    return BarberDto(
      id: existing.id,
      name: name ?? existing.name,
      businessName: businessName ?? existing.businessName,
      phone: phone ?? existing.phone,
      slug: existing.slug,
      isActive: existing.isActive,
      qrUrl: existing.qrUrl,
      createdAt: existing.createdAt,
      email: existing.email,
    );
  }

  Future<Map<String, dynamic>> getQrCode() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      'url': 'https://glownic.encuentrame.org/b/salon-glownic',
      'qrCode': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    };
  }
}

