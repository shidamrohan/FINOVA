class Income {
  final String id;
  final String userId;
  final String source; // Salary, Freelance, Business, Investments, Bonus, Other
  final double amount;
  final DateTime date;
  final String note;
  final String? category; // Optional: for sub-categorization
  final bool isRecurring;
  final String? recurringFrequency; // monthly, weekly, yearly
  final DateTime createdAt;
  final DateTime updatedAt;

  Income({
    required this.id,
    required this.userId,
    required this.source,
    required this.amount,
    required this.date,
    this.note = '',
    this.category,
    this.isRecurring = false,
    this.recurringFrequency,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'source': source,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'category': category,
      'is_recurring': isRecurring,
      'recurring_frequency': recurringFrequency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON (Supabase)
  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      source: json['source'] as String,
      amount: _parseAmount(json['amount']),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String? ?? '',
      category: json['category'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurringFrequency: json['recurring_frequency'] as String?,
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

  Income copyWith({
    String? id,
    String? userId,
    String? source,
    double? amount,
    DateTime? date,
    String? note,
    String? category,
    bool? isRecurring,
    String? recurringFrequency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Income(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      source: source ?? this.source,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      category: category ?? this.category,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Income source types
class IncomeSource {
  static const String salary = 'Salary';
  static const String freelance = 'Freelance';
  static const String business = 'Business';
  static const String investments = 'Investments';
  static const String bonus = 'Bonus';
  static const String other = 'Other';

  static List<String> get all => [
        salary,
        freelance,
        business,
        investments,
        bonus,
        other,
      ];

  static String getIcon(String source) {
    switch (source) {
      case salary:
        return '💼';
      case freelance:
        return '💻';
      case business:
        return '🏢';
      case investments:
        return '📈';
      case bonus:
        return '🎁';
      case other:
        return '💰';
      default:
        return '💵';
    }
  }
}
