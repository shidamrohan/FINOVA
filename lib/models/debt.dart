class Debt {
  final String id;
  final String userId;
  final String name;
  final DebtType type;
  final double totalAmount;
  final double paidAmount;
  final double interestRate; // Annual percentage
  final DateTime startDate;
  final DateTime? dueDate;
  final String? lenderName; // Bank/Person name
  final String note;
  final DebtStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Debt({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.interestRate = 0.0,
    required this.startDate,
    this.dueDate,
    this.lenderName,
    this.note = '',
    this.status = DebtStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get remaining amount
  double get remainingAmount {
    final remaining = totalAmount - paidAmount;
    return remaining > 0 ? remaining : 0;
  }

  // Get payment progress percentage
  double get progressPercentage {
    if (totalAmount <= 0) return 0;
    final percentage = (paidAmount / totalAmount) * 100;
    return percentage > 100 ? 100 : percentage;
  }

  // Check if debt is fully paid
  bool get isPaidOff => paidAmount >= totalAmount;

  // Calculate total interest (simple calculation)
  double get totalInterest {
    if (interestRate <= 0 || dueDate == null) return 0;

    final months = dueDate!.difference(startDate).inDays / 30;
    final monthlyRate = interestRate / 12 / 100;
    final interest = totalAmount * monthlyRate * months;

    return interest;
  }

  // Total amount with interest
  double get totalWithInterest => totalAmount + totalInterest;

  // Days remaining until due date
  int? get daysRemaining {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final difference = dueDate!.difference(now).inDays;
    return difference;
  }

  // Is overdue?
  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && !isPaidOff;
  }

  // Estimated payoff date (if making regular payments)
  DateTime? getEstimatedPayoffDate(double monthlyPayment) {
    if (monthlyPayment <= 0 || remainingAmount <= 0) return null;

    final monthsToPayoff = (remainingAmount / monthlyPayment).ceil();
    return DateTime.now().add(Duration(days: monthsToPayoff * 30));
  }

  // Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type.name,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'interest_rate': interestRate,
      'start_date': startDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'lender_name': lenderName,
      'note': note,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON (Supabase)
  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: DebtType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DebtType.other,
      ),
      totalAmount: _parseAmount(json['total_amount']),
      paidAmount: _parseAmount(json['paid_amount'] ?? 0),
      interestRate: _parseAmount(json['interest_rate'] ?? 0),
      startDate: DateTime.parse(json['start_date'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      lenderName: json['lender_name'] as String?,
      note: json['note'] as String? ?? '',
      status: DebtStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DebtStatus.active,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static double _parseAmount(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0.0;
  }

  Debt copyWith({
    String? id,
    String? userId,
    String? name,
    DebtType? type,
    double? totalAmount,
    double? paidAmount,
    double? interestRate,
    DateTime? startDate,
    DateTime? dueDate,
    String? lenderName,
    String? note,
    DebtStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Debt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      interestRate: interestRate ?? this.interestRate,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      lenderName: lenderName ?? this.lenderName,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Debt Types
enum DebtType {
  creditCard,
  personalLoan,
  carLoan,
  homeLoan,
  educationLoan,
  businessLoan,
  other;

  String get displayName {
    switch (this) {
      case DebtType.creditCard:
        return 'Credit Card';
      case DebtType.personalLoan:
        return 'Personal Loan';
      case DebtType.carLoan:
        return 'Car Loan';
      case DebtType.homeLoan:
        return 'Home Loan';
      case DebtType.educationLoan:
        return 'Education Loan';
      case DebtType.businessLoan:
        return 'Business Loan';
      case DebtType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case DebtType.creditCard:
        return '💳';
      case DebtType.personalLoan:
        return '💰';
      case DebtType.carLoan:
        return '🚗';
      case DebtType.homeLoan:
        return '🏠';
      case DebtType.educationLoan:
        return '🎓';
      case DebtType.businessLoan:
        return '💼';
      case DebtType.other:
        return '📋';
    }
  }
}

// Debt Status
enum DebtStatus {
  active,
  paidOff,
  defaulted;

  String get displayName {
    switch (this) {
      case DebtStatus.active:
        return 'Active';
      case DebtStatus.paidOff:
        return 'Paid Off';
      case DebtStatus.defaulted:
        return 'Defaulted';
    }
  }
}

// Payment model for tracking individual payments
class DebtPayment {
  final String id;
  final String userId;
  final String debtId;
  final double amount;
  final DateTime paymentDate;
  final String note;
  final DateTime createdAt;

  DebtPayment({
    required this.id,
    required this.userId,
    required this.debtId,
    required this.amount,
    required this.paymentDate,
    this.note = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'debt_id': debtId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DebtPayment.fromJson(Map<String, dynamic> json) {
    return DebtPayment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      debtId: json['debt_id'] as String,
      amount: json['amount'] is int
          ? (json['amount'] as int).toDouble()
          : json['amount'] as double,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      note: json['note'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
