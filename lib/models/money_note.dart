class MoneyNote {
  final String id;
  final double amount;
  final double remainingAmount;
  final String personName;
  final DateTime date;
  final String type; // 'gave' or 'took'
  final String status; // 'open' or 'settled'
  final String? note;

  MoneyNote({
    required this.id,
    required this.amount,
    required this.remainingAmount,
    required this.personName,
    required this.date,
    required this.type,
    required this.status,
    this.note,
  });

  // ✅ UPDATED: Convert to Map for Supabase (snake_case fields)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'remaining_amount': remainingAmount, // ✅ Changed to snake_case
      'person_name': personName, // ✅ Changed to snake_case
      'date': date.toIso8601String(),
      'type': type,
      'status': status,
      'note': note,
    };
  }

  // ✅ UPDATED: Create from Map (Supabase uses snake_case)
  factory MoneyNote.fromJson(Map<String, dynamic> json) {
    return MoneyNote(
      id: json['id'] as String,
      amount: _parseAmount(json['amount']), // ✅ Safe parsing
      remainingAmount: _parseAmount(
          json['remaining_amount']), // ✅ Changed from remainingAmount
      personName: json['person_name'] as String, // ✅ Changed from personName
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
      status: json['status'] as String,
      note: json['note'] as String?,
    );
  }

  // ✅ ADDED: Helper method to safely parse amounts
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

  factory MoneyNote.fromMap(Map<String, dynamic> map) {
    // Try new format first, fall back to old format
    if (map.containsKey('person_name')) {
      return MoneyNote.fromJson(map);
    }
    // Old format (camelCase)
    return MoneyNote(
      id: map['id'],
      amount: _parseAmount(map['amount']),
      remainingAmount: _parseAmount(map['remainingAmount']),
      personName: map['personName'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      status: map['status'],
      note: map['note'],
    );
  }

  // Copy with method (unchanged)
  MoneyNote copyWith({
    String? id,
    double? amount,
    double? remainingAmount,
    String? personName,
    DateTime? date,
    String? type,
    String? status,
    String? note,
  }) {
    return MoneyNote(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      personName: personName ?? this.personName,
      date: date ?? this.date,
      type: type ?? this.type,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }
}
