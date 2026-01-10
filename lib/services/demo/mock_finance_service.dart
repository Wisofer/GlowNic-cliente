import '../../models/finance.dart';

/// Servicio mock de finanzas para modo demo
class MockFinanceService {
  Future<TransactionsResponse> getIncome({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    final transactions = <TransactionDto>[
      TransactionDto(
        id: 1,
        amount: 150.00,
        description: 'Corte Clásico - Juan Pérez',
        category: 'Servicios',
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: 'Income',
      ),
      TransactionDto(
        id: 2,
        amount: 250.00,
        description: 'Corte + Barba - Carlos Rodríguez',
        category: 'Servicios',
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: 'Income',
      ),
      TransactionDto(
        id: 3,
        amount: 200.00,
        description: 'Afeitado Tradicional - Miguel González',
        category: 'Servicios',
        date: DateTime.now().subtract(const Duration(days: 3)),
        type: 'Income',
      ),
      TransactionDto(
        id: 4,
        amount: 350.00,
        description: 'Corte + Barba + Tratamiento - Luis Martínez',
        category: 'Servicios',
        date: DateTime.now().subtract(const Duration(days: 4)),
        type: 'Income',
      ),
    ];

    return TransactionsResponse(
      total: transactions.fold(0.0, (sum, t) => sum + t.amount),
      items: transactions,
    );
  }

  Future<TransactionDto> createIncome({
    required double amount,
    required String description,
    String? category,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return TransactionDto(
      id: DateTime.now().millisecondsSinceEpoch,
      amount: amount,
      description: description,
      category: category ?? 'Servicios',
      date: date,
      type: 'Income',
    );
  }

  Future<TransactionsResponse> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    final transactions = <TransactionDto>[
      TransactionDto(
        id: 101,
        amount: 50.00,
        description: 'Compra de productos',
        category: 'Suministros',
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: 'Expense',
      ),
      TransactionDto(
        id: 102,
        amount: 30.00,
        description: 'Servicios públicos',
        category: 'Gastos',
        date: DateTime.now().subtract(const Duration(days: 5)),
        type: 'Expense',
      ),
      TransactionDto(
        id: 103,
        amount: 70.00,
        description: 'Mantenimiento de equipos',
        category: 'Mantenimiento',
        date: DateTime.now().subtract(const Duration(days: 10)),
        type: 'Expense',
      ),
    ];

    return TransactionsResponse(
      total: transactions.fold(0.0, (sum, t) => sum + t.amount),
      items: transactions,
    );
  }

  Future<TransactionDto> createExpense({
    required double amount,
    required String description,
    String? category,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return TransactionDto(
      id: DateTime.now().millisecondsSinceEpoch,
      amount: amount,
      description: description,
      category: category ?? 'Gastos',
      date: date,
      type: 'Expense',
    );
  }

  Future<FinanceSummaryDto> getSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final income = await getIncome(startDate: startDate, endDate: endDate);
    final expenses = await getExpenses(startDate: startDate, endDate: endDate);
    
    return FinanceSummaryDto(
      incomeThisMonth: income.total,
      expensesThisMonth: expenses.total,
      profitThisMonth: income.total - expenses.total,
      totalIncome: income.total,
      totalExpenses: expenses.total,
      netProfit: income.total - expenses.total,
    );
  }
}

