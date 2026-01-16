import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para notificar cuando el dashboard necesita refrescarse
class DashboardRefreshNotifier extends StateNotifier<int> {
  DashboardRefreshNotifier() : super(0);

  /// Forzar refresco del dashboard
  void refresh() {
    state = state + 1;
  }
}

final dashboardRefreshProvider =
    StateNotifierProvider<DashboardRefreshNotifier, int>((ref) {
  return DashboardRefreshNotifier();
});
