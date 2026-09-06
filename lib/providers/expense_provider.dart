import '../main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/expense.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'budget_provider.dart';
import 'notification_provider.dart';
import 'settings_provider.dart';

class ExpenseProvider with ChangeNotifier {
  final SupabaseService _supabaseService;

  List<Expense> _expenses = [];
  RealtimeChannel? _realtimeChannel;
  bool _isLoading = false;
  String? _error;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ExpenseProvider(SupabaseService supabaseService)
      : _supabaseService = supabaseService {
    debugPrint('🚀 ExpenseProvider: Initializing...');
    if (SupabaseService.isAuthenticated) {
      _initializeExpenses();
    }
  }

  /// Schedule notifyListeners safely (avoids calling during build)
  void _safeNotify() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }

  /// Initial load + subscribe to realtime changes
  Future<void> _initializeExpenses() async {
    if (!SupabaseService.isAuthenticated) {
      _isLoading = false;
      _safeNotify();
      return;
    }

    debugPrint('📡 ExpenseProvider: Setting up expenses...');
    _isLoading = true;
    _safeNotify();

    // 1. Initial fetch
    await _fetchExpenses();

    // 2. Subscribe to realtime changes
    _subscribeToChanges();
  }

  /// Re-fetch data after login (called from main.dart onAuthStateChange)
  Future<void> refreshData() async {
    debugPrint('🔄 ExpenseProvider: Refreshing data after auth change...');
    await _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;

    if (!SupabaseService.isAuthenticated) {
      _expenses = [];
      _isLoading = false;
      _safeNotify();
      return;
    }

    await _initializeExpenses();
  }

  /// Fetch all expenses from Supabase
  Future<void> _fetchExpenses() async {
    try {
      if (!SupabaseService.isAuthenticated) {
        debugPrint('❌ ExpenseProvider: Not authenticated');
        _isLoading = false;
        _safeNotify();
        return;
      }

      final userId = _supabaseService.currentUserId;
      debugPrint('📥 ExpenseProvider: Fetching expenses for user: $userId');

      final data = await Supabase.instance.client
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      _expenses = (data as List)
          .map((json) => Expense.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ ExpenseProvider: Loaded ${_expenses.length} expenses');
      _isLoading = false;
      _error = null;
      _safeNotify();
    } catch (e) {
      debugPrint('❌ ExpenseProvider: Error fetching expenses: $e');
      _error = e.toString();
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Subscribe to Supabase Realtime for INSERT/UPDATE/DELETE events
  void _subscribeToChanges() {
    final userId = _supabaseService.currentUserId;
    if (userId.isEmpty) return;
    debugPrint('👂 ExpenseProvider: Subscribing to realtime changes...');

    _realtimeChannel = Supabase.instance.client
        .channel('expenses_changes_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expenses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint(
                '🔄 ExpenseProvider: Realtime event: ${payload.eventType}');
            _fetchExpenses(); // Re-fetch on any change
          },
        )
        .subscribe((status, [error]) {
      debugPrint('📡 ExpenseProvider: Realtime status: $status');
      if (error != null) {
        debugPrint('❌ ExpenseProvider: Realtime error: $error');
      }
    });
  }

  /// Add a new expense
  Future<void> addExpense(Expense expense) async {
    try {
      debugPrint('➕ ExpenseProvider: Adding expense...');
      debugPrint('   Amount: \$${expense.amount}');
      debugPrint('   Note: ${expense.note}');
      debugPrint('   Category: ${expense.categoryId}');

      await _supabaseService.addExpense(expense);

      // Immediately refresh local list so UI updates without waiting for realtime
      await _fetchExpenses();

      debugPrint('✅ ExpenseProvider: Expense added and UI refreshed');

      // Send instant notification
      try {
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          final notificationProvider = context.read<NotificationProvider>();
          final settingsProvider = context.read<SettingsProvider>();
          await notificationProvider.sendExpenseAdded(
            amount: expense.amount,
          category: expense.categoryId,
          currency: settingsProvider.currency,
          note: expense.note,
        );
        }
      } catch (e) {
        debugPrint('❌ ExpenseProvider: Error sending expense notification: $e');
      }

      // Check budget alerts after adding expense
      await _checkBudgetAfterExpense();
    } catch (e) {
      debugPrint('❌ ExpenseProvider: Error adding expense: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Check budget alerts after adding expense
  Future<void> _checkBudgetAfterExpense() async {
    try {
      final now = DateTime.now();
      final currentMonthSpent = getTotalByMonth(now);

      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        final budgetProvider = context.read<BudgetProvider>();
        await budgetProvider.triggerBudgetAlertIfNeeded(currentMonthSpent);

        // Also check category overspend for multi-budgets
        final categoryTotals = getCategoryTotalsByMonth(now);
        await budgetProvider.checkCategoryOverspend(categoryTotals);
      }

      debugPrint('ExpenseProvider: Budget alert check completed');
    } catch (e) {
      debugPrint('ExpenseProvider: Error checking budget: $e');
    }
  }

  /// Update an existing expense
  Future<void> updateExpense(Expense expense) async {
    try {
      debugPrint('📝 ExpenseProvider: Updating expense ${expense.id}...');

      await _supabaseService.updateExpense(expense);

      // Immediately refresh local list so UI updates without waiting for realtime
      await _fetchExpenses();

      debugPrint('✅ ExpenseProvider: Expense updated and UI refreshed');

      // ✅ CHECK BUDGET ALERTS AFTER UPDATING EXPENSE
      await _checkBudgetAfterExpense();
    } catch (e) {
      debugPrint('❌ ExpenseProvider: Error updating expense: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      debugPrint('🗑️ ExpenseProvider: Deleting expense $expenseId...');

      // Capture amount before deletion for notification
      final expense = _expenses.where((e) => e.id == expenseId).firstOrNull;

      await _supabaseService.deleteExpense(expenseId);

      // Immediately refresh local list so UI updates without waiting for realtime
      await _fetchExpenses();

      debugPrint('✅ ExpenseProvider: Expense deleted and UI refreshed');

      // Send instant notification
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted && expense != null) {
        try {
          final notificationProvider = context.read<NotificationProvider>();
          final settingsProvider = context.read<SettingsProvider>();
          await notificationProvider.sendExpenseDeleted(
            amount: expense.amount,
            currency: settingsProvider.currency,
          );
        } catch (e) {
          debugPrint(
              '❌ ExpenseProvider: Error sending delete notification: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ ExpenseProvider: Error deleting expense: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Get expense by ID
  Expense? getExpenseById(String id) {
    try {
      return _expenses.firstWhere((expense) => expense.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get total expenses for a specific month
  double getTotalByMonth(DateTime date) {
    final month = date.month;
    final year = date.year;

    final total = _expenses
        .where((expense) =>
            expense.date.month == month && expense.date.year == year)
        .fold(0.0, (sum, expense) => sum + expense.amount);

    debugPrint('💰 Total for $month/$year: \$$total');
    return total;
  }

  /// Get total expenses for a specific month (by month and year)
  double getMonthlyTotal(int month, int year) {
    final total = _expenses
        .where((expense) =>
            expense.date.month == month && expense.date.year == year)
        .fold(0.0, (sum, expense) => sum + expense.amount);

    debugPrint('💰 Monthly total for $month/$year: \$$total');
    return total;
  }

  /// Get expenses for a specific date range
  List<Expense> getExpensesByDateRange(DateTime start, DateTime end) {
    return _expenses
        .where((expense) =>
            expense.date.isAfter(start.subtract(const Duration(days: 1))) &&
            expense.date.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  /// Get expenses by category
  List<Expense> getExpensesByCategory(String categoryId) {
    return _expenses
        .where((expense) => expense.categoryId == categoryId)
        .toList();
  }

  /// Get category totals
  Map<String, double> getCategoryTotals() {
    final Map<String, double> totals = {};
    for (var expense in _expenses) {
      totals[expense.categoryId] =
          (totals[expense.categoryId] ?? 0) + expense.amount;
    }
    return totals;
  }

  /// Get category totals for a specific month
  Map<String, double> getCategoryTotalsByMonth(DateTime date) {
    final month = date.month;
    final year = date.year;
    final Map<String, double> totals = {};

    for (var expense in _expenses) {
      if (expense.date.month == month && expense.date.year == year) {
        totals[expense.categoryId] =
            (totals[expense.categoryId] ?? 0) + expense.amount;
      }
    }
    return totals;
  }

  /// Get daily totals for a month (for charts)
  Map<int, double> getDailyTotalsForMonth(DateTime date) {
    final month = date.month;
    final year = date.year;
    final Map<int, double> dailyTotals = {};

    for (var expense in _expenses) {
      if (expense.date.month == month && expense.date.year == year) {
        final day = expense.date.day;
        dailyTotals[day] = (dailyTotals[day] ?? 0) + expense.amount;
      }
    }
    return dailyTotals;
  }

  /// Get total expenses
  double get totalExpenses {
    final total = _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    debugPrint('💰 Total expenses: \$$total');
    return total;
  }

  double get currentMonthTotal => getTotalByMonth(DateTime.now());

  /// Clear all expenses (use with caution!)
  Future<void> clearAllExpenses() async {
    try {
      debugPrint('⚠️ ExpenseProvider: Clearing all expenses...');

      for (var expense in _expenses) {
        await _supabaseService.deleteExpense(expense.id);
      }

      debugPrint('✅ ExpenseProvider: All expenses cleared');
    } catch (e) {
      debugPrint('❌ ExpenseProvider: Error clearing expenses: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    debugPrint('🔚 ExpenseProvider: Disposing...');
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
