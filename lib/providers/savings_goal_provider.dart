import '../main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/savings_goal.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'notification_provider.dart';
import 'settings_provider.dart';

class SavingsGoalProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  List<SavingsGoal> _savingsGoals = [];
  bool _isLoading = false;
  RealtimeChannel? _realtimeChannel;

  // Track which milestones have been sent to avoid duplicates
  final Map<String, Set<int>> _sentMilestones = {};

  SavingsGoalProvider(this._supabaseService) {
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

  // Getters
  List<SavingsGoal> get savingsGoals => _savingsGoals;
  bool get isLoading => _isLoading;

  List<SavingsGoal> get activeGoals =>
      _savingsGoals.where((goal) => !goal.isCompleted).toList();

  List<SavingsGoal> get completedGoals =>
      _savingsGoals.where((goal) => goal.isCompleted).toList();

  double get totalTargetAmount {
    return activeGoals.fold(0.0, (sum, goal) => sum + goal.targetAmount);
  }

  double get totalSavedAmount {
    return activeGoals.fold(0.0, (sum, goal) => sum + goal.currentAmount);
  }

  double get overallProgress {
    if (totalTargetAmount <= 0) return 0;
    final percentage = (totalSavedAmount / totalTargetAmount) * 100;
    return percentage > 100 ? 100 : percentage;
  }

  // Initialize and listen to changes
  Future<void> _initialize() async {
    if (!SupabaseService.isAuthenticated) {
      _isLoading = false;
      _safeNotify();
      return;
    }

    debugPrint('🎯 SavingsGoalProvider: Initializing...');
    await _fetchSavingsGoals();
    _subscribeToChanges();
  }

  /// Re-fetch data after login (called from main.dart onAuthStateChange)
  Future<void> refreshData() async {
    debugPrint('🔄 SavingsGoalProvider: Refreshing data after auth change...');
    _sentMilestones.clear();
    await _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;

    if (!SupabaseService.isAuthenticated) {
      _savingsGoals = [];
      _isLoading = false;
      _safeNotify();
      return;
    }

    await _initialize();
  }

  // Fetch all savings goals from Supabase
  Future<void> _fetchSavingsGoals() async {
    try {
      _isLoading = true;
      _safeNotify();

      if (!SupabaseService.isAuthenticated) {
        _isLoading = false;
        _safeNotify();
        return;
      }

      debugPrint('🎯 SavingsGoalProvider: Fetching savings goals...');
      final data = await _supabaseService.getSavingsGoals();

      _savingsGoals = data.map((json) => SavingsGoal.fromJson(json)).toList()
        ..sort((a, b) {
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }
          return b.createdAt.compareTo(a.createdAt);
        });

      debugPrint('✅ SavingsGoalProvider: Loaded ${_savingsGoals.length} goals');
      _isLoading = false;
      _safeNotify();
    } catch (e) {
      debugPrint('❌ SavingsGoalProvider: Error loading goals: $e');
      _isLoading = false;
      _safeNotify();
    }
  }

  // Subscribe to realtime changes
  void _subscribeToChanges() {
    final userId = _supabaseService.currentUserId;
    if (userId.isEmpty) return;
    debugPrint('👂 SavingsGoalProvider: Subscribing to realtime changes...');

    _realtimeChannel = Supabase.instance.client
        .channel('savings_goals_changes_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'savings_goals',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint(
                '🔄 SavingsGoalProvider: Realtime event: ${payload.eventType}');
            _fetchSavingsGoals();
          },
        )
        .subscribe((status, [error]) {
      debugPrint('📡 SavingsGoalProvider: Realtime status: $status');
      if (error != null) {
        debugPrint('❌ SavingsGoalProvider: Realtime error: $error');
      }
    });
  }

  // Add new savings goal
  Future<void> addSavingsGoal(SavingsGoal goal) async {
    try {
      debugPrint('📝 SavingsGoalProvider: Adding savings goal...');
      await _supabaseService.addSavingsGoal(goal.toJson());
      _sentMilestones[goal.id] = {};

      // Immediately refresh so UI updates without waiting for realtime
      await _fetchSavingsGoals();

      // Send instant notification
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        try {
          final notificationProvider = context.read<NotificationProvider>();
          final settingsProvider = context.read<SettingsProvider>();
          await notificationProvider.sendSavingsGoalAdded(
            goalName: goal.name,
            targetAmount: goal.targetAmount,
            currency: settingsProvider.currency,
          );
        } catch (e) {
          debugPrint(
              '❌ SavingsGoalProvider: Error sending goal notification: $e');
        }
      }

      debugPrint('✅ SavingsGoalProvider: Goal added and UI refreshed');
    } catch (e) {
      debugPrint('❌ SavingsGoalProvider: Error adding goal: $e');
      rethrow;
    }
  }

  // Update savings goal
  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    try {
      debugPrint('📝 SavingsGoalProvider: Updating goal ${goal.id}...');
      await _supabaseService.updateSavingsGoal(goal.toJson());

      // Immediately refresh so UI updates without waiting for realtime
      await _fetchSavingsGoals();

      debugPrint('✅ SavingsGoalProvider: Goal updated and UI refreshed');
    } catch (e) {
      debugPrint('❌ SavingsGoalProvider: Error updating goal: $e');
      rethrow;
    }
  }

  // Delete savings goal
  Future<void> deleteSavingsGoal(String id) async {
    try {
      debugPrint('🗑️ SavingsGoalProvider: Deleting goal $id...');
      await _supabaseService.deleteSavingsGoal(id);
      _sentMilestones.remove(id);

      // Immediately refresh so UI updates without waiting for realtime
      await _fetchSavingsGoals();

      debugPrint('✅ SavingsGoalProvider: Goal deleted and UI refreshed');
    } catch (e) {
      debugPrint('❌ SavingsGoalProvider: Error deleting goal: $e');
      rethrow;
    }
  }

  // Add money to a goal
  Future<void> addMoneyToGoal(
    String goalId,
    double amount,
  ) async {
    try {
      debugPrint('💰 SavingsGoalProvider: Adding $amount to goal $goalId...');

      final goal = _savingsGoals.firstWhere((g) => g.id == goalId);
      final previousProgress = goal.progressPercentage;

      final newAmount = goal.currentAmount + amount;
      final isCompleted = newAmount >= goal.targetAmount;

      final updatedGoal = goal.copyWith(
        currentAmount: newAmount,
        isCompleted: isCompleted,
        updatedAt: DateTime.now(),
      );

      await updateSavingsGoal(updatedGoal);
      await checkGoalMilestones(updatedGoal, previousProgress);
      await _checkGoalBehindSchedule(updatedGoal);

      // Send deposit notification
      try {
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          final notificationProvider = context.read<NotificationProvider>();
          final settingsProvider = context.read<SettingsProvider>();
          await notificationProvider.sendSavingsDeposit(
            goalName: goal.name,
            amount: amount,
            progressPercent: updatedGoal.progressPercentage,
            currency: settingsProvider.currency,
          );
        }
      } catch (e) {
        debugPrint(
            '❌ SavingsGoalProvider: Error sending deposit notification: $e');
      }

      debugPrint('✅ SavingsGoalProvider: Money added successfully');
    } catch (e) {
      debugPrint('❌ SavingsGoalProvider: Error adding money: $e');
      rethrow;
    }
  }

  // Withdraw money from a goal
  Future<void> withdrawFromGoal(String goalId, double amount) async {
    try {
      debugPrint(
          '💸 SavingsGoalProvider: Withdrawing $amount from goal $goalId...');

      final goal = _savingsGoals.firstWhere((g) => g.id == goalId);
      final newAmount = goal.currentAmount - amount;

      if (newAmount < 0) {
        throw Exception('Cannot withdraw more than current amount');
      }

      final updatedGoal = goal.copyWith(
        currentAmount: newAmount,
        isCompleted: false,
        updatedAt: DateTime.now(),
      );

      await updateSavingsGoal(updatedGoal);
      debugPrint('✅ SavingsGoalProvider: Amount withdrawn successfully');
    } catch (e) {
      debugPrint('❌ SavingsGoalProvider: Error withdrawing from goal: $e');
      rethrow;
    }
  }

  // Mark goal as completed
  Future<void> completeGoal(String goalId) async {
    try {
      debugPrint('✅ SavingsGoalProvider: Completing goal $goalId...');

      final goal = _savingsGoals.firstWhere((g) => g.id == goalId);
      final updatedGoal = goal.copyWith(
        isCompleted: true,
        updatedAt: DateTime.now(),
      );

      await updateSavingsGoal(updatedGoal);
      debugPrint('✅ SavingsGoalProvider: Goal completed successfully');
    } catch (e) {
      debugPrint('❌ SavingsGoalProvider: Error completing goal: $e');
      rethrow;
    }
  }

  // Reactivate a completed goal
  Future<void> reactivateGoal(String goalId) async {
    try {
      debugPrint('🔄 SavingsGoalProvider: Reactivating goal $goalId...');

      final goal = _savingsGoals.firstWhere((g) => g.id == goalId);
      final updatedGoal = goal.copyWith(
        isCompleted: false,
        updatedAt: DateTime.now(),
      );

      await updateSavingsGoal(updatedGoal);
      _sentMilestones[goalId] = {};
      debugPrint('✅ SavingsGoalProvider: Goal reactivated successfully');
    } catch (e) {
      debugPrint('❌ SavingsGoalProvider: Error reactivating goal: $e');
      rethrow;
    }
  }

  // Check and send goal milestone notifications
  Future<void> checkGoalMilestones(
    SavingsGoal goal,
    double previousProgress,
  ) async {
    try {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        final notificationProvider = context.read<NotificationProvider>();
        final settingsProvider = context.read<SettingsProvider>();

        if (!notificationProvider.notificationsEnabled ||
            !notificationProvider.goalMilestonesEnabled) {
          return;
        }

      final currentProgress = goal.progressPercentage;
      final milestones = [25, 50, 75, 100];

      _sentMilestones[goal.id] ??= {};

      for (final milestone in milestones) {
        if (previousProgress < milestone &&
            currentProgress >= milestone &&
            !_sentMilestones[goal.id]!.contains(milestone)) {
          _sentMilestones[goal.id]!.add(milestone);

          await notificationProvider.sendGoalMilestone(
            goalName: goal.name,
            percentage: milestone,
            saved: goal.currentAmount,
            target: goal.targetAmount,
            currency: settingsProvider.currency,
          );

          debugPrint('✅ Milestone notification sent: $milestone%');
          break;
        }
      }
      }
    } catch (e) {
      debugPrint('❌ SavingsGoalProvider: Error checking milestones: $e');
    }
  }

  // Check if a single goal is behind schedule and notify
  Future<void> _checkGoalBehindSchedule(
    SavingsGoal goal,
  ) async {
    try {
      if (goal.isCompleted || goal.targetDate == null) return;

      final now = DateTime.now();
      final totalDays = goal.targetDate!.difference(goal.createdAt).inDays;
      final elapsedDays = now.difference(goal.createdAt).inDays;

      if (totalDays <= 0) return;

      final expectedProgress = (elapsedDays / totalDays) * 100;
      final actualProgress = goal.progressPercentage;

      // Alert if more than 10% behind expected progress
      if (actualProgress < (expectedProgress - 10)) {
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          final notificationProvider = context.read<NotificationProvider>();
          final settingsProvider = context.read<SettingsProvider>();

          if (!notificationProvider.notificationsEnabled ||
              !notificationProvider.goalMilestonesEnabled) {
            return;
          }

        final daysRemaining = goal.targetDate!.difference(now).inDays;
        final expectedAmount = goal.targetAmount * (elapsedDays / totalDays);

        await notificationProvider.sendGoalBehindSchedule(
          goalName: goal.name,
          currentAmount: goal.currentAmount,
          expectedAmount: expectedAmount,
          targetAmount: goal.targetAmount,
          daysRemaining: daysRemaining,
          currency: settingsProvider.currency,
        );
        }
      }
    } catch (e) {
      debugPrint('❌ SavingsGoalProvider: Error checking behind schedule: $e');
    }
  }

  // Check all active goals for behind-schedule status
  Future<void> checkAllGoalsBehindSchedule() async {
    for (final goal in activeGoals) {
      await _checkGoalBehindSchedule(goal);
    }
  }

  SavingsGoal? getGoalById(String id) {
    try {
      return _savingsGoals.firstWhere((goal) => goal.id == id);
    } catch (e) {
      return null;
    }
  }

  List<SavingsGoal> getGoalsByDateRange(DateTime start, DateTime end) {
    return _savingsGoals.where((goal) {
      if (goal.targetDate == null) return false;
      return goal.targetDate!
              .isAfter(start.subtract(const Duration(days: 1))) &&
          goal.targetDate!.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  List<SavingsGoal> get goalsNearCompletion {
    return activeGoals.where((goal) => goal.progressPercentage >= 90).toList();
  }

  List<SavingsGoal> get goalsBehindSchedule {
    final now = DateTime.now();
    return activeGoals.where((goal) {
      if (goal.targetDate == null) return false;

      final totalDays = goal.targetDate!.difference(goal.createdAt).inDays;
      final elapsedDays = now.difference(goal.createdAt).inDays;

      if (totalDays <= 0) return false;

      final expectedProgress = (elapsedDays / totalDays) * 100;
      final actualProgress = goal.progressPercentage;

      return actualProgress < (expectedProgress - 10);
    }).toList();
  }

  double get totalAmountNeeded {
    return activeGoals.fold(
      0.0,
      (sum, goal) => sum + (goal.targetAmount - goal.currentAmount),
    );
  }

  void resetMilestoneTracking(String goalId) {
    _sentMilestones[goalId] = {};
  }

  void resetAllMilestoneTracking() {
    _sentMilestones.clear();
  }

  @override
  void dispose() {
    debugPrint('👋 SavingsGoalProvider: Disposing...');
    _realtimeChannel?.unsubscribe();
    _sentMilestones.clear();
    super.dispose();
  }
}
