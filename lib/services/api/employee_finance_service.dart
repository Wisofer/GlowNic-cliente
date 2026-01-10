import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/finance.dart';
import '../../providers/providers.dart';

class EmployeeFinanceService {
  final Dio _dio;

  EmployeeFinanceService(this._dio);

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
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      _addDateFilters(queryParams, startDate, endDate);

      final response = await _dio.get(
        '/employee/finances/income',
        queryParameters: queryParams.isEmpty ? null : queryParams,
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
        '/employee/finances/income',
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
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      _addDateFilters(queryParams, startDate, endDate);

      final response = await _dio.get(
        '/employee/finances/expenses',
        queryParameters: queryParams.isEmpty ? null : queryParams,
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
        '/employee/finances/expenses',
        data: data,
      );
      return TransactionDto.fromJson(response.data);
    } on DioException {
      rethrow;
    }
  }
}

final employeeFinanceServiceProvider = Provider<EmployeeFinanceService>((ref) {
  final dio = ref.watch(dioProvider);
  return EmployeeFinanceService(dio);
});
