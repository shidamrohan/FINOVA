import '../main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../models/bill.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_provider.dart';
import 'settings_provider.dart';

class BillProvider with ChangeNotifier {
  final SupabaseService _supabaseService;

  List<Bill> _bills = [];
  RealtimeChannel? _realtimeChannel;
  bool _isLoading = false;
  String? _error;

  List<Bill> get bills => _bills;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BillProvider(SupabaseService supabaseService)
      : _supabaseService = supabaseService {
    debugPrint('🚀 BillProvider: Initializing...');
    if (SupabaseService.isAuthenticated) {
      _initializeBills();
    }
  }

  /// Schedule notifyListeners safely (avoids calling during build)
  void _safeNotify() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }

  Future<void> _initializeBills() async {
    if (!SupabaseService.isAuthenticated) {
      _isLoading = false;
      _safeNotify();
      return;
    }

    debugPrint('📡 BillProvider: Setting up bills...');
    _isLoading = true;
    _safeNotify();

    await _fetchBills();
    _subscribeToChanges();
  }

  /// Re-fetch data after login (called from main.dart onAuthStateChange)
  Future<void> refreshData() async {
    debugPrint('🔄 BillProvider: Refreshing data after auth change...');
    await _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;

    if (!SupabaseService.isAuthenticated) {
      _bills = [];
      _isLoading = false;
      _safeNotify();
      return;
    }

    await _initializeBills();
  }

  Future<void> _fetchBills() async {
    try {
      if (!SupabaseService.isAuthenticated) {
        _isLoading = false;
        _safeNotify();
        return;
      }

      final userId = _supabaseService.currentUserId;
      debugPrint('📥 BillProvider: Fetching bills for user: $userId');

      final data = await Supabase.instance.client
          .from('bills')
          .select()
          .eq('user_id', userId)
          .order('due_date', ascending: true);

      _bills = (data as List)
          .map((json) => Bill.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ BillProvider: Loaded ${_bills.length} bills');
      _isLoading = false;
      _error = null;
      _safeNotify();
    } catch (e) {
      debugPrint('❌ BillProvider: Error fetching bills: $e');
      _error = e.toString();
      _isLoading = false;
      _safeNotify();
    }
  }

  void _subscribeToChanges() {
    final userId = _supabaseService.currentUserId;
    if (userId.isEmpty) return;
    debugPrint('👂 BillProvider: Subscribing to realtime changes...');

    _realtimeChannel = Supabase.instance.client
        .channel('bills_changes_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bills',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('🔄 BillProvider: Realtime event: ${payload.eventType}');
            _fetchBills();
          },
        )
        .subscribe((status, [error]) {
      debugPrint('📡 BillProvider: Realtime status: $status');
      if (error != null) {
        debugPrint('❌ BillProvider: Realtime error: $error');
      }
    });
  }

  // Add bill
  Future<void> addBill(Bill bill) async {
    try {
      debugPrint('BillProvider: Adding bill...');
      await _supabaseService.addBill(bill);

      // Immediately refresh so UI updates without waiting for realtime
      await _fetchBills();

      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        final notificationProvider = context.read<NotificationProvider>();
        final settingsProvider = context.read<SettingsProvider>();

        // Instant notification: bill added
        if (notificationProvider.transactionAlertsEnabled) {
          await notificationProvider.sendBillAdded(
            billName: bill.name,
            amount: bill.amount,
            dueDate: bill.dueDate,
            currency: settingsProvider.currency,
          );
        }

        // Schedule reminder for unpaid bills
        if (notificationProvider.billRemindersEnabled && !bill.isPaid) {
          await notificationProvider.sendBillReminder(
            billId: bill.id,
            billName: bill.name,
            amount: bill.amount,
            dueDate: bill.dueDate,
            currency: settingsProvider.currency,
          );
        }
      }

      debugPrint('BillProvider: Bill added and UI refreshed');
    } catch (e) {
      debugPrint('BillProvider: Error adding bill: $e');
      rethrow;
    }
  }

  // Mark bill as paid
  Future<void> markBillAsPaid(Bill bill) async {
    try {
      debugPrint('BillProvider: Marking bill ${bill.id} as paid...');
      final updatedBill = bill.copyWith(status: 'paid');
      await _supabaseService.updateBill(updatedBill);

      // Immediately refresh so UI updates without waiting for realtime
      await _fetchBills();

      // Cancel scheduled reminder
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        try {
          final notificationProvider = context.read<NotificationProvider>();
          final settingsProvider = context.read<SettingsProvider>();
          await notificationProvider.cancelBillReminder(bill.id);
          await notificationProvider.sendBillPaid(
            billName: bill.name,
            amount: bill.amount,
            currency: settingsProvider.currency,
          );
        } catch (e) {
          debugPrint('BillProvider: Error sending bill paid notification: $e');
        }
      }

      debugPrint('BillProvider: Bill marked as paid and UI refreshed');
    } catch (e) {
      debugPrint('BillProvider: Error marking bill as paid: $e');
      rethrow;
    }
  }

  Future<void> updateBill(Bill bill) async {
    try {
      debugPrint('📝 BillProvider: Updating bill ${bill.id}...');
      await _supabaseService.updateBill(bill);

      // Immediately refresh so UI updates without waiting for realtime
      await _fetchBills();

      debugPrint('✅ BillProvider: Bill updated and UI refreshed');
    } catch (e) {
      debugPrint('❌ BillProvider: Error updating bill: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteBill(String billId) async {
    try {
      debugPrint('🗑️ BillProvider: Deleting bill $billId...');
      await _supabaseService.deleteBill(billId);

      // Immediately refresh so UI updates without waiting for realtime
      await _fetchBills();

      debugPrint('✅ BillProvider: Bill deleted and UI refreshed');
    } catch (e) {
      debugPrint('❌ BillProvider: Error deleting bill: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Bill? getBillById(String id) {
    try {
      return _bills.firstWhere((bill) => bill.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Bill> get upcomingBills {
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));

    return _bills
        .where((bill) =>
            bill.dueDate.isAfter(now) &&
            bill.dueDate.isBefore(thirtyDaysFromNow) &&
            bill.status != 'paid')
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<Bill> get overdueBills {
    final now = DateTime.now();
    return _bills
        .where((bill) => bill.dueDate.isBefore(now) && bill.status != 'paid')
        .toList();
  }

  List<Bill> get paidBills {
    return _bills.where((bill) => bill.status == 'paid').toList();
  }

  double get totalUpcoming {
    return upcomingBills.fold(0.0, (sum, bill) => sum + bill.amount);
  }

  double get totalOverdue {
    return overdueBills.fold(0.0, (sum, bill) => sum + bill.amount);
  }

  Future<void> markAsPaid(String billId) async {
    try {
      debugPrint('💵 BillProvider: Marking bill as paid...');

      final bill = getBillById(billId);
      if (bill != null) {
        final paidBill = Bill(
          id: bill.id,
          name: bill.name,
          amount: bill.amount,
          categoryId: bill.categoryId,
          dueDate: bill.dueDate,
          repeatType: bill.repeatType,
          status: 'paid',
          note: bill.note,
        );
        await updateBill(paidBill);

        if (bill.repeatType != 'none') {
          debugPrint('🔄 Creating next recurring bill...');
          await _createNextRecurringBill(paidBill);
        }

        debugPrint('✅ BillProvider: Bill marked as paid');
      }
    } catch (e) {
      debugPrint('❌ BillProvider: Error marking bill as paid: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _createNextRecurringBill(Bill bill) async {
    try {
      DateTime nextDueDate;

      switch (bill.repeatType) {
        case 'weekly':
          nextDueDate = bill.dueDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          nextDueDate = DateTime(
            bill.dueDate.year,
            bill.dueDate.month + 1,
            bill.dueDate.day,
          );
          break;
        case 'yearly':
          nextDueDate = DateTime(
            bill.dueDate.year + 1,
            bill.dueDate.month,
            bill.dueDate.day,
          );
          break;
        default:
          return;
      }

      final nextBill = Bill(
        id: 'bill_${DateTime.now().millisecondsSinceEpoch}',
        name: bill.name,
        amount: bill.amount,
        categoryId: bill.categoryId,
        dueDate: nextDueDate,
        repeatType: bill.repeatType,
        status: 'pending',
        note: bill.note,
      );

      await _supabaseService.addBill(nextBill);
      debugPrint('✅ Next recurring bill created successfully');
    } catch (e) {
      debugPrint('❌ Error creating recurring bill: $e');
    }
  }

  Future<void> updateBillStatuses() async {
    try {
      final now = DateTime.now();

      for (var bill in _bills) {
        if (bill.status != 'paid' && bill.dueDate.isBefore(now)) {
          if (bill.status != 'overdue') {
            final overdueBill = Bill(
              id: bill.id,
              name: bill.name,
              amount: bill.amount,
              dueDate: bill.dueDate,
              repeatType: bill.repeatType,
              status: 'overdue',
              note: bill.note,
              categoryId: bill.categoryId,
            );
            await updateBill(overdueBill);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating bill statuses: $e');
    }
  }

  Future<void> convertAllBills(double conversionRate) async {
    try {
      for (var bill in _bills) {
        final convertedBill = Bill(
          id: bill.id,
          name: bill.name,
          amount: bill.amount * conversionRate,
          dueDate: bill.dueDate,
          repeatType: bill.repeatType,
          status: bill.status,
          note: bill.note,
          categoryId: bill.categoryId,
        );
        await updateBill(convertedBill);
      }
    } catch (e) {
      debugPrint('❌ Error converting bills: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> scheduleBillReminders() async {
    try {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        final notificationProvider = context.read<NotificationProvider>();
        final settingsProvider = context.read<SettingsProvider>();

        if (!notificationProvider.notificationsEnabled ||
            !notificationProvider.billRemindersEnabled) {
          return;
        }

        for (final bill in _bills) {
          if (!bill.isPaid && bill.dueDate.isAfter(DateTime.now())) {
            await notificationProvider.sendBillReminder(
              billId: bill.id,
              billName: bill.name,
              amount: bill.amount,
              dueDate: bill.dueDate,
              currency: settingsProvider.currency,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('BillProvider: Error scheduling reminders: $e');
    }
  }

  Future<void> checkOverdueBills() async {
    try {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        final notificationProvider = context.read<NotificationProvider>();
        final settingsProvider = context.read<SettingsProvider>();

        if (!notificationProvider.notificationsEnabled ||
            !notificationProvider.billRemindersEnabled) {
          return;
        }

        final now = DateTime.now();

        for (final bill in _bills) {
          if (!bill.isPaid && bill.dueDate.isBefore(now)) {
            final daysOverdue = now.difference(bill.dueDate).inDays;

            await notificationProvider.sendOverdueBillNotification(
              billName: bill.name,
              amount: bill.amount,
              daysOverdue: daysOverdue,
              currency: settingsProvider.currency,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('BillProvider: Error checking overdue bills: $e');
    }
  }

  /// Check for bills due today and send immediate alerts
  Future<void> checkBillsDueToday() async {
    try {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        final notificationProvider = context.read<NotificationProvider>();
        final settingsProvider = context.read<SettingsProvider>();

        if (!notificationProvider.notificationsEnabled ||
            !notificationProvider.billRemindersEnabled) {
          return;
        }

        final now = DateTime.now();

        for (final bill in _bills) {
          if (!bill.isPaid &&
              bill.dueDate.year == now.year &&
              bill.dueDate.month == now.month &&
              bill.dueDate.day == now.day) {
            await notificationProvider.sendBillDueToday(
            billName: bill.name,
            amount: bill.amount,
            currency: settingsProvider.currency,
          );
        }
      }
      }
    } catch (e) {
      debugPrint('BillProvider: Error checking bills due today: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('🔚 BillProvider: Disposing...');
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
