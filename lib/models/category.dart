class Category {
  final String id;
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final bool isDefault;

  Category({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    this.isDefault = false,
  });

  // ✅ UPDATED: Convert to Map for Supabase (snake_case fields)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_code_point': iconCodePoint, // ✅ Changed to snake_case
      'color_value': colorValue, // ✅ Changed to snake_case
      'is_default': isDefault, // ✅ Changed to snake_case
    };
  }

  // ✅ UPDATED: Create from Map (Supabase uses snake_case)
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCodePoint:
          json['icon_code_point'] as int, // ✅ Changed from iconCodePoint
      colorValue: _parseColorValue(json['color_value']), // ✅ Safe parsing
      isDefault:
          json['is_default'] as bool? ?? false, // ✅ Changed from isDefault
    );
  }

  int? get color => null;

  int? get icon => null;

  // ✅ ADDED: Helper method to safely parse color value
  // Supabase returns BIGINT, which might come as String or int
  static int _parseColorValue(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    if (value is num) return value.toInt();
    return 0xFF000000; // Default black color if parsing fails
  }

  // Copy with method (unchanged)
  Category copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
