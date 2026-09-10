import 'package:flutter/material.dart';
import '../main.dart';
import 'package:flutter/scheduler.dart';
import '../models/income.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_provider.dart';
import 'settings_provider.dart';
import 'package:provider/provider.dart';

class IncomeProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  List<Income> _incomes = [];
  bool _isLoading = false;
  RealtimeChannel? _realtimeChannel;

  IncomeProvider(this._supabaseService) {
    if (SupabaseService.isAuthenticated) {
      _initialize();
    }
  }

  /// Schedule notifyListeners safely (avoids calling during build)
  void _safeNotify() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }

  List<Income> get incomes => _incomes;
  bool get isLoading => _isLoading;

  // Get total income for current month
  double get currentMonthIncome {
    final now = DateTime.now();
    return _incomes
        .where((income) =>
            income.date.year == now.year && income.date.month == now.month)
        .fold(0.0, (sum, income) => sum + income.amount);
  }

  // Get income for specific month/year
  double getIncomeForMonth(int month, int year) {
    return _incomes
        .where(
            (income) => income.date.year == year && income.date.month == month)
        .fold(0.0, (sum, income) => sum + income.amount);
  }

  // Get income by source
  double getIncomeBySource(String source,
      {DateTime? startDate, DateTime? endDate}) {
    var filtered = _incomes.where((income) => income.source == source);

    if (startDate != null) {
      filtered = filtered.where((income) =>
          income.date.isAfter(startDate.subtract(const Duration(days: 1))));
    }

    if (endDate != null) {
      filtered = filtered.where((income) =>
          income.date.isBefore(endDate.add(const Duration(days: 1))));
    }

    return filtered.fold(0.0, (sum, income) => sum + income.amount);
  }

  // Get incomes for date range
  List<Income> getIncomesForDateRange(DateTime startDate, DateTime endDate) {
    return _incomes
        .where((income) =>
            income.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            income.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Get yearly income
  double getYearlyIncome(int year) {
    return _incomes
        .where((income) => income.date.year == year)
        .fold(0.0, (sum, income) => sum + income.amount);
  }

  // Initialize and listen to changes
  Future<void> _initialize() async {
    if (!SupabaseService.isAuthenticated) {
      _isLoading = false;
      _safeNotify();
      return;
    }

    debugPrint('📊 IncomeProvider: Initializing...');
    await _fetchIncomes();
    _subscribeToChanges();
  }

  /// Re-fetch data after login (called from main.dart onAuthStateChange)
  Future<void> refreshData() async {
    debugPrint('🔄 IncomeProvider: Refreshing data after auth change...');
    await _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;

    if (!SupabaseService.isAuthenticated) {
      _incomes = [];
      _isLoading = false;
      _safeNotify();
      return;
    }

    await _initialize();
  }

  // Fetch all incomes from Supabase
  Future<void> _fetchIncomes() async {
    try {
      _isLoading = true;
      _safeNotify();

      if (!SupabaseService.isAuthenticated) {
        _isLoading = false;
        _safeNotify();
        return;
      }

      debugPrint('📊 IncomeProvider: Fetching incomes...');
      final data = await _supabaseService.getIncomes();

      _incomes = data.map((json) => Income.fromJson(json)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      debugPrint('✅ IncomeProvider: Loaded ${_incomes.length} incomes');
      _isLoading = false;
      _safeNotify();
    } catch (e) {
      debugPrint('❌ IncomeProvider: Error loading incomes: $e');
      _isLoading = false;
      _safeNotify();
    }
  }

  // Subscribe to realtime changes
  void _subscribeToChanges() {
    final userId = _supabaseService.currentUserId;
    if (userId.isEmpty) return;
    debugPrint('👂 IncomeProvider: Subscribing to realtime changes...');

    _realtimeChannel = Supabase.instance.client
        .channel('income_changes_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'income',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint(
                '🔄 IncomeProvider: Realtime event: ${payload.eventType}');
            _fetchIncomes();
          },
        )
        .subscribe((status, [error]) {
      debugPrint('📡 IncomeProvider: Realtime status: $status');
      if (error != null) {
        debugPrint('❌ IncomeProvider: Realtime error: $error');
      }
    });
  }

  // Add new income
  Future<void> addIncome(Income income) async {
    try {
      debugPrint('📝 IncomeProvider: Adding income...');
      await _supabaseService.addIncome(income.toJson());

      // Immediately refresh so UI updates without waiting for realtime
      await _fetchIncomes();

      debugPrint('✅ IncomeProvider: Income added and UI refreshed');

      // Send instant notification
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        try {
          final notificationProvider = context.read<NotificationProvider>();
          final settingsProvider = context.read<SettingsProvider>();
          await notificationProvider.sendIncomeAdded(
            amount: income.amount,
            source: income.source,
            currency: settingsProvider.currency,
          );
        } catch (e) {
          debugPrint('❌ IncomeProvider: Error sending income notification: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ IncomeProvider: Error adding income: $e');
      rethrow;
    }
  }

  // Update income
  Future<void> updateIncome(Income income) async {
    try {
      debugPrint('📝 IncomeProvider: Updating income ${income.id}...');
      await _supabaseService.updateIncome(income.toJson());

      // Immediately refresh so UI updates without waiting for realtime
      await _fetchIncomes();

      debugPrint('✅ IncomeProvider: Income updated and UI refreshed');
    } catch (e) {
      debugPrint('❌ IncomeProvider: Error updating income: $e');
      rethrow;
    }
  }

  // Delete income
  Future<void> deleteIncome(String id) async {
    try {
      debugPrint('🗑️ IncomeProvider: Deleting income $id...');
      await _supabaseService.deleteIncome(id);

      // Immediately refresh so UI updates without waiting for realtime
      await _fetchIncomes();

      debugPrint('✅ IncomeProvider: Income deleted and UI refreshed');
    } catch (e) {
      debugPrint('❌ IncomeProvider: Error deleting income: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    debugPrint('👋 IncomeProvider: Disposing...');
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
