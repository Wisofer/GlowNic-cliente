import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/finance.dart';
import '../../providers/providers.dart';
import '../../providers/auth_provider.dart';
import '../demo/mock_finance_service.dart';

class FinanceService {
  final Dio _dio;

  FinanceService(this._dio);

  String _formatDateTime(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$year-$month-${day}T$hour:$minute:$second';
  }

  void _addDateFilters(Map<String, dynamic> queryParams, DateTime? startDate, DateTime? endDate) {
    if (startDate != null) {
      final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
      queryParams['startDate'] = _formatDateTime(normalizedStart);
    }
    if (endDate != null) {
      final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      queryParams['endDate'] = _formatDateTime(normalizedEnd);
    }
  }

  Future<TransactionsResponse> getIncome({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };
      _addDateFilters(queryParams, startDate, endDate);

      final response = await _dio.get(
        '/barber/finances/income',
        queryParameters: queryParams,
      );
      return TransactionsResponse.fromJson(response.data);
    } on DioException {
      rethrow;
    }
  }

  Future<TransactionDto> createIncome({
    required double amount,
    required String description,
    String? category,
    required DateTime date,
  }) async {
    try {
      final data = <String, dynamic>{
        'amount': amount,
        'description': description,
        'date': date.toIso8601String().split('T')[0],
      };
      if (category != null && category.isNotEmpty) {
        data['category'] = category;
      }
      final response = await _dio.post(
        '/barber/finances/income',
        data: data,
      );
      return TransactionDto.fromJson(response.data);
    } on DioException {
      rethrow;
    }
  }

  Future<TransactionsResponse> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };
      _addDateFilters(queryParams, startDate, endDate);

      final response = await _dio.get(
        '/barber/finances/expenses',
        queryParameters: queryParams,
      );
      return TransactionsResponse.fromJson(response.data);
    } on DioException {
      rethrow;
    }
  }

  Future<TransactionDto> createExpense({
    required double amount,
    required String description,
    String? category,
    required DateTime date,
  }) async {
    try {
      final data = <String, dynamic>{
        'amount': amount,
        'description': description,
        'date': date.toIso8601String().split('T')[0],
      };
      if (category != null && category.isNotEmpty) {
        data['category'] = category;
      }
      final response = await _dio.post(
        '/barber/finances/expenses',
        data: data,
      );
      return TransactionDto.fromJson(response.data);
    } on DioException {
      rethrow;
    }
  }

  Future<TransactionDto> updateExpense({
    required int id,
    required double amount,
    required String description,
    String? category,
    required DateTime date,
  }) async {
    try {
      final data = <String, dynamic>{
        'amount': amount,
        'description': description,
        'date': date.toIso8601String().split('T')[0],
      };
      if (category != null && category.isNotEmpty) {
        data['category'] = category;
      }
      final response = await _dio.put(
        '/barber/finances/expenses/$id',
        data: data,
      );
      return TransactionDto.fromJson(response.data);
    } on DioException {
      rethrow;
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _dio.delete('/barber/finances/expenses/$id');
    } on DioException {
      rethrow;
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await _dio.get('/barber/finances/categories');
      return (response.data as List).map((e) => e.toString()).toList();
    } on DioException {
      rethrow;
    }
  }
}

final financeServiceProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(authNotifierProvider);
  
  // Si está en modo demo, usar servicio mock
  if (authState.isDemoMode) {
    return MockFinanceService();
  }
  
  final dio = ref.watch(dioProvider);
  return FinanceService(dio);
});
