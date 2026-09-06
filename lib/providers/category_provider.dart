import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../services/supabase_service.dart'; // ✅ CHANGED: firebase → supabase
import 'dart:async';

class CategoryProvider with ChangeNotifier {
  final SupabaseService _supabaseService =
      SupabaseService(); // ✅ CHANGED: Firebase → Supabase

  List<Category> _categories = [];
  StreamSubscription<List<Category>>? _categoriesSubscription;
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  List<Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get error => _error;

  CategoryProvider() {
    _initializeCategories();
  }

  /// Initialize and listen to Supabase stream
  void _initializeCategories() async {
    _isLoading = true;
    notifyListeners();

    // Start listening to categories stream
    _categoriesSubscription = _supabaseService.getCategoriesStream().listen(
      // ✅ CHANGED: firebase → supabase
      (categories) {
        _categories = categories;
        _isLoading = false;
        _error = null;
        notifyListeners();
        print(
            '✅ Categories loaded from Supabase: ${categories.length}'); // ✅ CHANGED: Firestore → Supabase

        // Initialize defaults if empty (after first load)
        if (!_initialized && categories.isEmpty) {
          _initialized = true;
          _initializeDefaults();
        } else {
          _initialized = true;
        }
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
        print('❌ Error loading categories: $error');
      },
    );
  }

  /// Initialize default categories
  Future<void> _initializeDefaults() async {
    try {
      print('📦 Initializing default categories...');
      await _supabaseService // ✅ CHANGED: firebase → supabase
          .initializeDefaultCategories(_getDefaultCategories());
      print('✅ Default categories initialized');
    } catch (e) {
      print('❌ Error initializing defaults: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get default categories
  List<Category> _getDefaultCategories() {
    return [
      Category(
        id: 'cat_food',
        name: 'Food & Dining',
        iconCodePoint: 0xe57f, // restaurant
        colorValue: 0xFFFF6B6B,
        isDefault: true,
      ),
      Category(
        id: 'cat_transport',
        name: 'Transportation',
        iconCodePoint: 0xe558, // directions_car
        colorValue: 0xFF4ECDC4,
        isDefault: true,
      ),
      Category(
        id: 'cat_shopping',
        name: 'Shopping',
        iconCodePoint: 0xe59c, // shopping_bag
        colorValue: 0xFF95E1D3,
        isDefault: true,
      ),
      Category(
        id: 'cat_entertainment',
        name: 'Entertainment',
        iconCodePoint: 0xe412, // movie
        colorValue: 0xFFF38181,
        isDefault: true,
      ),
      Category(
        id: 'cat_bills',
        name: 'Bills & Utilities',
        iconCodePoint: 0xe8b8, // receipt
        colorValue: 0xFFAA96DA,
        isDefault: true,
      ),
      Category(
        id: 'cat_health',
        name: 'Healthcare',
        iconCodePoint: 0xe3f7, // local_hospital
        colorValue: 0xFFFCACA,
        isDefault: true,
      ),
      Category(
        id: 'cat_education',
        name: 'Education',
        iconCodePoint: 0xe80c, // school
        colorValue: 0xFFFFD93D,
        isDefault: true,
      ),
      Category(
        id: 'cat_other',
        name: 'Other',
        iconCodePoint: 0xe8f9, // more_horiz
        colorValue: 0xFFBDC3C7,
        isDefault: true,
      ),
    ];
  }

  /// Manually trigger default category initialization (for debugging)
  Future<void> forceInitializeDefaults() async {
    await _initializeDefaults();
  }

  /// Add a new category
  Future<void> addCategory(Category category) async {
    try {
      await _supabaseService
          .addCategory(category); // ✅ CHANGED: firebase → supabase
      print('✅ Category added successfully');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      print('❌ Error adding category: $e');
      rethrow;
    }
  }

  /// Get category by ID
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      print('⚠️ Category not found: $id');
      return null;
    }
  }

  /// Get default categories only
  List<Category> get defaultCategories {
    return _categories.where((cat) => cat.isDefault).toList();
  }

  /// Get custom categories only
  List<Category> get customCategories {
    return _categories.where((cat) => !cat.isDefault).toList();
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    super.dispose();
  }
}
