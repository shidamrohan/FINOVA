class SavingsGoal {
  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String? icon; // emoji or icon name
  final String? colorHex; // #FF5733
  final String note;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavingsGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    this.icon,
    this.colorHex,
    this.note = '',
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get progress percentage (0-100)
  double get progressPercentage {
    if (targetAmount <= 0) return 0;
    final percentage = (currentAmount / targetAmount) * 100;
    return percentage > 100 ? 100 : percentage;
  }

  // Get remaining amount
  double get remainingAmount {
    final remaining = targetAmount - currentAmount;
    return remaining > 0 ? remaining : 0;
  }

  // Check if goal is reached
  bool get isReached => currentAmount >= targetAmount;

  // Days remaining (if target date is set)
  int? get daysRemaining {
    if (targetDate == null) return null;
    final now = DateTime.now();
    final difference = targetDate!.difference(now).inDays;
    return difference;
  }

  // Is overdue?
  bool get isOverdue {
    if (targetDate == null) return false;
    return DateTime.now().isAfter(targetDate!) && !isReached;
  }

  // Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate?.toIso8601String(),
      'icon': icon,
      'color_hex': colorHex,
      'note': note,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON (Supabase)
  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      targetAmount: _parseAmount(json['target_amount']),
      currentAmount: _parseAmount(json['current_amount'] ?? 0),
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      icon: json['icon'] as String?,
      colorHex: json['color_hex'] as String?,
      note: json['note'] as String? ?? '',
      isCompleted: json['is_completed'] as bool? ?? false,
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

  SavingsGoal copyWith({
    String? id,
    String? userId,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? icon,
    String? colorHex,
    String? note,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      note: note ?? this.note,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Preset savings goal types
class SavingsGoalPreset {
  final String name;
  final String icon;
  final String colorHex;

  const SavingsGoalPreset({
    required this.name,
    required this.icon,
    required this.colorHex,
  });

  static const vacation = SavingsGoalPreset(
    name: 'Vacation',
    icon: '✈️',
    colorHex: '#FF6B6B',
  );

  static const car = SavingsGoalPreset(
    name: 'Car',
    icon: '🚗',
    colorHex: '#4ECDC4',
  );

  static const house = SavingsGoalPreset(
    name: 'House',
    icon: '🏠',
    colorHex: '#95E1D3',
  );

  static const emergency = SavingsGoalPreset(
    name: 'Emergency Fund',
    icon: '🆘',
    colorHex: '#F38181',
  );

  static const education = SavingsGoalPreset(
    name: 'Education',
    icon: '🎓',
    colorHex: '#AA96DA',
  );

  static const wedding = SavingsGoalPreset(
    name: 'Wedding',
    icon: '💍',
    colorHex: '#FCBAD3',
  );

  static const gadget = SavingsGoalPreset(
    name: 'Gadget',
    icon: '📱',
    colorHex: '#A8D8EA',
  );

  static const investment = SavingsGoalPreset(
    name: 'Investment',
    icon: '📈',
    colorHex: '#FFD93D',
  );

  static const other = SavingsGoalPreset(
    name: 'Other',
    icon: '💰',
    colorHex: '#6BCB77',
  );

  static List<SavingsGoalPreset> get all => [
        vacation,
        car,
        house,
        emergency,
        education,
        wedding,
        gadget,
        investment,
        other,
      ];
}
