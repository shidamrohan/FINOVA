class Bill {
  final String id;
  final String name;
  final double amount;
  final String categoryId;
  final DateTime dueDate;
  final String repeatType;
  final String status;
  final String? note;

  Bill({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.dueDate,
    required this.repeatType,
    required this.status,
    this.note,
  });

  // ✅ UPDATED: Convert to Map for Supabase (snake_case fields)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category_id': categoryId, // ✅ Changed to snake_case
      'due_date': dueDate.toIso8601String(), // ✅ Changed to snake_case
      'repeat_type': repeatType, // ✅ Changed to snake_case
      'status': status,
      'note': note,
    };
  }

  // ✅ UPDATED: Create from Map (Supabase uses snake_case)
  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: _parseAmount(json['amount']), // ✅ Safe parsing
      categoryId: json['category_id'] as String, // ✅ Changed from categoryId
      dueDate:
          DateTime.parse(json['due_date'] as String), // ✅ Changed from dueDate
      repeatType: json['repeat_type'] as String, // ✅ Changed from repeatType
      status: json['status'] as String,
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

  factory Bill.fromMap(Map<String, dynamic> map) {
    // Try new format first, fall back to old format
    if (map.containsKey('category_id')) {
      return Bill.fromJson(map);
    }
    // Old format (camelCase)
    return Bill(
      id: map['id'],
      name: map['name'],
      amount: _parseAmount(map['amount']),
      categoryId: map['categoryId'],
      dueDate: DateTime.parse(map['dueDate']),
      repeatType: map['repeatType'],
      status: map['status'],
      note: map['note'],
    );
  }

  bool get isPaid => status == 'paid';

  // Copy with method (unchanged)
  Bill copyWith({
    String? id,
    String? name,
    double? amount,
    String? categoryId,
    DateTime? dueDate,
    String? repeatType,
    String? status,
    String? note,
  }) {
    return Bill(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      dueDate: dueDate ?? this.dueDate,
      repeatType: repeatType ?? this.repeatType,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }
}
