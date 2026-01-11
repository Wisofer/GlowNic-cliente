import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/finance.dart';
import '../../providers/providers.dart';
import '../../providers/auth_provider.dart';
import '../demo/mock_finance_service.dart';

class FinanceService {
  final Dio _dio;

  FinanceService(this._dio);

  void _addDateFilters(Map<String, dynamic> queryParams, DateTime? startDate, DateTime? endDate) {
    if (startDate != null) {
      // Formato DateOnly: YYYY-MM-DD
      final year = startDate.year.toString();
      final month = startDate.month.toString().padLeft(2, '0');
      final day = startDate.day.toString().padLeft(2, '0');
      queryParams['startDate'] = '$year-$month-$day';
    }
    if (endDate != null) {
      // Formato DateOnly: YYYY-MM-DD
      final year = endDate.year.toString();
      final month = endDate.month.toString().padLeft(2, '0');
      final day = endDate.day.toString().padLeft(2, '0');
      queryParams['endDate'] = '$year-$month-$day';
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
        '/salon/finances/income',
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
        'date': date.toIso8601String(), // DateTime ISO 8601 completo
      };
      if (category != null && category.isNotEmpty) {
        data['category'] = category;
      }
      final response = await _dio.post(
        '/salon/finances/income',
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
        '/salon/finances/expenses',
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
        'date': date.toIso8601String(), // DateTime ISO 8601 completo
      };
      if (category != null && category.isNotEmpty) {
        data['category'] = category;
      }
      final response = await _dio.post(
        '/salon/finances/expenses',
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
        'date': date.toIso8601String(), // DateTime ISO 8601 completo
      };
      if (category != null && category.isNotEmpty) {
        data['category'] = category;
      }
      final response = await _dio.put(
        '/salon/finances/expenses/$id',
        data: data,
      );
      return TransactionDto.fromJson(response.data);
    } on DioException {
      rethrow;
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _dio.delete('/salon/finances/expenses/$id');
    } on DioException {
      rethrow;
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await _dio.get('/salon/finances/categories');
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
