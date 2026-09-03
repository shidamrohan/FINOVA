import 'dart:convert';

// ==================== MONTHLY BUDGET ====================

class MonthlyBudget {
  final String id;
  final int month;
  final int year;
  final double baseAmount;
  final List<BudgetAdjustment> adjustments;

  MonthlyBudget({
    required this.id,
    required this.month,
    required this.year,
    required this.baseAmount,
    List<BudgetAdjustment>? adjustments,
  }) : adjustments = adjustments ?? [];

  double get totalIncome {
    return adjustments
        .where((a) => a.type == BudgetAdjustmentType.income)
        .fold(0.0, (sum, a) => sum + a.amount);
  }

  double get totalExpenseAdjustments {
    return adjustments
        .where((a) => a.type == BudgetAdjustmentType.expense)
        .fold(0.0, (sum, a) => sum + a.amount);
  }

  double get totalAmount {
    return baseAmount + totalIncome - totalExpenseAdjustments;
  }

  // ✅ UPDATED: Convert to Map for Supabase (snake_case fields)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'month': month,
      'year': year,
      'base_amount': baseAmount, // ✅ Changed to snake_case
      'adjustments':
          adjustments.map((a) => a.toJson()).toList(), // ✅ JSONB array
    };
  }

  // ✅ UPDATED: Create from Map (Supabase uses snake_case)
  factory MonthlyBudget.fromJson(Map<String, dynamic> json) {
    return MonthlyBudget(
      id: json['id'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      baseAmount:
          _parseAmount(json['base_amount']), // ✅ Changed from baseAmount
      adjustments:
          _parseAdjustments(json['adjustments']), // ✅ Safe JSONB parsing
    );
  }

  // ✅ ADDED: Helper method to safely parse amount
  static double _parseAmount(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0.0;
  }

  // ✅ ADDED: Helper method to safely parse adjustments from JSONB
  static List<BudgetAdjustment> _parseAdjustments(dynamic value) {
    if (value == null) return [];

    try {
      if (value is String) {
        // If it comes as JSON string
        final decoded = jsonDecode(value) as List;
        return decoded.map((a) => BudgetAdjustment.fromJson(a)).toList();
      } else if (value is List) {
        // If it comes as List directly (JSONB)
        return value
            .map((a) => BudgetAdjustment.fromJson(a as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('❌ Error parsing adjustments: $e');
    }

    return [];
  }

  // ✅ KEPT: Backward compatibility with old local storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month': month,
      'year': year,
      'base_amount': baseAmount,
      'adjustments': jsonEncode(adjustments.map((a) => a.toJson()).toList()),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory MonthlyBudget.fromMap(Map<String, dynamic> map) {
    // Try new format first
    if (map.containsKey('base_amount')) {
      return MonthlyBudget.fromJson(map);
    }

    // Old format (camelCase)
    return MonthlyBudget(
      id: map['id'],
      month: map['month'],
      year: map['year'],
      baseAmount: _parseAmount(map['baseAmount']),
      adjustments: map['adjustments'] != null
          ? (jsonDecode(map['adjustments']) as List)
              .map((a) => BudgetAdjustment.fromJson(a))
              .toList()
          : [],
    );
  }

  MonthlyBudget copyWith({
    String? id,
    int? month,
    int? year,
    double? baseAmount,
    List<BudgetAdjustment>? adjustments,
  }) {
    return MonthlyBudget(
      id: id ?? this.id,
      month: month ?? this.month,
      year: year ?? this.year,
      baseAmount: baseAmount ?? this.baseAmount,
      adjustments: adjustments ?? this.adjustments,
    );
  }
}

// ==================== BUDGET ADJUSTMENT ====================

class BudgetAdjustment {
  final String id;
  final BudgetAdjustmentType type;
  final double amount;
  final String note;
  final DateTime date;

  BudgetAdjustment({
    required this.id,
    required this.type,
    required this.amount,
    required this.note,
    required this.date,
  });

  // ✅ This stays the same - stored as JSONB, no snake_case needed for nested data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
    };
  }

  factory BudgetAdjustment.fromJson(Map<String, dynamic> json) {
    return BudgetAdjustment(
      id: json['id'] as String,
      type: BudgetAdjustmentType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => BudgetAdjustmentType.expense,
      ),
      amount: _parseAmount(json['amount']),
      note: json['note'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  // ✅ ADDED: Safe amount parsing
  static double _parseAmount(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0.0;
  }
}

enum BudgetAdjustmentType {
  income,
  expense,
}

// ==================== MULTI BUDGET ====================

class MultiBudget {
  final String id;
  final String name;
  final double monthlyAmount;
  final DateTime startDate;
  final int durationMonths;
  final String categoryId;
  final bool isActive;

  MultiBudget({
    required this.id,
    required this.name,
    required this.monthlyAmount,
    required this.startDate,
    required this.durationMonths,
    this.categoryId = 'all',
    this.isActive = true,
  });

  DateTime get endDate {
    return DateTime(
      startDate.year,
      startDate.month + durationMonths,
      0,
      23,
      59,
      59,
    );
  }

  double get totalAmount => monthlyAmount * durationMonths;

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return now.isAfter(startDate.subtract(const Duration(days: 1))) &&
        now.isBefore(endDate.add(const Duration(days: 1))) &&
        isActive;
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return startDate.isAfter(now) && isActive;
  }

  bool get isExpired {
    final now = DateTime.now();
    return endDate.isBefore(now);
  }

  int get daysUntilStart {
    final now = DateTime.now();
    if (startDate.isAfter(now)) {
      return startDate.difference(now).inDays;
    }
    return 0;
  }

  int get daysRemaining {
    final now = DateTime.now();
    if (endDate.isAfter(now) && startDate.isBefore(now)) {
      return endDate.difference(now).inDays;
    }
    return 0;
  }

  int get currentMonthIndex {
    final now = DateTime.now();
    if (!isCurrentlyActive) return 0;

    final monthsDiff =
        (now.year - startDate.year) * 12 + (now.month - startDate.month);
    return monthsDiff.clamp(0, durationMonths - 1);
  }
  // ==================== EXPENSE TRACKING METHODS ====================

  /// Calculate total spent from a list of expenses
  double calculateTotalSpent(List<dynamic> expenses) {
    if (categoryId == 'all') {
      // Track all expenses
      return expenses
          .where((expense) => _isExpenseInDateRange(expense))
          .fold(0.0, (sum, expense) => sum + _getExpenseAmount(expense));
    } else {
      // Track only expenses in this category
      return expenses
          .where((expense) =>
              _getExpenseCategoryId(expense) == categoryId &&
              _isExpenseInDateRange(expense))
          .fold(0.0, (sum, expense) => sum + _getExpenseAmount(expense));
    }
  }

  /// Calculate spent for a specific month index (0-based)
  double calculateMonthSpent(List<dynamic> expenses, int monthIndex) {
    final monthDate = DateTime(
      startDate.year,
      startDate.month + monthIndex,
      1,
    );
    final monthStart = DateTime(monthDate.year, monthDate.month, 1);
    final monthEnd =
        DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);

    if (categoryId == 'all') {
      return expenses.where((expense) {
        final expenseDate = _getExpenseDate(expense);
        return expenseDate
                .isAfter(monthStart.subtract(const Duration(days: 1))) &&
            expenseDate.isBefore(monthEnd.add(const Duration(days: 1)));
      }).fold(0.0, (sum, expense) => sum + _getExpenseAmount(expense));
    } else {
      return expenses.where((expense) {
        final expenseDate = _getExpenseDate(expense);
        return _getExpenseCategoryId(expense) == categoryId &&
            expenseDate.isAfter(monthStart.subtract(const Duration(days: 1))) &&
            expenseDate.isBefore(monthEnd.add(const Duration(days: 1)));
      }).fold(0.0, (sum, expense) => sum + _getExpenseAmount(expense));
    }
  }

  /// Get remaining budget amount
  double getRemainingBudget(List<dynamic> expenses) {
    return totalAmount - calculateTotalSpent(expenses);
  }

  /// Get spending progress (0.0 to 1.0)
  double getSpendingProgress(List<dynamic> expenses) {
    if (totalAmount == 0) return 0.0;
    final spent = calculateTotalSpent(expenses);
    return (spent / totalAmount).clamp(0.0, 1.0);
  }

  /// Check if over budget
  bool isOverBudget(List<dynamic> expenses) {
    return calculateTotalSpent(expenses) > totalAmount;
  }

// ==================== PRIVATE HELPER METHODS ====================

  bool _isExpenseInDateRange(dynamic expense) {
    try {
      final expenseDate = _getExpenseDate(expense);
      return expenseDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          expenseDate.isBefore(endDate.add(const Duration(days: 1)));
    } catch (e) {
      return false;
    }
  }

  DateTime _getExpenseDate(dynamic expense) {
    if (expense is Map<String, dynamic>) {
      return DateTime.parse(expense['date'] as String);
    }
    // If it's an Expense object with date property
    return (expense as dynamic).date as DateTime;
  }

  double _getExpenseAmount(dynamic expense) {
    if (expense is Map<String, dynamic>) {
      final amount = expense['amount'];
      if (amount is double) return amount;
      if (amount is int) return amount.toDouble();
      if (amount is num) return amount.toDouble();
      if (amount is String) return double.parse(amount);
      return 0.0;
    }
    // If it's an Expense object with amount property
    final amount = (expense as dynamic).amount;
    if (amount is double) return amount;
    if (amount is int) return amount.toDouble();
    return 0.0;
  }

  String _getExpenseCategoryId(dynamic expense) {
    if (expense is Map<String, dynamic>) {
      return expense['category_id'] as String? ??
          expense['categoryId'] as String? ??
          '';
    }
    // If it's an Expense object with categoryId property
    return (expense as dynamic).categoryId as String? ?? '';
  }

  // ✅ UPDATED: Convert to Map for Supabase (snake_case fields)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'monthly_amount': monthlyAmount, // ✅ Changed to snake_case
      'start_date': startDate.toIso8601String(), // ✅ Changed to snake_case
      'duration_months': durationMonths, // ✅ Changed to snake_case
      'category_id': categoryId, // ✅ Changed to snake_case
      'is_active': isActive, // ✅ Changed to snake_case
    };
  }

  // ✅ UPDATED: Create from Map (Supabase uses snake_case)
  factory MultiBudget.fromJson(Map<String, dynamic> json) {
    return MultiBudget(
      id: json['id'] as String,
      name: json['name'] as String,
      monthlyAmount:
          _parseAmount(json['monthly_amount']), // ✅ Changed from monthlyAmount
      startDate: DateTime.parse(
          json['start_date'] as String), // ✅ Changed from startDate
      durationMonths:
          json['duration_months'] as int, // ✅ Changed from durationMonths
      categoryId:
          json['category_id'] as String? ?? 'all', // ✅ Changed from categoryId
      isActive: json['is_active'] as bool? ?? true, // ✅ Changed from isActive
    );
  }

  // ✅ ADDED: Safe amount parsing
  static double _parseAmount(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0.0;
  }

  MultiBudget copyWith({
    String? id,
    String? name,
    double? monthlyAmount,
    DateTime? startDate,
    int? durationMonths,
    String? categoryId,
    bool? isActive,
  }) {
    return MultiBudget(
      id: id ?? this.id,
      name: name ?? this.name,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      startDate: startDate ?? this.startDate,
      durationMonths: durationMonths ?? this.durationMonths,
      categoryId: categoryId ?? this.categoryId,
      isActive: isActive ?? this.isActive,
    );
  }
}

// ==================== TYPE ALIAS ====================

// Type alias for backward compatibility
typedef Budget = MonthlyBudget;
