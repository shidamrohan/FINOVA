import '../models/budget.dart';
import '../services/supabase_service.dart';
import '../main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_provider.dart';
import 'settings_provider.dart';

class BudgetProvider with ChangeNotifier {
  final SupabaseService _supabaseService;

  // Track which alerts have been sent to avoid duplicates
  final Set<String> _sentAlerts = {};

  // Monthly Budgets
  MonthlyBudget? _currentBudget;
  List<MonthlyBudget> _budgets = [];

  // Multi Budgets
  List<MultiBudget> _multiBudgets = [];

  // Realtime channels
  RealtimeChannel? _budgetsChannel;
  RealtimeChannel? _multiBudgetsChannel;

  bool _isLoading = false;
  String? _error;

  // Getters
  MonthlyBudget? get currentBudget => _currentBudget;
  List<MonthlyBudget> get budgets => List.unmodifiable(_budgets);
  List<MultiBudget> get multiBudgets => List.unmodifiable(_multiBudgets);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get active multi-budgets
  List<MultiBudget> get activeMultiBudgets {
    return _multiBudgets.where((mb) => mb.isCurrentlyActive).toList();
  }

  /// Get upcoming multi-budgets
  List<MultiBudget> get upcomingMultiBudgets {
    return _multiBudgets.where((mb) => mb.isUpcoming).toList();
  }

  /// Get expired multi-budgets
  List<MultiBudget> get expiredMultiBudgets {
    return _multiBudgets.where((mb) => mb.isExpired).toList();
  }

  BudgetProvider(SupabaseService supabaseService)
      : _supabaseService = supabaseService {
    if (SupabaseService.isAuthenticated) {
      _initializeBudgets();
    }
  }

