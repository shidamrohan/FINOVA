import '../main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../models/debt.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_provider.dart';
import 'settings_provider.dart';

class DebtProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  List<Debt> _debts = [];
  List<DebtPayment> _payments = [];
  bool _isLoading = false;
  RealtimeChannel? _debtsChannel;
  RealtimeChannel? _paymentsChannel;

  DebtProvider(this._supabaseService) {
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

  List<Debt> get debts => _debts;
  List<DebtPayment> get payments => _payments;
  bool get isLoading => _isLoading;

  List<Debt> get activeDebts =>
      _debts.where((debt) => debt.status == DebtStatus.active).toList();

  List<Debt> get paidOffDebts =>
      _debts.where((debt) => debt.status == DebtStatus.paidOff).toList();

  double get totalDebtAmount {
    return activeDebts.fold(0.0, (sum, debt) => sum + debt.totalAmount);
  }

  double get totalPaidAmount {
    return activeDebts.fold(0.0, (sum, debt) => sum + debt.paidAmount);
  }

  double get totalRemainingAmount {
    return activeDebts.fold(0.0, (sum, debt) => sum + debt.remainingAmount);
  }

  double get overallProgress {
    if (totalDebtAmount <= 0) return 0;
    final percentage = (totalPaidAmount / totalDebtAmount) * 100;
    return percentage > 100 ? 100 : percentage;
  }

  double get totalInterest {
    return activeDebts.fold(0.0, (sum, debt) => sum + debt.totalInterest);
  }

  List<Debt> getDebtsByType(DebtType type) {
    return _debts.where((debt) => debt.type == type).toList();
  }

  List<DebtPayment> getPaymentsForDebt(String debtId) {
    return _payments.where((payment) => payment.debtId == debtId).toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
  }

  Future<void> _initialize() async {
    if (!SupabaseService.isAuthenticated) {
      _isLoading = false;
      _safeNotify();
      return;
    }

    debugPrint('DebtProvider: Initializing...');
    _isLoading = true;
    _safeNotify();

    await _fetchDebts();
    await _fetchPayments();
    _subscribeToChanges();
  }

  /// Re-fetch data after login (called from main.dart onAuthStateChange)
  Future<void> refreshData() async {
    debugPrint('🔄 DebtProvider: Refreshing data after auth change...');
    await _debtsChannel?.unsubscribe();
    await _paymentsChannel?.unsubscribe();
    _debtsChannel = null;
    _paymentsChannel = null;

    if (!SupabaseService.isAuthenticated) {
      _debts = [];
      _payments = [];
      _isLoading = false;
      _safeNotify();
      return;
    }

    await _initialize();
  }

  Future<void> _fetchDebts() async {
    try {
      if (!SupabaseService.isAuthenticated) {
        _isLoading = false;
        _safeNotify();
        return;
      }

      debugPrint('DebtProvider: Fetching debts...');
      final data = await _supabaseService.getDebts();

      _debts = data.map((json) => Debt.fromJson(json)).toList()
        ..sort((a, b) {
          if (a.status != b.status) {
            return a.status == DebtStatus.active ? -1 : 1;
          }
          return b.createdAt.compareTo(a.createdAt);
        });

      debugPrint('DebtProvider: Loaded ${_debts.length} debts');
      _isLoading = false;
      _safeNotify();
    } catch (e) {
      debugPrint('DebtProvider ERROR: Error loading debts: $e');
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<void> _fetchPayments() async {
    try {
      if (!SupabaseService.isAuthenticated) return;

      debugPrint('DebtProvider: Fetching payments...');
      final data = await _supabaseService.getDebtPayments();

      _payments = data.map((json) => DebtPayment.fromJson(json)).toList()
        ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

      debugPrint('DebtProvider: Loaded ${_payments.length} payments');
      _safeNotify();
    } catch (e) {
      debugPrint('DebtProvider ERROR: Error loading payments: $e');
    }
  }

  void _subscribeToChanges() {
    final userId = _supabaseService.currentUserId;
    if (userId.isEmpty) return;
    debugPrint('👂 DebtProvider: Subscribing to realtime changes...');

    _debtsChannel = Supabase.instance.client
        .channel('debts_changes_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'debts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint(
                '🔄 DebtProvider: Debts realtime event: ${payload.eventType}');
            _fetchDebts();
          },
        )
        .subscribe((status, [error]) {
      debugPrint('📡 DebtProvider: Debts realtime status: $status');
    });

    _paymentsChannel = Supabase.instance.client
        .channel('debt_payments_changes_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'debt_payments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint(
                '🔄 DebtProvider: Payments realtime event: ${payload.eventType}');
            _fetchPayments();
          },
        )
        .subscribe((status, [error]) {
      debugPrint('📡 DebtProvider: Payments realtime status: $status');
    });
  }

  // Add new debt
  Future<void> addDebt(Debt debt) async {
    try {
      debugPrint('DebtProvider: Adding debt...');
      await _supabaseService.addDebt(debt.toJson());

      // Immediately refresh so UI updates without waiting for realtime
      await _fetchDebts();

      try {
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          final notificationProvider = context.read<NotificationProvider>();
          final settingsProvider = context.read<SettingsProvider>();

          if (notificationProvider.transactionAlertsEnabled) {
            await notificationProvider.sendDebtAdded(
              debtName: debt.name,
              totalAmount: debt.totalAmount,
              currency: settingsProvider.currency,
            );
          }

          if (notificationProvider.debtRemindersEnabled &&
              debt.dueDate != null &&
              debt.status == DebtStatus.active) {
            await notificationProvider.sendDebtReminder(
              debtId: debt.id,
              debtName: debt.name,
              remaining: debt.remainingAmount,
              dueDate: debt.dueDate!,
              currency: settingsProvider.currency,
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Error sending debt notification: $e');
      }

      debugPrint('DebtProvider: Debt added and UI refreshed');
    } catch (e) {
      debugPrint('DebtProvider: Error adding debt: $e');
      rethrow;
    }
  }

  Future<void> updateDebt(Debt debt) async {
    try {
      debugPrint('DebtProvider: Updating debt ${debt.id}...');
      await _supabaseService.updateDebt(debt.toJson());

      // Immediately refresh so UI updates without waiting for realtime
      await _fetchDebts();

      debugPrint('DebtProvider: Debt updated and UI refreshed');
    } catch (e) {
      debugPrint('DebtProvider ERROR: Error updating debt: $e');
      rethrow;
    }
  }

  Future<void> deleteDebt(String id) async {
    try {
      debugPrint('DebtProvider: Deleting debt $id...');
      await _supabaseService.deleteDebt(id);

      // Immediately refresh so UI updates without waiting for realtime
      await _fetchDebts();

      debugPrint('DebtProvider: Debt deleted and UI refreshed');
    } catch (e) {
      debugPrint('DebtProvider ERROR: Error deleting debt: $e');
      rethrow;
    }
  }

  Future<void> addPayment(
      String debtId, double amount, String note) async {
    try {
      debugPrint('DebtProvider: Adding payment of $amount to debt $debtId...');

      final debt = _debts.firstWhere((d) => d.id == debtId);

      final payment = DebtPayment(
        id: 'payment_${DateTime.now().millisecondsSinceEpoch}',
        userId: debt.userId,
        debtId: debtId,
        amount: amount,
        paymentDate: DateTime.now(),
        note: note,
        createdAt: DateTime.now(),
      );

      await _supabaseService.addDebtPayment(payment.toJson());

      // Immediately refresh payments so UI updates without waiting for realtime
      await _fetchPayments();

      final newPaidAmount = debt.paidAmount + amount;
      final isPaidOff = newPaidAmount >= debt.totalAmount;
      final updatedDebt = debt.copyWith(
        paidAmount: newPaidAmount,
        status: isPaidOff ? DebtStatus.paidOff : DebtStatus.active,
        updatedAt: DateTime.now(),
      );

      await updateDebt(updatedDebt);

      // Send notification
      try {
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          final notificationProvider = context.read<NotificationProvider>();
          final settingsProvider = context.read<SettingsProvider>();
          if (isPaidOff) {
            await notificationProvider.sendDebtPaidOff(
              debtName: debt.name,
              currency: settingsProvider.currency,
            );
            // Also send 100% milestone
            await notificationProvider.sendDebtMilestone(
              debtName: debt.name,
              percentPaid: 100,
            );
          } else {
            await notificationProvider.sendDebtPayment(
              debtName: debt.name,
              paymentAmount: amount,
              remaining: updatedDebt.remainingAmount,
              currency: settingsProvider.currency,
            );

            // Check 50% milestone
            final previousPercent =
                (debt.paidAmount / debt.totalAmount * 100).round();
            final newPercent = (newPaidAmount / debt.totalAmount * 100).round();
            if (previousPercent < 50 && newPercent >= 50) {
              await notificationProvider.sendDebtMilestone(
                debtName: debt.name,
                percentPaid: 50,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('❌ DebtProvider: Error sending payment notification: $e');
      }

      debugPrint('DebtProvider: Payment added successfully');
    } catch (e) {
      debugPrint('DebtProvider ERROR: Error adding payment: $e');
      rethrow;
    }
  }

  Future<void> markAsPaidOff(String debtId) async {
    try {
      debugPrint('DebtProvider: Marking debt $debtId as paid off...');

      final debt = _debts.firstWhere((d) => d.id == debtId);
      final updatedDebt = debt.copyWith(
        paidAmount: debt.totalAmount,
        status: DebtStatus.paidOff,
        updatedAt: DateTime.now(),
      );

      await updateDebt(updatedDebt);

      // Send paid off notification
      try {
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          final notificationProvider = context.read<NotificationProvider>();
          final settingsProvider = context.read<SettingsProvider>();
          await notificationProvider.sendDebtPaidOff(
            debtName: debt.name,
            currency: settingsProvider.currency,
          );
          await notificationProvider.cancelDebtReminder(debtId);
        }
      } catch (e) {
        debugPrint('❌ DebtProvider: Error sending paid off notification: $e');
      }

      debugPrint('DebtProvider: Debt marked as paid off successfully');
    } catch (e) {
      debugPrint('DebtProvider ERROR: Error marking debt as paid off: $e');
      rethrow;
    }
  }

  Future<void> reactivateDebt(String debtId) async {
    try {
      debugPrint('DebtProvider: Reactivating debt $debtId...');

      final debt = _debts.firstWhere((d) => d.id == debtId);
      final updatedDebt = debt.copyWith(
        status: DebtStatus.active,
        updatedAt: DateTime.now(),
      );

      await updateDebt(updatedDebt);
      debugPrint('DebtProvider: Debt reactivated successfully');
    } catch (e) {
      debugPrint('DebtProvider ERROR: Error reactivating debt: $e');
      rethrow;
    }
  }

  Future<void> scheduleDebtReminders() async {
    try {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        final notificationProvider = context.read<NotificationProvider>();
        final settingsProvider = context.read<SettingsProvider>();

        if (!notificationProvider.notificationsEnabled ||
            !notificationProvider.debtRemindersEnabled) {
          return;
        }

        for (final debt in activeDebts) {
          if (debt.dueDate != null && debt.dueDate!.isAfter(DateTime.now())) {
            await notificationProvider.sendDebtReminder(
              debtId: debt.id,
              debtName: debt.name,
              remaining: debt.remainingAmount,
              dueDate: debt.dueDate!,
              currency: settingsProvider.currency,
            );
          }
        }
      }

      debugPrint('DebtProvider: Debt reminders scheduled');
    } catch (e) {
      debugPrint('DebtProvider: Error scheduling reminders: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('DebtProvider: Disposing...');
    _debtsChannel?.unsubscribe();
    _paymentsChannel?.unsubscribe();
    super.dispose();
  }
}
