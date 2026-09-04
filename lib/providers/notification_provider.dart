import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService;

  // ══════════════════════════════════════════════════════════════════════════
  // SETTINGS STATE
  // ══════════════════════════════════════════════════════════════════════════

  // Master
  bool _notificationsEnabled = true;

  // Category 1 – Budget & Spending
  bool _budgetAlertsEnabled = true;
  bool _expenseAlertsEnabled = true;
  bool _dailyNudgeEnabled = false;

  // Category 2 – Bills & Debts
  bool _billRemindersEnabled = true;
  bool _debtRemindersEnabled = true;

  // Category 3 – Savings Goals
  bool _goalMilestonesEnabled = true;

  // Category 4 – Reports
  bool _weeklySummaryEnabled = false;
  bool _monthlySummaryEnabled = false;
  bool _yearlyReviewEnabled = false;

  // Category 5 – System & Security
  bool _systemNotificationsEnabled = true;
  bool _loginAlertEnabled = true;

  // Transaction-level (income, bill paid, debt payment, savings deposit)
  bool _incomeAlertsEnabled = true;
  bool _transactionAlertsEnabled = true;

  // Time
  int _summaryHour = 9;
  int _summaryMinute = 0;

  NotificationProvider(this._notificationService) {
    _loadSettings();
    // Defer plugin initialization to keep first frame responsive.
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      unawaited(_notificationService.initialize());
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ══════════════════════════════════════════════════════════════════════════

  bool get notificationsEnabled => _notificationsEnabled;
  bool get budgetAlertsEnabled => _budgetAlertsEnabled;
  bool get expenseAlertsEnabled => _expenseAlertsEnabled;
  bool get dailyNudgeEnabled => _dailyNudgeEnabled;
  bool get billRemindersEnabled => _billRemindersEnabled;
  bool get debtRemindersEnabled => _debtRemindersEnabled;
  bool get goalMilestonesEnabled => _goalMilestonesEnabled;
  bool get weeklySummaryEnabled => _weeklySummaryEnabled;
  bool get monthlySummaryEnabled => _monthlySummaryEnabled;
  bool get yearlyReviewEnabled => _yearlyReviewEnabled;
  bool get systemNotificationsEnabled => _systemNotificationsEnabled;
  bool get loginAlertEnabled => _loginAlertEnabled;
  bool get incomeAlertsEnabled => _incomeAlertsEnabled;
  bool get transactionAlertsEnabled => _transactionAlertsEnabled;
  int get summaryHour => _summaryHour;
  int get summaryMinute => _summaryMinute;
  bool get canSendNotifications => _notificationsEnabled;

  // ══════════════════════════════════════════════════════════════════════════
  // PERSISTENCE
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _budgetAlertsEnabled = prefs.getBool('budget_alerts_enabled') ?? true;
      _expenseAlertsEnabled = prefs.getBool('expense_alerts_enabled') ?? true;
      _dailyNudgeEnabled = prefs.getBool('daily_nudge_enabled') ?? false;
      _billRemindersEnabled = prefs.getBool('bill_reminders_enabled') ?? true;
      _debtRemindersEnabled = prefs.getBool('debt_reminders_enabled') ?? true;
      _goalMilestonesEnabled = prefs.getBool('goal_milestones_enabled') ?? true;
      _weeklySummaryEnabled = prefs.getBool('weekly_summary_enabled') ?? false;
      _monthlySummaryEnabled =
          prefs.getBool('monthly_summary_enabled') ?? false;
      _yearlyReviewEnabled = prefs.getBool('yearly_review_enabled') ?? false;
      _systemNotificationsEnabled =
          prefs.getBool('system_notifications_enabled') ?? true;
      _loginAlertEnabled = prefs.getBool('login_alert_enabled') ?? true;
      _incomeAlertsEnabled = prefs.getBool('income_alerts_enabled') ?? true;
      _transactionAlertsEnabled =
          prefs.getBool('transaction_alerts_enabled') ?? true;
      _summaryHour = prefs.getInt('summary_hour') ?? 9;
      _summaryMinute = prefs.getInt('summary_minute') ?? 0;

      notifyListeners();
      debugPrint('NotificationProvider: Settings loaded');
    } catch (e) {
      debugPrint('NotificationProvider ERROR: Failed to load settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('budget_alerts_enabled', _budgetAlertsEnabled);
      await prefs.setBool('expense_alerts_enabled', _expenseAlertsEnabled);
      await prefs.setBool('daily_nudge_enabled', _dailyNudgeEnabled);
      await prefs.setBool('bill_reminders_enabled', _billRemindersEnabled);
      await prefs.setBool('debt_reminders_enabled', _debtRemindersEnabled);
      await prefs.setBool('goal_milestones_enabled', _goalMilestonesEnabled);
      await prefs.setBool('weekly_summary_enabled', _weeklySummaryEnabled);
      await prefs.setBool('monthly_summary_enabled', _monthlySummaryEnabled);
      await prefs.setBool('yearly_review_enabled', _yearlyReviewEnabled);
      await prefs.setBool(
          'system_notifications_enabled', _systemNotificationsEnabled);
      await prefs.setBool('login_alert_enabled', _loginAlertEnabled);
      await prefs.setBool('income_alerts_enabled', _incomeAlertsEnabled);
      await prefs.setBool(
          'transaction_alerts_enabled', _transactionAlertsEnabled);
      await prefs.setInt('summary_hour', _summaryHour);
      await prefs.setInt('summary_minute', _summaryMinute);
      debugPrint('NotificationProvider: Settings saved');
    } catch (e) {
      debugPrint('NotificationProvider ERROR: Failed to save settings: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TOGGLES
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    await _saveSettings();
    if (!value) {
      await _notificationService.cancelAllNotifications();
      debugPrint('All notifications disabled and cancelled');
    }
  }

  Future<void> toggleBudgetAlerts(bool value) async {
    _budgetAlertsEnabled = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> toggleExpenseAlerts(bool value) async {
    _expenseAlertsEnabled = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> toggleDailyNudge(bool value) async {
    _dailyNudgeEnabled = value;
    notifyListeners();
    await _saveSettings();
    if (value) {
      await _notificationService.scheduleDailySpendingNudge(
          hour: 20, minute: 0);
    } else {
      await _notificationService
          .cancelNotification(NotificationService.idDailyNudge);
    }
  }

  Future<void> toggleBillReminders(bool value) async {
    _billRemindersEnabled = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> toggleDebtReminders(bool value) async {
    _debtRemindersEnabled = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> toggleGoalMilestones(bool value) async {
    _goalMilestonesEnabled = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> toggleIncomeAlerts(bool value) async {
    _incomeAlertsEnabled = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> toggleTransactionAlerts(bool value) async {
    _transactionAlertsEnabled = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> toggleWeeklySummary(bool value) async {
    _weeklySummaryEnabled = value;
    notifyListeners();
    await _saveSettings();
    if (value) {
      await _notificationService.scheduleWeeklySummary();
    } else {
      await _notificationService
          .cancelNotification(NotificationService.idWeeklySummary);
    }
  }

  Future<void> toggleMonthlySummary(bool value) async {
    _monthlySummaryEnabled = value;
    notifyListeners();
    await _saveSettings();
    if (value) {
      await _notificationService.scheduleMonthlySummary();
    } else {
      await _notificationService
          .cancelNotification(NotificationService.idMonthlySummary);
    }
  }

  Future<void> toggleYearlyReview(bool value) async {
    _yearlyReviewEnabled = value;
    notifyListeners();
    await _saveSettings();
    if (value) {
      await _notificationService.scheduleYearlyReview();
    } else {
      await _notificationService
          .cancelNotification(NotificationService.idYearlyReview);
    }
  }

  Future<void> toggleSystemNotifications(bool value) async {
    _systemNotificationsEnabled = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> toggleLoginAlert(bool value) async {
    _loginAlertEnabled = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setSummaryTime(int hour, int minute) async {
    _summaryHour = hour;
    _summaryMinute = minute;
    notifyListeners();
    await _saveSettings();
    if (_weeklySummaryEnabled) {
      await _notificationService.scheduleWeeklySummary(
          hour: hour, minute: minute);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NOTIFICATION TRIGGERS
  // ══════════════════════════════════════════════════════════════════════════

  // --- Expense ---
  Future<void> sendExpenseAdded({
    required double amount,
    required String category,
    required String currency,
    String? note,
  }) async {
    if (!_notificationsEnabled || !_expenseAlertsEnabled) return;
    await _notificationService.showExpenseAdded(
      amount: amount,
      category: category,
      currency: currency,
      note: note,
    );
  }

  Future<void> sendExpenseDeleted({
    required double amount,
    required String currency,
  }) async {
    if (!_notificationsEnabled || !_expenseAlertsEnabled) return;
    await _notificationService.showExpenseDeleted(
      amount: amount,
      currency: currency,
    );
  }

  // --- Budget ---
  Future<void> sendBudgetAlert({
    required String type,
    required double percentage,
    required double spent,
    required double budget,
    required String currency,
  }) async {
    if (!_notificationsEnabled || !_budgetAlertsEnabled) return;
    await _notificationService.showBudgetAlert(
      type: type,
      percentage: percentage,
      spent: spent,
      budget: budget,
      currency: currency,
    );
  }

  Future<void> sendCategoryOverspendAlert({
    required String categoryName,
    required double spent,
    required double categoryBudget,
    required String currency,
  }) async {
    if (!_notificationsEnabled || !_budgetAlertsEnabled) return;
    await _notificationService.showCategoryOverspendAlert(
      categoryName: categoryName,
      spent: spent,
      categoryBudget: categoryBudget,
      currency: currency,
    );
  }

  // --- Bill ---
  Future<void> sendBillReminder({
    required String billId,
    required String billName,
    required double amount,
    required DateTime dueDate,
    required String currency,
    int daysBefore = 1,
  }) async {
    if (!_notificationsEnabled || !_billRemindersEnabled) return;
    await _notificationService.scheduleBillReminder(
      billId: billId,
      billName: billName,
      amount: amount,
      dueDate: dueDate,
      currency: currency,
      daysBefore: daysBefore,
    );
  }

  Future<void> sendBillDueToday({
    required String billName,
    required double amount,
    required String currency,
  }) async {
    if (!_notificationsEnabled || !_billRemindersEnabled) return;
    await _notificationService.showBillDueToday(
      billName: billName,
      amount: amount,
      currency: currency,
    );
  }

  Future<void> sendBillAdded({
    required String billName,
    required double amount,
    required DateTime dueDate,
    required String currency,
  }) async {
    if (!_notificationsEnabled || !_transactionAlertsEnabled) return;
    await _notificationService.showBillAdded(
      billName: billName,
      amount: amount,
      currency: currency,
      dueDate: dueDate,
    );
  }

  Future<void> sendBillPaid({
    required String billName,
    required double amount,
    required String currency,
  }) async {
    if (!_notificationsEnabled || !_transactionAlertsEnabled) return;
    await _notificationService.showBillPaid(
      billName: billName,
      amount: amount,
      currency: currency,
    );
  }

  Future<void> sendOverdueBillNotification({
    required String billName,
    required double amount,
    required int daysOverdue,
    required String currency,
  }) async {
    if (!_notificationsEnabled || !_billRemindersEnabled) return;
    await _notificationService.showOverdueBillNotification(
      billName: billName,
      amount: amount,
      daysOverdue: daysOverdue,
      currency: currency,
    );
  }

  // --- Income ---
  Future<void> sendIncomeAdded({
    required double amount,
    required String source,
    required String currency,
  }) async {
    if (!_notificationsEnabled || !_incomeAlertsEnabled) return;
    await _notificationService.showIncomeAdded(
      amount: amount,
      source: source,
      currency: currency,
    );
  }

  // --- Savings ---
  Future<void> sendGoalMilestone({
    required String goalName,
    required int percentage,
    required double saved,
    required double target,
    required String currency,
  }) async {
    if (!_notificationsEnabled || !_goalMilestonesEnabled) return;
    await _notificationService.showGoalMilestone(
      goalName: goalName,
      percentage: percentage,
      saved: saved,
      target: target,
      currency: currency,
    );
  }

  Future<void> sendGoalBehindSchedule({
    required String goalName,
    required double currentAmount,
    required double expectedAmount,
    required double targetAmount,
    required int daysRemaining,
    required String currency,
  }) async {
    if (!_notificationsEnabled || !_goalMilestonesEnabled) return;
    await _notificationService.showGoalBehindSchedule(
      goalName: goalName,
      currentAmount: currentAmount,
      expectedAmount: expectedAmount,
      targetAmount: targetAmount,
      daysRemaining: daysRemaining,
      currency: currency,
    );
  }

  Future<void> sendSavingsGoalAdded({
    required String goalName,
    required double targetAmount,
    required String currency,
  }) async {
    if (!_notificationsEnabled || !_transactionAlertsEnabled) return;
    await _notificationService.showSavingsGoalAdded(
      goalName: goalName,
      targetAmount: targetAmount,
      currency: currency,
    );
  }

  Future<void> sendSavingsDeposit({
    required String goalName,
    required double amount,
    required double progressPercent,
    required String currency,
  }) async {
    if (!_notificationsEnabled || !_transactionAlertsEnabled) return;
    await _notificationService.showSavingsDeposit(
      goalName: goalName,
      amount: amount,
      progressPercent: progressPercent,
      currency: currency,
    );
  }

  // --- Debt ---
  Future<void> sendDebtReminder({
    required String debtId,
    required String debtName,
    required double remaining,
    required DateTime dueDate,
    required String currency,
  }) async {
    if (!_notificationsEnabled || !_debtRemindersEnabled) return;
    await _notificationService.scheduleDebtReminder(
      debtId: debtId,
      debtName: debtName,
      remaining: remaining,
      dueDate: dueDate,
      currency: currency,
    );
  }

  Future<void> sendDebtAdded({
    required String debtName,
    required double totalAmount,
    required String currency,
  }) async {
    if (!_notificationsEnabled || !_transactionAlertsEnabled) return;
    await _notificationService.showDebtAdded(
      debtName: debtName,
      totalAmount: totalAmount,
      currency: currency,
    );
  }

  Future<void> sendDebtPayment({
    required String debtName,
    required double paymentAmount,
    required double remaining,
    required String currency,
  }) async {
    if (!_notificationsEnabled || !_transactionAlertsEnabled) return;
    await _notificationService.showDebtPayment(
      debtName: debtName,
      paymentAmount: paymentAmount,
      remaining: remaining,
      currency: currency,
    );
  }

  Future<void> sendDebtPaidOff({
    required String debtName,
    required String currency,
  }) async {
    if (!_notificationsEnabled || !_transactionAlertsEnabled) return;
    await _notificationService.showDebtPaidOff(
      debtName: debtName,
      currency: currency,
    );
  }

  Future<void> sendDebtMilestone({
    required String debtName,
    required int percentPaid,
  }) async {
    if (!_notificationsEnabled || !_debtRemindersEnabled) return;
    await _notificationService.showDebtMilestone(
      debtName: debtName,
      percentPaid: percentPaid,
    );
  }

  // --- System & Security ---
  Future<void> sendLoginAlert({
    required String email,
    String? deviceInfo,
  }) async {
    if (!_notificationsEnabled ||
        !_systemNotificationsEnabled ||
        !_loginAlertEnabled) return;
    await _notificationService.showLoginAlert(
      email: email,
      deviceInfo: deviceInfo,
    );
  }

  Future<void> sendCurrencyConversionComplete({
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (!_notificationsEnabled || !_systemNotificationsEnabled) return;
    await _notificationService.showCurrencyConversionComplete(
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
    );
  }

  Future<void> sendDataSyncComplete({int itemsSynced = 0}) async {
    if (!_notificationsEnabled || !_systemNotificationsEnabled) return;
    await _notificationService.showDataSyncComplete(
      itemsSynced: itemsSynced,
    );
  }

  // --- Cancellation helpers ---
  Future<void> cancelBillReminder(String billId) async {
    await _notificationService.cancelNotification(billId.hashCode);
  }

  Future<void> cancelDebtReminder(String debtId) async {
    await _notificationService.cancelNotification(debtId.hashCode);
  }

  Future<int> getPendingNotificationsCount() async {
    final pending = await _notificationService.getPendingNotifications();
    return pending.length;
  }

  @override
  void dispose() {
    debugPrint('NotificationProvider: Disposing...');
    super.dispose();
  }
}