  /// Schedule notifyListeners safely (avoids calling during build)
  void _safeNotify() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }

  /// Initialize budgets
  Future<void> _initializeBudgets() async {
    if (!SupabaseService.isAuthenticated) {
      _isLoading = false;
      _safeNotify();
      return;
    }

    _isLoading = true;
    _safeNotify();

    await _fetchAllBudgets();
    await _fetchMultiBudgets();
    _subscribeToChanges();
  }

  /// Re-fetch data after login (called from main.dart onAuthStateChange)
  Future<void> refreshData() async {
    debugPrint('🔄 BudgetProvider: Refreshing data after auth change...');
    _sentAlerts.clear();
    await _budgetsChannel?.unsubscribe();
    await _multiBudgetsChannel?.unsubscribe();
    _budgetsChannel = null;
    _multiBudgetsChannel = null;

    if (!SupabaseService.isAuthenticated) {
      _currentBudget = null;
      _budgets = [];
      _multiBudgets = [];
      _isLoading = false;
      _safeNotify();
      return;
    }

    await _initializeBudgets();
  }

  /// Fetch all budgets from Supabase
  Future<void> _fetchAllBudgets() async {
    try {
      if (!SupabaseService.isAuthenticated) return;

      final userId = _supabaseService.currentUserId;
      final now = DateTime.now();

      final data = await Supabase.instance.client
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .order('year', ascending: false);

      _budgets = (data as List)
          .map((json) => MonthlyBudget.fromJson(json as Map<String, dynamic>))
          .toList();

      // Set current month budget
      try {
        _currentBudget = _budgets.firstWhere(
          (b) => b.month == now.month && b.year == now.year,
        );
      } catch (_) {
        _currentBudget = null;
      }

      debugPrint('✅ BudgetProvider: Loaded ${_budgets.length} budgets');
      _isLoading = false;
      _error = null;
      _safeNotify();
    } catch (e) {
      debugPrint('❌ BudgetProvider: Error fetching budgets: $e');
      _error = e.toString();
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Fetch all multi-budgets from Supabase
  Future<void> _fetchMultiBudgets() async {
    try {
      if (!SupabaseService.isAuthenticated) return;

      final userId = _supabaseService.currentUserId;

      final data = await Supabase.instance.client
          .from('multi_budgets')
          .select()
          .eq('user_id', userId)
          .order('start_date', ascending: false);

      _multiBudgets = (data as List)
          .map((json) => MultiBudget.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint(
          '✅ BudgetProvider: Loaded ${_multiBudgets.length} multi-budgets');
      _safeNotify();
    } catch (e) {
      debugPrint('❌ BudgetProvider: Error fetching multi-budgets: $e');
    }
  }

  /// Subscribe to Realtime changes for both budgets and multi_budgets
  void _subscribeToChanges() {
    final userId = _supabaseService.currentUserId;
    if (userId.isEmpty) return;
    debugPrint('👂 BudgetProvider: Subscribing to realtime changes...');

    _budgetsChannel = Supabase.instance.client
        .channel('budgets_changes_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'budgets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint(
                '🔄 BudgetProvider: Budgets realtime event: ${payload.eventType}');
            _fetchAllBudgets();
          },
        )
        .subscribe((status, [error]) {
      debugPrint('📡 BudgetProvider: Budgets realtime status: $status');
    });

    _multiBudgetsChannel = Supabase.instance.client
        .channel('multi_budgets_changes_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'multi_budgets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint(
                '🔄 BudgetProvider: Multi-budgets realtime event: ${payload.eventType}');
            _fetchMultiBudgets();
          },
        )
        .subscribe((status, [error]) {
      debugPrint('📡 BudgetProvider: Multi-budgets realtime status: $status');
    });
  }

  /// Load budget for a specific month (updates _currentBudget)
  void loadBudgetForMonth(int month, int year) {
    try {
      _currentBudget = _budgets.firstWhere(
        (b) => b.month == month && b.year == year,
      );
    } catch (_) {
      _currentBudget = null;
    }
    notifyListeners();
  }

  /// Get budget for specific date
  MonthlyBudget? getBudgetForDate(DateTime date) {
    if (_currentBudget != null &&
        _currentBudget!.month == date.month &&
        _currentBudget!.year == date.year) {
      return _currentBudget;
    }

    try {
      return _budgets.firstWhere(
        (b) => b.month == date.month && b.year == date.year,
      );
    } catch (e) {
      return null;
    }
  }

  MonthlyBudget getCurrentBudget() {
    if (_currentBudget != null) {
      return _currentBudget!;
    }

    final now = DateTime.now();
    return MonthlyBudget(
      id: 'budget_${now.month}_${now.year}',
      month: now.month,
      year: now.year,
      baseAmount: 0.0,
      adjustments: [],
    );
  }

  /// Get budget for a specific month
  MonthlyBudget getBudgetForMonth(int month, int year) {
    if (_currentBudget != null &&
        _currentBudget!.month == month &&
        _currentBudget!.year == year) {
      return _currentBudget!;
    }

    try {
      return _budgets.firstWhere(
        (b) => b.month == month && b.year == year,
      );
    } catch (e) {
      return MonthlyBudget(
        id: 'budget_${month}_$year',
        month: month,
        year: year,
        baseAmount: 0.0,
        adjustments: [],
      );
    }
  }

  /// Save or update budget
  Future<void> saveBudget(MonthlyBudget budget) async {
    try {
      await _supabaseService.saveBudget(budget);

      // Immediately refresh so UI updates without waiting for realtime
      await _fetchAllBudgets();

      debugPrint('✅ Budget saved and UI refreshed');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('❌ Error saving budget: $e');
      rethrow;
    }
  }

  /// Set monthly budget (create or update base amount)
  Future<void> setMonthlyBudget({
    required int month,
    required int year,
    required double amount,
  }) async {
    try {
      MonthlyBudget budget;

      if (_currentBudget != null &&
          _currentBudget!.month == month &&
          _currentBudget!.year == year) {
        budget = _currentBudget!.copyWith(baseAmount: amount);
      } else {
        budget = MonthlyBudget(
          id: 'budget_${month}_$year',
          month: month,
          year: year,
          baseAmount: amount,
          adjustments: [],
        );
      }

      await saveBudget(budget);
      debugPrint('✅ Monthly budget set to $amount');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('❌ Error setting monthly budget: $e');
      rethrow;
    }
  }

  /// Add budget adjustment
  Future<void> addBudgetAdjustment({
    required int month,
    required int year,
    required double amount,
    required String note,
    required BudgetAdjustmentType type,
  }) async {
    try {
      MonthlyBudget budget;

      if (_currentBudget != null &&
          _currentBudget!.month == month &&
          _currentBudget!.year == year) {
        budget = _currentBudget!;
      } else {
        budget = MonthlyBudget(
          id: 'budget_${month}_$year',
          month: month,
          year: year,
          baseAmount: 0,
          adjustments: [],
        );
      }

      final adjustment = BudgetAdjustment(
        id: 'adj_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        amount: amount,
        note: note,
        date: DateTime.now(),
      );

      final updatedAdjustments = List<BudgetAdjustment>.from(budget.adjustments)
        ..add(adjustment);

      final updatedBudget = budget.copyWith(
        adjustments: updatedAdjustments,
      );

      await saveBudget(updatedBudget);
      debugPrint('✅ Budget adjustment added');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('❌ Error adding adjustment: $e');
      rethrow;
    }
  }

  /// Remove/delete budget adjustment
  Future<void> deleteAdjustment(String adjustmentId, int year) async {
    try {
      if (_currentBudget != null) {
        final updatedAdjustments = _currentBudget!.adjustments
            .where((adj) => adj.id != adjustmentId)
            .toList();

        final updatedBudget = _currentBudget!.copyWith(
          adjustments: updatedAdjustments,
        );

        await saveBudget(updatedBudget);
        debugPrint('✅ Budget adjustment deleted');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('❌ Error deleting adjustment: $e');
      rethrow;
    }
  }

  /// Remove budget adjustment (alias for deleteAdjustment)
  Future<void> removeBudgetAdjustment(String adjustmentId) async {
    if (_currentBudget != null) {
      return deleteAdjustment(adjustmentId, _currentBudget!.year);
    }
  }

  // ==================== MULTI-BUDGET METHODS ====================

  /// Create multi-budget
  Future<void> createMultiBudget({
    required String name,
    required double monthlyAmount,
    required DateTime startDate,
    required int durationMonths,
    String categoryId = 'all',
  }) async {
    try {
      final multiBudget = MultiBudget(
        id: 'mb_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        monthlyAmount: monthlyAmount,
        startDate: startDate,
        durationMonths: durationMonths,
        categoryId: categoryId,
        isActive: true,
      );

      await _supabaseService.saveMultiBudget(multiBudget);

      // Immediately refresh so UI updates without waiting for realtime
      await _fetchMultiBudgets();

      debugPrint('✅ Multi-budget created and UI refreshed');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('❌ Error creating multi-budget: $e');
      rethrow;
    }
  }

  /// Update multi-budget
  Future<void> updateMultiBudget(MultiBudget multiBudget) async {
    try {
      await _supabaseService.saveMultiBudget(multiBudget);

      // Immediately refresh so UI updates without waiting for realtime
      await _fetchMultiBudgets();

      debugPrint('✅ Multi-budget updated and UI refreshed');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('❌ Error updating multi-budget: $e');
      rethrow;
    }
  }

  /// Delete multi-budget
  Future<void> deleteMultiBudget(String multiBudgetId) async {
    try {
      await _supabaseService.deleteMultiBudget(multiBudgetId);

      // Immediately refresh so UI updates without waiting for realtime
      await _fetchMultiBudgets();

      debugPrint('✅ Multi-budget deleted and UI refreshed');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('❌ Error deleting multi-budget: $e');
      rethrow;
    }
  }

  /// Toggle multi-budget active status
  Future<void> toggleMultiBudgetActive(String multiBudgetId) async {
    try {
      final multiBudget =
          _multiBudgets.firstWhere((mb) => mb.id == multiBudgetId);
      final updated = multiBudget.copyWith(isActive: !multiBudget.isActive);
      await updateMultiBudget(updated);
      debugPrint('✅ Multi-budget toggled');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('❌ Error toggling multi-budget: $e');
      rethrow;
    }
  }

  /// Get total active multi-budget amount for current month
  double get activeMultiBudgetTotal {
    return activeMultiBudgets.fold(
      0.0,
      (sum, mb) => sum + mb.monthlyAmount,
    );
  }

  get expenses => null;

  /// Get expenses for a specific multi-budget
  List<dynamic> getExpensesForMultiBudget(
    MultiBudget multiBudget,
    List<dynamic> allExpenses,
  ) {
    if (multiBudget.categoryId == 'all') {
      return allExpenses.where((expense) {
        try {
          final expenseDate = _getExpenseDate(expense);
          return expenseDate.isAfter(
                  multiBudget.startDate.subtract(const Duration(days: 1))) &&
              expenseDate
                  .isBefore(multiBudget.endDate.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();
    } else {
      return allExpenses.where((expense) {
        try {
          final categoryId = _getExpenseCategoryId(expense);
          final expenseDate = _getExpenseDate(expense);
          return categoryId == multiBudget.categoryId &&
              expenseDate.isAfter(
                  multiBudget.startDate.subtract(const Duration(days: 1))) &&
              expenseDate
                  .isBefore(multiBudget.endDate.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();
    }
  }

  DateTime _getExpenseDate(dynamic expense) {
    if (expense is Map<String, dynamic>) {
      return DateTime.parse(expense['date'] as String);
    }
    return (expense as dynamic).date as DateTime;
  }

  String _getExpenseCategoryId(dynamic expense) {
    if (expense is Map<String, dynamic>) {
      return expense['category_id'] as String? ??
          expense['categoryId'] as String? ??
          '';
    }
    return (expense as dynamic).categoryId as String? ?? '';
  }

  // ==================== CONVENIENCE METHODS ====================

  /// Add money to budget (income adjustment)
  Future<void> addMoneyToBudget({
    required int month,
    required int year,
    required double amount,
    required String note,
  }) async {
    try {
      await addBudgetAdjustment(
        month: month,
        year: year,
        amount: amount,
        note: note,
        type: BudgetAdjustmentType.income,
      );
      debugPrint('✅ Money added to budget: $amount');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('❌ Error adding money to budget: $e');
      rethrow;
    }
  }

  /// Remove money from budget (expense adjustment)
  Future<void> removeMoneyFromBudget({
    required int month,
    required int year,
    required double amount,
    required String note,
  }) async {
    try {
      await addBudgetAdjustment(
        month: month,
        year: year,
        amount: amount,
        note: note,
        type: BudgetAdjustmentType.expense,
      );
      debugPrint('✅ Money removed from budget: $amount');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('❌ Error removing money from budget: $e');
      rethrow;
    }
  }

  // Helper method to trigger alert with spent amount
  Future<void> triggerBudgetAlertIfNeeded(
    double spent,
  ) async {
    try {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        final notificationProvider = context.read<NotificationProvider>();
        final settingsProvider = context.read<SettingsProvider>();

        if (!notificationProvider.notificationsEnabled ||
            !notificationProvider.budgetAlertsEnabled) {
          return;
        }

      final currentBudget = getCurrentBudget();
      final budget = currentBudget.totalAmount;

      if (budget == 0) return;

      final percentage = (spent / budget) * 100;
      final now = DateTime.now();
      final alertKey = '${now.year}-${now.month}';

      if (percentage >= 80 && percentage < 100) {
        final key80 = '$alertKey-80';
        if (!_sentAlerts.contains(key80)) {
          _sentAlerts.add(key80);
          debugPrint('🚨 Sending 80% budget alert');
          await notificationProvider.sendBudgetAlert(
            type: 'warning',
            percentage: percentage,
            spent: spent,
            budget: budget,
            currency: settingsProvider.currency,
          );
        }
      }

      if (percentage >= 100) {
        final key100 = '$alertKey-100';
        if (!_sentAlerts.contains(key100)) {
          _sentAlerts.add(key100);
          debugPrint('🚨 Sending 100% budget alert');
          await notificationProvider.sendBudgetAlert(
            type: 'exceeded',
            percentage: percentage,
            spent: spent,
            budget: budget,
            currency: settingsProvider.currency,
          );
        }
      }
      }
    } catch (e) {
      debugPrint('BudgetProvider: Error triggering budget alert: $e');
    }
  }

  /// Check multi-budget category overspend alerts
  Future<void> checkCategoryOverspend(
    Map<String, double> categoryTotals,
  ) async {
    try {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        final notificationProvider = context.read<NotificationProvider>();
        final settingsProvider = context.read<SettingsProvider>();

        if (!notificationProvider.notificationsEnabled ||
            !notificationProvider.budgetAlertsEnabled) {
          return;
        }

      for (final mb in activeMultiBudgets) {
        if (mb.categoryId == 'all') continue;

        final spent = categoryTotals[mb.categoryId] ?? 0.0;
        final budgetAmount = mb.monthlyAmount;
        if (budgetAmount <= 0) continue;

        final pct = (spent / budgetAmount) * 100;
        final alertKey = 'cat-${mb.id}-${DateTime.now().month}';

        if (pct >= 100 && !_sentAlerts.contains(alertKey)) {
          _sentAlerts.add(alertKey);
          await notificationProvider.sendCategoryOverspendAlert(
            categoryName: mb.name,
            spent: spent,
            categoryBudget: budgetAmount,
            currency: settingsProvider.currency,
          );
        }
      }
      }
    } catch (e) {
      debugPrint('BudgetProvider: Error checking category overspend: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('🔚 BudgetProvider: Disposing...');
    _budgetsChannel?.unsubscribe();
    _multiBudgetsChannel?.unsubscribe();
    super.dispose();
  }
}
