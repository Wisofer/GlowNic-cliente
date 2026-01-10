class FinanceSummaryDto {
  final double incomeThisMonth;
  final double expensesThisMonth;
  final double profitThisMonth;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;

  FinanceSummaryDto({
    required this.incomeThisMonth,
    required this.expensesThisMonth,
    required this.profitThisMonth,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
  });

  factory FinanceSummaryDto.fromJson(Map<String, dynamic> json) => FinanceSummaryDto(
        incomeThisMonth: (json['incomeThisMonth'] ?? 0).toDouble(),
        expensesThisMonth: (json['expensesThisMonth'] ?? 0).toDouble(),
        profitThisMonth: (json['profitThisMonth'] ?? 0).toDouble(),
        totalIncome: (json['totalIncome'] ?? 0).toDouble(),
        totalExpenses: (json['totalExpenses'] ?? 0).toDouble(),
        netProfit: (json['netProfit'] ?? 0).toDouble(),
      );
}

class TransactionDto {
  final int id;
  final String type; // "Income" or "Expense"
  final double amount;
  final String description;
  final String? category;
  final DateTime date;
  final int? appointmentId;

  TransactionDto({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    this.category,
    required this.date,
    this.appointmentId,
  });

  factory TransactionDto.fromJson(Map<String, dynamic> json) => TransactionDto(
        id: json['id'],
        type: json['type'],
        amount: (json['amount'] as num).toDouble(),
        description: json['description'],
        category: json['category'],
        date: DateTime.parse(json['date']),
        appointmentId: json['appointmentId'],
      );

  bool get isIncome => type == 'Income';
  bool get isExpense => type == 'Expense';
}

class TransactionsResponse {
  final double total;
  final List<TransactionDto> items;

  TransactionsResponse({
    required this.total,
    required this.items,
  });

  factory TransactionsResponse.fromJson(Map<String, dynamic> json) => TransactionsResponse(
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        items: (json['items'] as List?)
                ?.map((e) => TransactionDto.fromJson(e))
                .toList() ??
            [],
      );
}

// Alias para compatibilidad
typedef FinanceTransactionDto = TransactionDto;
typedef FinanceTransactionsResponse = TransactionsResponse;

class AvailabilityResponse {
  final String date;
  final List<String> availableSlots;
  final List<String> blockedSlots;

  AvailabilityResponse({
    required this.date,
    required this.availableSlots,
    required this.blockedSlots,
  });

  factory AvailabilityResponse.fromJson(Map<String, dynamic> json) => AvailabilityResponse(
        date: json['date'],
        availableSlots: (json['availableSlots'] as List?)?.map((e) => e.toString()).toList() ?? [],
        blockedSlots: (json['blockedSlots'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
}

