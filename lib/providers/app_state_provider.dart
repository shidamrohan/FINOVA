import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'expense_provider.dart';
import 'income_provider.dart';
import 'bill_provider.dart';
import 'budget_provider.dart';
import 'savings_goal_provider.dart';
import 'debt_provider.dart';

/// Global app-level state that is shared across the entire widget tree.
///
/// Responsibilities:
///  • Internet connectivity monitoring
///  • Global refresh of all data providers after login / pull-to-refresh
///  • Active bottom-nav tab index
///  • App-wide banner / snackbar messages
class AppStateProvider with ChangeNotifier {
  // ── Providers that need to be refreshed together ──────────────────────────
  final ExpenseProvider _expenseProvider;
  final IncomeProvider _incomeProvider;
  final BillProvider _billProvider;
  final BudgetProvider _budgetProvider;
  final SavingsGoalProvider _savingsGoalProvider;
  final DebtProvider _debtProvider;

  AppStateProvider({
    required ExpenseProvider expenseProvider,
    required IncomeProvider incomeProvider,
    required BillProvider billProvider,
    required BudgetProvider budgetProvider,
    required SavingsGoalProvider savingsGoalProvider,
    required DebtProvider debtProvider,
  })  : _expenseProvider = expenseProvider,
        _incomeProvider = incomeProvider,
        _billProvider = billProvider,
        _budgetProvider = budgetProvider,
        _savingsGoalProvider = savingsGoalProvider,
        _debtProvider = debtProvider {
    _startConnectivityMonitor();
  }

  // ── Connectivity ───────────────────────────────────────────────────────────
  bool _isOnline = true;
  Timer? _connectivityTimer;

  bool get isOnline => _isOnline;

  void _startConnectivityMonitor() {
    // Poll every 10 seconds — lightweight and works on all platforms.
    _connectivityTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _checkConnectivity());
    _checkConnectivity(); // immediate first check
  }

  Future<void> _checkConnectivity() async {
    try {
      // Use the Supabase host from env var for the most accurate check
      const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
      final supabaseHost = supabaseUrl.isNotEmpty
          ? Uri.parse(supabaseUrl).host
          : 'google.com';
      final results = await Future.any([
        InternetAddress.lookup(supabaseHost),
        InternetAddress.lookup('8.8.8.8'),
      ]).timeout(const Duration(seconds: 5));
      final online = results.isNotEmpty && results.first.rawAddress.isNotEmpty;
      if (online != _isOnline) {
        _isOnline = online;
        debugPrint(_isOnline ? '🌐 Network: online' : '📵 Network: offline');
        notifyListeners();
      }
    } catch (_) {
      if (_isOnline) {
        _isOnline = false;
        debugPrint('📵 Network: offline');
        notifyListeners();
      }
    }
  }

  // ── Global loading / refreshing ────────────────────────────────────────────
  bool _isRefreshing = false;
  DateTime? _lastRefreshed;

  bool get isRefreshing => _isRefreshing;
  DateTime? get lastRefreshed => _lastRefreshed;

  /// Refreshes all data providers simultaneously.
  /// Call this after login or when the user pulls-to-refresh.
  Future<void> refreshAll({Duration? delay}) async {
    if (_isRefreshing) return; // prevent double-refresh
    _isRefreshing = true;
    notifyListeners();

    if (delay != null) await Future.delayed(delay);

    try {
      debugPrint('🔄 AppStateProvider: refreshing all providers…');
      await Future.wait([
        _expenseProvider.refreshData(),
        _incomeProvider.refreshData(),
        _billProvider.refreshData(),
        _budgetProvider.refreshData(),
        _savingsGoalProvider.refreshData(),
        _debtProvider.refreshData(),
      ]);
      _lastRefreshed = DateTime.now();
      debugPrint('✅ AppStateProvider: all providers refreshed');
    } catch (e) {
      debugPrint('❌ AppStateProvider: refresh failed: $e');
    }

    _isRefreshing = false;
    notifyListeners();
  }

  // ── Active tab index ───────────────────────────────────────────────────────
  int _activeTabIndex = 0;

  int get activeTabIndex => _activeTabIndex;

  void setActiveTab(int index) {
    if (index != _activeTabIndex) {
      _activeTabIndex = index;
      notifyListeners();
    }
  }

  // ── App-wide banner message ────────────────────────────────────────────────
  String? _bannerMessage;
  bool _bannerIsError = false;
  Timer? _bannerTimer;

  String? get bannerMessage => _bannerMessage;
  bool get bannerIsError => _bannerIsError;

  /// Show a temporary banner message (auto-dismisses after [duration]).
  void showBanner(String message,
      {bool isError = false,
      Duration duration = const Duration(seconds: 3)}) {
    _bannerTimer?.cancel();
    _bannerMessage = message;
    _bannerIsError = isError;
    notifyListeners();

    _bannerTimer = Timer(duration, () {
      _bannerMessage = null;
      notifyListeners();
    });
  }

  void dismissBanner() {
    _bannerTimer?.cancel();
    _bannerMessage = null;
    notifyListeners();
  }

  // ── Dispose ────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _bannerTimer?.cancel();
    super.dispose();
  }
}

