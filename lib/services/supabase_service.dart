import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';
import '../models/money_note.dart';
import '../models/bill.dart';
import '../models/budget.dart';
import '../models/category.dart' as models;

class SupabaseService {
  static final _supabase = Supabase.instance.client;

  // ✅ Add public getter for compatibility
  SupabaseClient get supabase => _supabase;

  // ✅ Get current authenticated user ID with better error handling
  String get currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('❌ No authenticated user found!');
      return '';
    }
    debugPrint('✅ Current user ID: ${user.id}');
    return user.id;
  }

  // ✅ Check if user is authenticated
  static bool get isAuthenticated {
    final isAuth = _supabase.auth.currentUser != null;
    debugPrint('🔍 SupabaseService: Is authenticated: $isAuth');
    return isAuth;
  }

  // ==================== CATEGORIES ====================

  Stream<List<models.Category>> getCategoriesStream() {
    debugPrint('📡 Fetching categories stream...');

    return _supabase.from('categories').stream(primaryKey: ['id']).map((data) {
      final categories =
          data.map((json) => models.Category.fromJson(json)).toList();
      categories.sort((a, b) => a.name.compareTo(b.name));

      debugPrint('✅ Categories loaded: ${categories.length}');
      return categories;
    });
  }

  Future<void> addCategory(models.Category category) async {
    try {
      debugPrint('📝 Adding category: ${category.name}');

      await _supabase.from('categories').insert({
        'id': category.id,
        'name': category.name,
        'icon_code_point': category.iconCodePoint,
        'color_value': category.colorValue,
        'is_default': category.isDefault,
      });

      debugPrint('✅ Category added: ${category.id}');
    } catch (e) {
      debugPrint('❌ Error adding category: $e');
      rethrow;
    }
  }

  Future<void> initializeDefaultCategories(
      List<models.Category> categories) async {
    try {
      debugPrint('🔄 Checking if categories need initialization...');

      final existing = await _supabase.from('categories').select('id').limit(1);

      if (existing.isNotEmpty) {
        debugPrint(
            'ℹ️ Categories already initialized (${existing.length} found)');
        return;
      }

      debugPrint('🔄 Initializing ${categories.length} default categories...');

      final data = categories
          .map((cat) => {
                'id': cat.id,
                'name': cat.name,
                'icon_code_point': cat.iconCodePoint,
                'color_value': cat.colorValue,
                'is_default': cat.isDefault,
              })
          .toList();

      await _supabase.from('categories').insert(data);

      debugPrint(
          '✅ ${categories.length} default categories initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing categories: $e');
      rethrow;
    }
  }

  // ==================== EXPENSES ====================

  Stream<List<Expense>> getExpensesStream() {
    if (!isAuthenticated) {
      debugPrint('❌ Cannot fetch expenses: User not authenticated');
      return Stream.value([]);
    }

    final userId = currentUserId;
    debugPrint('📡 Fetching expenses stream for user: $userId');

    return _supabase.from('expenses').stream(primaryKey: ['id']).map((data) {
      final expenses = data
          .where((item) => item['user_id'] == userId)
          .map((json) => Expense.fromJson(json))
          .toList();

      expenses.sort((a, b) => b.date.compareTo(a.date));

      debugPrint('✅ Expenses loaded: ${expenses.length}');
      return expenses;
    });
  }

  Future<void> addExpense(Expense expense) async {
    try {
      final user = _supabase.auth.currentUser;

      debugPrint('📝 Adding expense...');
      debugPrint('📝 User: ${user?.email ?? "NULL"}');
      debugPrint('📝 User ID: ${user?.id ?? "NULL"}');
      debugPrint('📝 Amount: ${expense.amount}');
      debugPrint('📝 Category: ${expense.categoryId}');

      if (user == null) {
        throw Exception('User not authenticated. Please login again.');
      }

      final expenseData = {
        'id': expense.id,
        'user_id': user.id,
        'amount': expense.amount,
        'category_id': expense.categoryId,
        'note': expense.note,
        'date': expense.date.toIso8601String(),
      };

      debugPrint('📝 Expense data: $expenseData');

      await _supabase.from('expenses').insert(expenseData);

      debugPrint('✅ Expense added successfully: ${expense.id}');
    } catch (e) {
      debugPrint('❌ Error adding expense: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      final userId = currentUserId;

      debugPrint('📝 Updating expense: ${expense.id}');
      debugPrint('📝 User ID: $userId');

      await _supabase
          .from('expenses')
          .update({
            'amount': expense.amount,
            'category_id': expense.categoryId,
            'note': expense.note,
            'date': expense.date.toIso8601String(),
          })
          .eq('id', expense.id)
          .eq('user_id', userId);

      debugPrint('✅ Expense updated: ${expense.id}');
    } catch (e) {
      debugPrint('❌ Error updating expense: $e');
      rethrow;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      final userId = currentUserId;

      debugPrint('🗑️ Deleting expense: $expenseId');
      debugPrint('📝 User ID: $userId');

      await _supabase
          .from('expenses')
          .delete()
          .eq('id', expenseId)
          .eq('user_id', userId);

      debugPrint('✅ Expense deleted: $expenseId');
    } catch (e) {
      debugPrint('❌ Error deleting expense: $e');
      rethrow;
    }
  }

  // ==================== MONEY NOTES ====================

  Stream<List<MoneyNote>> getMoneyNotesStream() {
    if (!isAuthenticated) {
      debugPrint('❌ Cannot fetch money notes: User not authenticated');
      return Stream.value([]);
    }

    final userId = currentUserId;
    debugPrint('📡 Fetching money notes stream for user: $userId');

    return _supabase.from('money_notes').stream(primaryKey: ['id']).map((data) {
      final notes = data
          .where((item) => item['user_id'] == userId)
          .map((json) => MoneyNote.fromJson(json))
          .toList();

      notes.sort((a, b) => b.date.compareTo(a.date));

      debugPrint('✅ Money notes loaded: ${notes.length}');
      return notes;
    });
  }

  Future<void> addMoneyNote(MoneyNote note) async {
    try {
      final user = _supabase.auth.currentUser;

      debugPrint('📝 Adding money note...');
      debugPrint('📝 User: ${user?.email ?? "NULL"}');
      debugPrint('📝 Person: ${note.personName}');
      debugPrint('📝 Amount: ${note.amount}');

      if (user == null) {
        throw Exception('User not authenticated. Please login again.');
      }

      await _supabase.from('money_notes').insert({
        'id': note.id,
        'user_id': user.id,
        'person_name': note.personName,
        'amount': note.amount,
        'remaining_amount': note.remainingAmount,
        'type': note.type,
        'status': note.status,
        'note': note.note,
        'date': note.date.toIso8601String(),
      });

      debugPrint('✅ Money note added: ${note.id}');
    } catch (e) {
      debugPrint('❌ Error adding money note: $e');
      rethrow;
    }
  }

  Future<void> updateMoneyNote(MoneyNote note) async {
    try {
      final userId = currentUserId;

      debugPrint('📝 Updating money note: ${note.id}');

      await _supabase
          .from('money_notes')
          .update({
            'person_name': note.personName,
            'amount': note.amount,
            'remaining_amount': note.remainingAmount,
            'type': note.type,
            'status': note.status,
            'note': note.note,
            'date': note.date.toIso8601String(),
          })
          .eq('id', note.id)
          .eq('user_id', userId);

      debugPrint('✅ Money note updated: ${note.id}');
    } catch (e) {
      debugPrint('❌ Error updating money note: $e');
      rethrow;
    }
  }

  Future<void> deleteMoneyNote(String noteId) async {
    try {
      final userId = currentUserId;

      debugPrint('🗑️ Deleting money note: $noteId');

      await _supabase
          .from('money_notes')
          .delete()
          .eq('id', noteId)
          .eq('user_id', userId);

      debugPrint('✅ Money note deleted: $noteId');
    } catch (e) {
      debugPrint('❌ Error deleting money note: $e');
      rethrow;
    }
  }

  // ==================== BILLS ====================

  Stream<List<Bill>> getBillsStream() {
    if (!isAuthenticated) {
      debugPrint('❌ Cannot fetch bills: User not authenticated');
      return Stream.value([]);
    }

    final userId = currentUserId;
    debugPrint('📡 Fetching bills stream for user: $userId');

    return _supabase.from('bills').stream(primaryKey: ['id']).map((data) {
      final bills = data
          .where((item) => item['user_id'] == userId)
          .map((json) => Bill.fromJson(json))
          .toList();

      bills.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      debugPrint('✅ Bills loaded: ${bills.length}');
      return bills;
    });
  }

  Future<void> addBill(Bill bill) async {
    try {
      final user = _supabase.auth.currentUser;

      debugPrint('📝 Adding bill...');
      debugPrint('📝 User: ${user?.email ?? "NULL"}');
      debugPrint('📝 Bill name: ${bill.name}');
      debugPrint('📝 Amount: ${bill.amount}');

      if (user == null) {
        throw Exception('User not authenticated. Please login again.');
      }

      await _supabase.from('bills').insert({
        'id': bill.id,
        'user_id': user.id,
        'name': bill.name,
        'amount': bill.amount,
        'category_id': bill.categoryId,
        'due_date': bill.dueDate.toIso8601String(),
        'repeat_type': bill.repeatType,
        'status': bill.status,
        'note': bill.note,
      });

      debugPrint('✅ Bill added: ${bill.id}');
    } catch (e) {
      debugPrint('❌ Error adding bill: $e');
      rethrow;
    }
  }

  Future<void> updateBill(Bill bill) async {
    try {
      final userId = currentUserId;

      debugPrint('📝 Updating bill: ${bill.id}');

      await _supabase
          .from('bills')
          .update({
            'name': bill.name,
            'amount': bill.amount,
            'category_id': bill.categoryId,
            'due_date': bill.dueDate.toIso8601String(),
            'repeat_type': bill.repeatType,
            'status': bill.status,
            'note': bill.note,
          })
          .eq('id', bill.id)
          .eq('user_id', userId);

      debugPrint('✅ Bill updated: ${bill.id}');
    } catch (e) {
      debugPrint('❌ Error updating bill: $e');
      rethrow;
    }
  }

  Future<void> deleteBill(String billId) async {
    try {
      final userId = currentUserId;

      debugPrint('🗑️ Deleting bill: $billId');

      await _supabase
          .from('bills')
          .delete()
          .eq('id', billId)
          .eq('user_id', userId);

      debugPrint('✅ Bill deleted: $billId');
    } catch (e) {
      debugPrint('❌ Error deleting bill: $e');
      rethrow;
    }
  }

  // ==================== BUDGETS ====================

  Stream<List<Budget>> getBudgetsStream() {
    if (!isAuthenticated) {
      debugPrint('❌ Cannot fetch budgets: User not authenticated');
      return Stream.value([]);
    }

    final userId = currentUserId;
    debugPrint('📡 Fetching budgets stream for user: $userId');

    return _supabase.from('budgets').stream(primaryKey: ['id']).map((data) {
      final budgets = data
          .where((item) => item['user_id'] == userId)
          .map((json) => Budget.fromJson(json))
          .toList();

      budgets.sort((a, b) {
        final yearCompare = b.year.compareTo(a.year);
        if (yearCompare != 0) return yearCompare;
        return b.month.compareTo(a.month);
      });

      debugPrint('✅ Budgets loaded: ${budgets.length}');
      return budgets;
    });
  }

  Future<void> addBudget(Budget budget) async {
    try {
      final userId = currentUserId;

      debugPrint('📝 Adding budget for ${budget.month}/${budget.year}');

      await _supabase.from('budgets').insert({
        'id': budget.id,
        'user_id': userId,
        'month': budget.month,
        'year': budget.year,
        'base_amount': budget.baseAmount,
        'adjustments': budget.adjustments.map((a) => a.toJson()).toList(),
      });

      debugPrint('✅ Budget added: ${budget.id}');
    } catch (e) {
      debugPrint('❌ Error adding budget: $e');
      rethrow;
    }
  }

  Future<void> updateBudget(Budget budget) async {
    try {
      final userId = currentUserId;

      debugPrint('📝 Updating budget: ${budget.id}');

      await _supabase
          .from('budgets')
          .update({
            'month': budget.month,
            'year': budget.year,
            'base_amount': budget.baseAmount,
            'adjustments': budget.adjustments.map((a) => a.toJson()).toList(),
          })
          .eq('id', budget.id)
          .eq('user_id', userId);

      debugPrint('✅ Budget updated: ${budget.id}');
    } catch (e) {
      debugPrint('❌ Error updating budget: $e');
      rethrow;
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      final userId = currentUserId;

      debugPrint('🗑️ Deleting budget: $budgetId');

      await _supabase
          .from('budgets')
          .delete()
          .eq('id', budgetId)
          .eq('user_id', userId);

      debugPrint('✅ Budget deleted: $budgetId');
    } catch (e) {
      debugPrint('❌ Error deleting budget: $e');
      rethrow;
    }
  }

  // ==================== MULTI BUDGETS ====================

  Stream<List<MultiBudget>> getMultiBudgetsStream() {
    if (!isAuthenticated) {
      debugPrint('❌ Cannot fetch multi budgets: User not authenticated');
      return Stream.value([]);
    }

    final userId = currentUserId;
    debugPrint('📡 Fetching multi budgets stream for user: $userId');

    return _supabase
        .from('multi_budgets')
        .stream(primaryKey: ['id']).map((data) {
      final multiBudgets = data
          .where((item) => item['user_id'] == userId)
          .map((json) => MultiBudget.fromJson(json))
          .toList();

      multiBudgets.sort((a, b) => b.startDate.compareTo(a.startDate));

      debugPrint('✅ Multi budgets loaded: ${multiBudgets.length}');
      return multiBudgets;
    });
  }

  Future<void> addMultiBudget(MultiBudget multiBudget) async {
    try {
      final userId = currentUserId;

      debugPrint('📝 Adding multi budget: ${multiBudget.name}');

      await _supabase.from('multi_budgets').insert({
        'id': multiBudget.id,
        'user_id': userId,
        'name': multiBudget.name,
        'monthly_amount': multiBudget.monthlyAmount,
        'start_date': multiBudget.startDate.toIso8601String(),
        'duration_months': multiBudget.durationMonths,
        'category_id': multiBudget.categoryId,
        'is_active': multiBudget.isActive,
      });

      debugPrint('✅ Multi budget added: ${multiBudget.id}');
    } catch (e) {
      debugPrint('❌ Error adding multi budget: $e');
      rethrow;
    }
  }

  Future<void> updateMultiBudget(MultiBudget multiBudget) async {
    try {
      final userId = currentUserId;

      debugPrint('📝 Updating multi budget: ${multiBudget.id}');

      await _supabase
          .from('multi_budgets')
          .update({
            'name': multiBudget.name,
            'monthly_amount': multiBudget.monthlyAmount,
            'start_date': multiBudget.startDate.toIso8601String(),
            'duration_months': multiBudget.durationMonths,
            'category_id': multiBudget.categoryId,
            'is_active': multiBudget.isActive,
          })
          .eq('id', multiBudget.id)
          .eq('user_id', userId);

      debugPrint('✅ Multi budget updated: ${multiBudget.id}');
    } catch (e) {
      debugPrint('❌ Error updating multi budget: $e');
      rethrow;
    }
  }

  Future<void> deleteMultiBudget(String multiBudgetId) async {
    try {
      final userId = currentUserId;

      debugPrint('🗑️ Deleting multi budget: $multiBudgetId');

      await _supabase
          .from('multi_budgets')
          .delete()
          .eq('id', multiBudgetId)
          .eq('user_id', userId);

      debugPrint('✅ Multi budget deleted: $multiBudgetId');
    } catch (e) {
      debugPrint('❌ Error deleting multi budget: $e');
      rethrow;
    }
  }

  // ==================== ADDITIONAL BUDGET METHODS ====================

  Stream<MonthlyBudget?> getBudgetStream(int month, int year) {
    if (!isAuthenticated) {
      debugPrint('❌ Cannot fetch budget: User not authenticated');
      return Stream.value(null);
    }

    final userId = currentUserId;
    debugPrint('📡 Fetching budget for $month/$year (user: $userId)');

    return _supabase.from('budgets').stream(primaryKey: ['id']).map((data) {
      try {
        final budget = data.firstWhere(
          (item) =>
              item['user_id'] == userId &&
              item['month'] == month &&
              item['year'] == year,
        );

        debugPrint('✅ Budget found for $month/$year');
        return MonthlyBudget.fromJson(budget);
      } catch (e) {
        debugPrint('ℹ️ No budget found for $month/$year');
        return null;
      }
    });
  }

  Stream<List<MonthlyBudget>> getAllBudgetsStream() {
    debugPrint('📡 Fetching all budgets stream');
    return getBudgetsStream();
  }

  Future<void> saveBudget(MonthlyBudget budget) async {
    try {
      final userId = currentUserId;

      debugPrint('💾 Saving budget for ${budget.month}/${budget.year}');
      debugPrint('💾 User ID: $userId');

      final existing = await _supabase
          .from('budgets')
          .select('id')
          .eq('user_id', userId)
          .eq('month', budget.month)
          .eq('year', budget.year)
          .maybeSingle();

      if (existing != null) {
        debugPrint('🔄 Budget exists, updating...');
        await updateBudget(budget);
      } else {
        debugPrint('➕ Budget doesn\'t exist, inserting...');
        await addBudget(budget);
      }

      debugPrint('✅ Budget saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving budget: $e');
      rethrow;
    }
  }

  Future<void> saveMultiBudget(MultiBudget multiBudget) async {
    try {
      final userId = currentUserId;

      debugPrint('💾 Saving multi-budget: ${multiBudget.name}');
      debugPrint('💾 User ID: $userId');

      final existing = await _supabase
          .from('multi_budgets')
          .select('id')
          .eq('id', multiBudget.id)
          .maybeSingle();

      if (existing != null) {
        debugPrint('🔄 Multi-budget exists, updating...');
        await updateMultiBudget(multiBudget);
      } else {
        debugPrint('➕ Multi-budget doesn\'t exist, inserting...');
        await addMultiBudget(multiBudget);
      }

      debugPrint('✅ Multi-budget saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving multi-budget: $e');
      rethrow;
    }
  }

  // ==================== INCOME METHODS ====================

  Future<List<Map<String, dynamic>>> getIncomes() async {
    try {
      debugPrint('✅ SupabaseService: Current user ID: $currentUserId');

      final response = await _supabase
          .from('income')
          .select()
          .eq('user_id', currentUserId)
          .order('date', ascending: false);

      debugPrint('📊 Fetched ${response.length} incomes');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching incomes: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> get incomeStream {
    return _supabase
        .from('income')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .order('date', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<void> addIncome(Map<String, dynamic> income) async {
    try {
      debugPrint('💾 Adding income: ${income['source']}');
      debugPrint('💾 Amount: ${income['amount']}');
      debugPrint('💾 User ID: $currentUserId');

      await _supabase.from('income').insert(income);

      debugPrint('✅ Income added successfully');
    } catch (e) {
      debugPrint('❌ Error adding income: $e');
      rethrow;
    }
  }

  Future<void> updateIncome(Map<String, dynamic> income) async {
    try {
      final id = income['id'];
      debugPrint('📝 Updating income: $id');
      debugPrint('📝 User ID: $currentUserId');

      await _supabase
          .from('income')
          .update(income)
          .eq('id', id)
          .eq('user_id', currentUserId);

      debugPrint('✅ Income updated: $id');
    } catch (e) {
      debugPrint('❌ Error updating income: $e');
      rethrow;
    }
  }

  Future<void> deleteIncome(String id) async {
    try {
      debugPrint('🗑️ Deleting income: $id');

      await _supabase
          .from('income')
          .delete()
          .eq('id', id)
          .eq('user_id', currentUserId);

      debugPrint('✅ Income deleted: $id');
    } catch (e) {
      debugPrint('❌ Error deleting income: $e');
      rethrow;
    }
  }

  // ✅ FIXED: Instance method for getting current user ID
  String? currentUserIdMethod() {
    return _supabase.auth.currentUser?.id;
  }
  // ==================== SAVINGS GOALS METHODS ====================

  /// Get all savings goals for current user
  Future<List<Map<String, dynamic>>> getSavingsGoals() async {
    try {
      debugPrint('✅ SupabaseService: Current user ID: $currentUserId');

      final response = await _supabase
          .from('savings_goals')
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      debugPrint('🎯 Fetched ${response.length} savings goals');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching savings goals: $e');
      rethrow;
    }
  }

  /// Real-time savings goals stream
  Stream<List<Map<String, dynamic>>> get savingsGoalsStream {
    return _supabase
        .from('savings_goals')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Add new savings goal
  Future<void> addSavingsGoal(Map<String, dynamic> goal) async {
    try {
      debugPrint('💾 Adding savings goal: ${goal['name']}');
      debugPrint('💾 Target: ${goal['target_amount']}');
      debugPrint('💾 User ID: $currentUserId');

      await _supabase.from('savings_goals').insert(goal);

      debugPrint('✅ Savings goal added successfully');
    } catch (e) {
      debugPrint('❌ Error adding savings goal: $e');
      rethrow;
    }
  }

  /// Update savings goal
  Future<void> updateSavingsGoal(Map<String, dynamic> goal) async {
    try {
      final id = goal['id'];
      debugPrint('📝 Updating savings goal: $id');
      debugPrint('📝 User ID: $currentUserId');

      await _supabase
          .from('savings_goals')
          .update(goal)
          .eq('id', id)
          .eq('user_id', currentUserId);

      debugPrint('✅ Savings goal updated: $id');
    } catch (e) {
      debugPrint('❌ Error updating savings goal: $e');
      rethrow;
    }
  }

  /// Delete savings goal
  Future<void> deleteSavingsGoal(String id) async {
    try {
      debugPrint('🗑️ Deleting savings goal: $id');

      await _supabase
          .from('savings_goals')
          .delete()
          .eq('id', id)
          .eq('user_id', currentUserId);

      debugPrint('✅ Savings goal deleted: $id');
    } catch (e) {
      debugPrint('❌ Error deleting savings goal: $e');
      rethrow;
    }
  }
  // ==================== DEBT MANAGEMENT METHODS ====================

  /// Get all debts for current user
  // ==================== DEBT MANAGEMENT METHODS ====================

  /// Get all debts for current user
  Future<List<Map<String, dynamic>>> getDebts() async {
    try {
      debugPrint('SupabaseService: Fetching debts for user: $currentUserId');

      final response = await _supabase
          .from('debts')
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      debugPrint('Fetched ${response.length} debts');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('ERROR: Error fetching debts: $e');
      rethrow;
    }
  }

  /// Real-time debts stream
  Stream<List<Map<String, dynamic>>> get debtsStream {
    return _supabase
        .from('debts')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Add new debt
  Future<void> addDebt(Map<String, dynamic> debt) async {
    try {
      debugPrint('Adding debt: ${debt['name']}');
      debugPrint('Amount: ${debt['total_amount']}');
      debugPrint('User ID: $currentUserId');

      await _supabase.from('debts').insert(debt);

      debugPrint('Debt added successfully');
    } catch (e) {
      debugPrint('ERROR: Error adding debt: $e');
      rethrow;
    }
  }

  /// Update debt
  Future<void> updateDebt(Map<String, dynamic> debt) async {
    try {
      final id = debt['id'];
      debugPrint('Updating debt: $id');
      debugPrint('User ID: $currentUserId');

      await _supabase
          .from('debts')
          .update(debt)
          .eq('id', id)
          .eq('user_id', currentUserId);

      debugPrint('Debt updated: $id');
    } catch (e) {
      debugPrint('ERROR: Error updating debt: $e');
      rethrow;
    }
  }

  /// Delete debt
  Future<void> deleteDebt(String id) async {
    try {
      debugPrint('Deleting debt: $id');

      await _supabase
          .from('debts')
          .delete()
          .eq('id', id)
          .eq('user_id', currentUserId);

      debugPrint('Debt deleted: $id');
    } catch (e) {
      debugPrint('ERROR: Error deleting debt: $e');
      rethrow;
    }
  }

  /// Get all debt payments
  Future<List<Map<String, dynamic>>> getDebtPayments() async {
    try {
      debugPrint(
          'SupabaseService: Fetching debt payments for user: $currentUserId');

      final response = await _supabase
          .from('debt_payments')
          .select()
          .eq('user_id', currentUserId)
          .order('payment_date', ascending: false);

      debugPrint('Fetched ${response.length} debt payments');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('ERROR: Error fetching debt payments: $e');
      rethrow;
    }
  }

  /// Real-time debt payments stream
  Stream<List<Map<String, dynamic>>> get debtPaymentsStream {
    return _supabase
        .from('debt_payments')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .order('payment_date', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Add debt payment
  Future<void> addDebtPayment(Map<String, dynamic> payment) async {
    try {
      debugPrint('Adding debt payment: ${payment['amount']}');

      await _supabase.from('debt_payments').insert(payment);

      debugPrint('Debt payment added successfully');
    } catch (e) {
      debugPrint('ERROR: Error adding debt payment: $e');
      rethrow;
    }
  }
}
