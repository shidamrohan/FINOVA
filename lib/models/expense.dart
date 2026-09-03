class Expense {
  final String id;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String? note;

  Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
  });

  // ✅ UPDATED: Convert to Map for Supabase (snake_case fields)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category_id': categoryId, // ✅ Changed to snake_case
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  // ✅ UPDATED: Create from Map (Supabase uses snake_case)
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      amount: _parseAmount(json['amount']), // ✅ Safe parsing
      categoryId: json['category_id'] as String, // ✅ Changed from categoryId
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }

  // ✅ ADDED: Helper method to safely parse amount
  // Supabase DECIMAL can return as num, int, double, or String
  static double _parseAmount(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0.0; // Fallback
  }

  // ✅ KEPT: Backward compatibility with old local storage
  // (Remove these after migration is complete if not needed)
  Map<String, dynamic> toMap() => toJson();

  factory Expense.fromMap(Map<String, dynamic> map) {
    // Try new format first, fall back to old format
    if (map.containsKey('category_id')) {
      return Expense.fromJson(map);
    }
    // Old format (camelCase)
    return Expense(
      id: map['id'],
      amount: _parseAmount(map['amount']),
      categoryId: map['categoryId'],
      date: DateTime.parse(map['date']),
      note: map['note'],
    );
  }

  // Copy with method (unchanged)
  Expense copyWith({
    String? id,
    double? amount,
    String? categoryId,
    DateTime? date,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
