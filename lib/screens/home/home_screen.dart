import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/expense_provider.dart';
import '../../providers/money_note_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/budget_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/slide_animation.dart';
import '../budget/budget_history_screen.dart';
import '../settings/settings_screen.dart';
import '../expenses/expense_details_screen.dart';
import '../expenses/expenses_screen.dart'; // ✅ Import Expenses Screen
import '../money_notes/money_notes_screen.dart'; // ✅ Import Money Notes Screen
import '../bills/bills_screen.dart'; // ✅ Import Bills Screen
import '../bills/bill_details_screen.dart';
import '../stats/stats_screen.dart'; // ✅ Import Stats Screen
import '../profile/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Consumer6<ExpenseProvider, MoneyNoteProvider, BillProvider,
            CategoryProvider, SettingsProvider, BudgetProvider>(
          builder: (context, expenseProvider, moneyNoteProvider, billProvider,
              categoryProvider, settingsProvider, budgetProvider, _) {
            final now = DateTime.now();
            final monthTotal = expenseProvider.getTotalByMonth(now);
            final currentBudget = budgetProvider.getBudgetForDate(now);
            final budget =
                currentBudget?.totalAmount ?? settingsProvider.monthlyBudget;
            final remaining = budget - monthTotal;

            final toReceive = moneyNoteProvider.totalToReceive;
            final toPay = moneyNoteProvider.totalToPay;

            final recentExpenses = expenseProvider.expenses.take(5).toList();
            final upcomingBills = billProvider.upcomingBills.take(3).toList();
            final categoryTotals = expenseProvider.getCategoryTotals();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(context, isDark, billProvider),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: Responsive.hp(context, 2)),

                      // Animated Budget Circle
                      SlideInAnimation(
                        delay: 0,
                        child: _buildBudgetCircle(
                          context,
                          isDark,
                          monthTotal,
                          budget,
                          remaining,
                          settingsProvider,
                          budgetProvider,
                        ),
                      ),

                      SizedBox(height: Responsive.hp(context, 3)),

                      // Animated Money Notes Summary
                      SlideInAnimation(
                        delay: 100,
                        child: _buildMoneyNotesSummary(
                          context,
                          isDark,
                          toReceive,
                          toPay,
                          settingsProvider,
                        ),
                      ),
                      Consumer2<BudgetProvider, ExpenseProvider>(
                        builder: (context, budgetProvider, expenseProvider, _) {
                          return _buildMultiBudgetWidget(
                            context,
                            isDark,
                            budgetProvider,
                            settingsProvider,
                          );
                        },
                      ),
                      SizedBox(height: Responsive.hp(context, 3)),

                      if (categoryTotals.isNotEmpty)
                        SlideInAnimation(
                          delay: 200,
                          child: _buildTopCategories(
                            context,
                            isDark,
                            categoryTotals,
                            categoryProvider,
                            settingsProvider,
                          ),
                        ),

                      SizedBox(height: Responsive.hp(context, 3)),

                      if (recentExpenses.isNotEmpty)
                        SlideInAnimation(
                          delay: 300,
                          child: _buildRecentExpenses(
                            context,
                            isDark,
                            recentExpenses,
                            categoryProvider,
                            settingsProvider,
                          ),
                        ),

                      SizedBox(height: Responsive.hp(context, 3)),

                      if (upcomingBills.isNotEmpty)
                        SlideInAnimation(
                          delay: 400,
                          child: _buildUpcomingBills(
                            context,
                            isDark,
                            upcomingBills,
                            settingsProvider,
                          ),
                        ),

                      SizedBox(height: Responsive.hp(context, 10)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, bool isDark, BillProvider billProvider) {
    // ✅ GET CURRENT USER
    final user = Supabase.instance.client.auth.currentUser;

    // ✅ GET USER NAME (from metadata or email)
    String userName = 'User';
    String userInitial = 'U';

    if (user != null) {
      // Try to get name from user metadata first
      final metadataName = user.userMetadata?['name'] as String?;
      final metadataFullName = user.userMetadata?['full_name'] as String?;

      if (metadataName != null && metadataName.isNotEmpty) {
        userName = metadataName;
      } else if (metadataFullName != null && metadataFullName.isNotEmpty) {
        userName = metadataFullName;
      } else if (user.email != null) {
        // Extract name from email (e.g., "john.doe@example.com" -> "john.doe")
        userName = user.email!.split('@')[0];
        // Capitalize first letter
        userName = userName.split('.').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        }).join(' ');
      }

      // Get first letter for avatar
      userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    }

    return SliverAppBar(
      floating: true,
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: Responsive.wp(context, 12),
            height: Responsive.wp(context, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFF00D4AA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                userInitial, // ✅ DYNAMIC INITIAL
                style: TextStyle(
                  fontSize: Responsive.sp(context, 18),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: Responsive.wp(context, 3)),

          // ✅ MADE CLICKABLE: Wrap greeting section with GestureDetector
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Navigate to Profile Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: Container(
                color: Colors.transparent, // Make entire area tappable
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: Responsive.sp(context, 13),
                        color: isDark
                            ? AppTheme.textMutedDark
                            : AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName, // ✅ DYNAMIC USER NAME
                            style: TextStyle(
                              fontSize: Responsive.sp(context, 17),
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppTheme.textDark
                                  : AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: Responsive.wp(context, 1)),
                        Icon(
                          Icons.chevron_right,
                          size: Responsive.sp(context, 18),
                          color: isDark
                              ? AppTheme.textMutedDark
                              : AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
          icon: Container(
            padding: EdgeInsets.all(Responsive.wp(context, 2)),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.settings,
              color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
              size: Responsive.sp(context, 20),
            ),
          ),
        ),
        Stack(
          children: [
            IconButton(
              onPressed: () {
                // ✅ Show notifications
                _showNotificationsSheet(context, isDark, billProvider);
              },
              icon: Container(
                padding: EdgeInsets.all(Responsive.wp(context, 2)),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications,
                  color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                  size: Responsive.sp(context, 20),
                ),
              ),
            ),
            if (billProvider.overdueBills.isNotEmpty ||
                billProvider.upcomingBills.isNotEmpty)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: Responsive.wp(context, 2.5),
                  height: Responsive.wp(context, 2.5),
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppTheme.backgroundDark
                          : AppTheme.backgroundLight,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetCircle(
    BuildContext context,
    bool isDark,
    double spent,
    double budget,
    double remaining,
    SettingsProvider settingsProvider,
    BudgetProvider budgetProvider,
  ) {
    final percentage = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final now = DateTime.now();
    final currentBudget = budgetProvider.getBudgetForDate(now);
    final circleSize = Responsive.wp(context, 55).clamp(180.0, 240.0);
    final isOverBudget = remaining < 0;

    return GestureDetector(
      onTap: () async {
        // Show options: Manage Budget or Add Income
        await _showBudgetOptions(
          context,
          isDark,
          budgetProvider,
          settingsProvider,
          currentBudget,
          now,
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Responsive.wp(context, 4)),
        child: PremiumCard(
          padding: EdgeInsets.all(Responsive.wp(context, 6)),
          child: Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background Circle
                    SizedBox(
                      width: circleSize,
                      height: circleSize,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: circleSize * 0.09,
                        backgroundColor: isDark
                            ? Colors.grey.shade800.withValues(alpha: 0.3)
                            : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark
                              ? Colors.grey.shade800.withValues(alpha: 0.3)
                              : Colors.grey.shade200,
                        ),
                      ),
                    ),

                    // Progress Circle
                    SizedBox(
                      width: circleSize,
                      height: circleSize,
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: 0, end: percentage),
                        builder: (context, value, child) {
                          return CircularProgressIndicator(
                            value: value,
                            strokeWidth: circleSize * 0.09,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getBudgetColor(value),
                            ),
                          );
                        },
                      ),
                    ),

                    // Center Content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isOverBudget ? 'Over Budget!' : 'Remaining',
                          style: TextStyle(
                            fontSize: Responsive.sp(context, 12),
                            color: isDark
                                ? AppTheme.textMutedDark
                                : AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: Responsive.hp(context, 0.8)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: Responsive.wp(context, 4)),
                            child: Text(
                              settingsProvider.formatCurrency(remaining.abs()),
                              style: TextStyle(
                                fontSize: Responsive.sp(context, 32),
                                fontWeight: FontWeight.bold,
                                color: isOverBudget
                                    ? AppTheme.danger
                                    : (isDark
                                        ? AppTheme.textDark
                                        : AppTheme.textPrimary),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: Responsive.hp(context, 0.5)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.wp(context, 3),
                            vertical: Responsive.hp(context, 0.5),
                          ),
                          decoration: BoxDecoration(
                            color:
                                _getBudgetColor(percentage).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(percentage * 100).toStringAsFixed(0)}% used',
                            style: TextStyle(
                              fontSize: Responsive.sp(context, 11),
                              fontWeight: FontWeight.bold,
                              color: _getBudgetColor(percentage),
                            ),
                          ),
                        ),
                        SizedBox(height: Responsive.hp(context, 1)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.wp(context, 3),
                            vertical: Responsive.hp(context, 0.7),
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app,
                                size: Responsive.sp(context, 12),
                                color: AppTheme.primary,
                              ),
                              SizedBox(width: Responsive.wp(context, 1)),
                              Text(
                                'Tap to manage budget',
                                style: TextStyle(
                                  fontSize: Responsive.sp(context, 10),
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: Responsive.hp(context, 3)),

                // Stats Row
                Container(
                  padding: EdgeInsets.all(Responsive.wp(context, 4)),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.02)
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(
                        Responsive.borderRadius(context, 16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBudgetStat(
                        context,
                        'Spent',
                        settingsProvider.formatCurrency(spent),
                        AppTheme.danger,
                        isDark,
                      ),
                      Container(
                        width: 1,
                        height: Responsive.hp(context, 5),
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.shade300,
                      ),
                      _buildBudgetStat(
                        context,
                        'Budget',
                        settingsProvider.formatCurrency(budget),
                        AppTheme.primary,
                        isDark,
                      ),
                    ],
                  ),
                ),

                if (currentBudget != null &&
                    currentBudget.adjustments.isNotEmpty) ...[
                  SizedBox(height: Responsive.hp(context, 1.5)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.wp(context, 3),
                      vertical: Responsive.hp(context, 1),
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.success.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: Responsive.sp(context, 14),
                          color: AppTheme.success,
                        ),
                        SizedBox(width: Responsive.wp(context, 1.5)),
                        Flexible(
                          child: Text(
                            'Budget has ${currentBudget.adjustments.length} adjustment${currentBudget.adjustments.length > 1 ? "s" : ""}',
                            style: TextStyle(
                              fontSize: Responsive.sp(context, 11),
                              color: AppTheme.success,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (currentBudget.totalIncome > 0) ...[
                          SizedBox(width: Responsive.wp(context, 2)),
                          Text(
                            '+${settingsProvider.formatCurrency(currentBudget.totalIncome)}',
                            style: TextStyle(
                              fontSize: Responsive.sp(context, 11),
                              fontWeight: FontWeight.bold,
                              color: AppTheme.success,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetStat(
    BuildContext context,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.sp(context, 11),
            color: isDark ? AppTheme.textMutedDark : AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: Responsive.hp(context, 0.5)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: Responsive.sp(context, 18),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Color _getBudgetColor(double percentage) {
    if (percentage >= 1.0) {
      return AppTheme.danger;
    } else if (percentage >= 0.8) {
      return Colors.orange;
    } else if (percentage >= 0.5) {
      return Colors.amber;
    } else {
      return AppTheme.success;
    }
  }

  Widget _buildMoneyNotesSummary(
    BuildContext context,
    bool isDark,
    double toReceive,
    double toPay,
    SettingsProvider settingsProvider,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.wp(context, 4)),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                // ✅ FIXED: Navigate to Money Notes Screen as new page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MoneyNotesScreen(),
                  ),
                );
              },
              child: GradientCard(
                gradientColors: const [Color(0xFF34C759), Color(0xFF30D158)],
                padding: EdgeInsets.all(Responsive.wp(context, 5)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(Responsive.wp(context, 2)),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_downward,
                            color: Colors.white,
                            size: Responsive.sp(context, 16),
                          ),
                        ),
                        SizedBox(width: Responsive.wp(context, 2)),
                        Flexible(
                          child: Text(
                            'To Receive',
                            style: TextStyle(
                              fontSize: Responsive.sp(context, 12),
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.hp(context, 1.5)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        settingsProvider.formatCurrency(toReceive),
                        style: TextStyle(
                          fontSize: Responsive.sp(context, 24),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: Responsive.wp(context, 4)),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // ✅ FIXED: Navigate to Money Notes Screen as new page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MoneyNotesScreen(),
                  ),
                );
              },
              child: GradientCard(
                gradientColors: const [Color(0xFFFF3B30), Color(0xFFFF6B6B)],
                padding: EdgeInsets.all(Responsive.wp(context, 5)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(Responsive.wp(context, 2)),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_upward,
                            color: Colors.white,
                            size: Responsive.sp(context, 16),
                          ),
                        ),
                        SizedBox(width: Responsive.wp(context, 2)),
                        Flexible(
                          child: Text(
                            'To Pay',
                            style: TextStyle(
                              fontSize: Responsive.sp(context, 12),
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.hp(context, 1.5)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        settingsProvider.formatCurrency(toPay),
                        style: TextStyle(
                          fontSize: Responsive.sp(context, 24),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategories(
    BuildContext context,
    bool isDark,
    Map<String, double> categoryTotals,
    CategoryProvider categoryProvider,
    SettingsProvider settingsProvider,
  ) {
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Responsive.wp(context, 4)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Categories',
                style: TextStyle(
                  fontSize: Responsive.sp(context, 18),
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // ✅ FIXED: Navigate to Stats Screen to see category breakdown
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StatsScreen(),
                    ),
                  );
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: Responsive.sp(context, 14),
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Responsive.hp(context, 1)),
        ...topCategories.asMap().entries.map((entry) {
          final index = entry.key;
          final categoryEntry = entry.value;
          final category = categoryProvider.getCategoryById(categoryEntry.key);

          return SlideInAnimation(
            delay: 350 + (index * 50),
            child: AnimatedCard(
              onTap: () {
                // ✅ FIXED: Navigate to Stats Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StatsScreen(),
                  ),
                );
              },
              margin: EdgeInsets.symmetric(
                horizontal: Responsive.wp(context, 4),
                vertical: Responsive.hp(context, 0.8),
              ),
              child: Padding(
                padding: EdgeInsets.all(Responsive.wp(context, 4)),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(Responsive.wp(context, 3)),
                      decoration: BoxDecoration(
                        color: category != null
                            ? Color(category.colorValue).withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          Responsive.borderRadius(context, 14),
                        ),
                      ),
                      child: Icon(
                        category != null
                            ? IconData(category.iconCodePoint,
                                fontFamily: 'MaterialIcons')
                            : Icons.help_outline,
                        color: category != null
                            ? Color(category.colorValue)
                            : Colors.grey,
                        size: Responsive.sp(context, 24),
                      ),
                    ),
                    SizedBox(width: Responsive.wp(context, 3)),
                    Expanded(
                      child: Text(
                        category?.name ?? 'Unknown',
                        style: TextStyle(
                          fontSize: Responsive.sp(context, 16),
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? AppTheme.textDark : AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        settingsProvider.formatCurrency(categoryEntry.value),
                        style: TextStyle(
                          fontSize: Responsive.sp(context, 18),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRecentExpenses(
    BuildContext context,
    bool isDark,
    List<dynamic> expenses,
    CategoryProvider categoryProvider,
    SettingsProvider settingsProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Responsive.wp(context, 4)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Expenses',
                style: TextStyle(
                  fontSize: Responsive.sp(context, 18),
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // ✅ FIXED: Navigate to Expenses Screen as new page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExpensesScreen(),
                    ),
                  );
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: Responsive.sp(context, 14),
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Responsive.hp(context, 1)),
        ...expenses.asMap().entries.map((entry) {
          final index = entry.key;
          final expense = entry.value;
          final category = categoryProvider.getCategoryById(expense.categoryId);

          return SlideInAnimation(
            delay: 450 + (index * 50),
            child: AnimatedCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ExpenseDetailsScreen(expense: expense),
                  ),
                );
              },
              margin: EdgeInsets.symmetric(
                horizontal: Responsive.wp(context, 4),
                vertical: Responsive.hp(context, 0.8),
              ),
              child: Padding(
                padding: EdgeInsets.all(Responsive.wp(context, 4)),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(Responsive.wp(context, 3)),
                      decoration: BoxDecoration(
                        color: category != null
                            ? Color(category.colorValue).withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          Responsive.borderRadius(context, 14),
                        ),
                      ),
                      child: Icon(
                        category != null
                            ? IconData(category.iconCodePoint,
                                fontFamily: 'MaterialIcons')
                            : Icons.help_outline,
                        color: category != null
                            ? Color(category.colorValue)
                            : Colors.grey,
                        size: Responsive.sp(context, 24),
                      ),
                    ),
                    SizedBox(width: Responsive.wp(context, 3)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category?.name ?? 'Unknown',
                            style: TextStyle(
                              fontSize: Responsive.sp(context, 16),
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.textDark
                                  : AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: Responsive.hp(context, 0.3)),
                          Text(
                            DateFormat('MMM dd, hh:mm a').format(expense.date),
                            style: TextStyle(
                              fontSize: Responsive.sp(context, 12),
                              color: isDark
                                  ? AppTheme.textMutedDark
                                  : AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        settingsProvider.formatCurrency(expense.amount),
                        style: TextStyle(
                          fontSize: Responsive.sp(context, 18),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildUpcomingBills(
    BuildContext context,
    bool isDark,
    List<dynamic> bills,
    SettingsProvider settingsProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Responsive.wp(context, 4)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Bills',
                style: TextStyle(
                  fontSize: Responsive.sp(context, 18),
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // ✅ FIXED: Navigate to Bills Screen as new page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BillsScreen(),
                    ),
                  );
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: Responsive.sp(context, 14),
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Responsive.hp(context, 1)),
        ...bills.asMap().entries.map((entry) {
          final index = entry.key;
          final bill = entry.value;
          final Color statusColor =
              bill.status == 'overdue' ? AppTheme.danger : AppTheme.success;

          return SlideInAnimation(
            delay: 550 + (index * 50),
            child: AnimatedCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BillDetailsScreen(bill: bill),
                  ),
                );
              },
              margin: EdgeInsets.symmetric(
                horizontal: Responsive.wp(context, 4),
                vertical: Responsive.hp(context, 0.8),
              ),
              child: Padding(
                padding: EdgeInsets.all(Responsive.wp(context, 4)),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(Responsive.wp(context, 3)),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          Responsive.borderRadius(context, 14),
                        ),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: statusColor,
                        size: Responsive.sp(context, 24),
                      ),
                    ),
                    SizedBox(width: Responsive.wp(context, 3)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.name,
                            style: TextStyle(
                              fontSize: Responsive.sp(context, 16),
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.textDark
                                  : AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: Responsive.hp(context, 0.3)),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: Responsive.wp(context, 2),
                                  vertical: Responsive.hp(context, 0.3),
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  bill.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: Responsive.sp(context, 9),
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: Responsive.wp(context, 2)),
                              Text(
                                DateFormat('MMM dd, yyyy').format(bill.dueDate),
                                style: TextStyle(
                                  fontSize: Responsive.sp(context, 12),
                                  color: isDark
                                      ? AppTheme.textMutedDark
                                      : AppTheme.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        settingsProvider.formatCurrency(bill.amount),
                        style: TextStyle(
                          fontSize: Responsive.sp(context, 18),
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // ✅ Notifications Sheet
  void _showNotificationsSheet(
      BuildContext context, bool isDark, BillProvider billProvider) {
    final upcomingBills = billProvider.upcomingBills;
    final overdueBills = billProvider.overdueBills;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: Responsive.hp(context, 60),
          padding: EdgeInsets.all(Responsive.wp(context, 5)),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  Icon(
                    Icons.notifications,
                    color: AppTheme.primary,
                    size: Responsive.sp(context, 24),
                  ),
                  SizedBox(width: Responsive.wp(context, 2)),
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: Responsive.sp(context, 20),
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (upcomingBills.isNotEmpty || overdueBills.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BillsScreen(),
                          ),
                        );
                      },
                      child: const Text('View All'),
                    ),
                ],
              ),

              SizedBox(height: Responsive.hp(context, 2)),

              // Notifications list
              Expanded(
                child: overdueBills.isEmpty && upcomingBills.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: Responsive.sp(context, 48),
                              color: Colors.grey,
                            ),
                            SizedBox(height: Responsive.hp(context, 2)),
                            Text(
                              'No notifications',
                              style: TextStyle(
                                fontSize: Responsive.sp(context, 16),
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        children: [
                          // Overdue bills
                          if (overdueBills.isNotEmpty) ...[
                            Text(
                              'Overdue Bills (${overdueBills.length})',
                              style: TextStyle(
                                fontSize: Responsive.sp(context, 14),
                                fontWeight: FontWeight.bold,
                                color: AppTheme.danger,
                              ),
                            ),
                            SizedBox(height: Responsive.hp(context, 1)),
                            ...overdueBills.map((bill) {
                              return Container(
                                margin: EdgeInsets.only(
                                  bottom: Responsive.hp(context, 1),
                                ),
                                padding:
                                    EdgeInsets.all(Responsive.wp(context, 3)),
                                decoration: BoxDecoration(
                                  color: AppTheme.danger.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.danger.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: AppTheme.danger,
                                      size: Responsive.sp(context, 20),
                                    ),
                                    SizedBox(width: Responsive.wp(context, 2)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bill.name,
                                            style: TextStyle(
                                              fontSize:
                                                  Responsive.sp(context, 14),
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppTheme.textDark
                                                  : AppTheme.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            'Due: ${DateFormat('MMM dd, yyyy').format(bill.dueDate)}',
                                            style: TextStyle(
                                              fontSize:
                                                  Responsive.sp(context, 12),
                                              color: AppTheme.danger,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            SizedBox(height: Responsive.hp(context, 2)),
                          ],

                          // Upcoming bills
                          if (upcomingBills.isNotEmpty) ...[
                            Text(
                              'Upcoming Bills (${upcomingBills.length})',
                              style: TextStyle(
                                fontSize: Responsive.sp(context, 14),
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                            SizedBox(height: Responsive.hp(context, 1)),
                            ...upcomingBills.take(5).map((bill) {
                              return Container(
                                margin: EdgeInsets.only(
                                  bottom: Responsive.hp(context, 1),
                                ),
                                padding:
                                    EdgeInsets.all(Responsive.wp(context, 3)),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: AppTheme.primary,
                                      size: Responsive.sp(context, 20),
                                    ),
                                    SizedBox(width: Responsive.wp(context, 2)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bill.name,
                                            style: TextStyle(
                                              fontSize:
                                                  Responsive.sp(context, 14),
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppTheme.textDark
                                                  : AppTheme.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            'Due: ${DateFormat('MMM dd, yyyy').format(bill.dueDate)}',
                                            style: TextStyle(
                                              fontSize:
                                                  Responsive.sp(context, 12),
                                              color: isDark
                                                  ? AppTheme.textMutedDark
                                                  : AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showBudgetOptions(
    BuildContext context,
    bool isDark,
    BudgetProvider budgetProvider,
    SettingsProvider settingsProvider,
    dynamic currentBudget,
    DateTime now,
  ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(Responsive.wp(context, 5)),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Text(
                'Budget Options',
                style: TextStyle(
                  fontSize: Responsive.sp(context, 20),
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                ),
              ),

              SizedBox(height: Responsive.hp(context, 3)),

              // Add Income/Adjustment
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(Responsive.wp(context, 3)),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add_circle,
                    color: AppTheme.success,
                    size: Responsive.sp(context, 24),
                  ),
                ),
                title: Text(
                  'Add Income/Adjustment',
                  style: TextStyle(
                    fontSize: Responsive.sp(context, 16),
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Add extra money to this month\'s budget',
                  style: TextStyle(
                    fontSize: Responsive.sp(context, 13),
                    color: isDark
                        ? AppTheme.textMutedDark
                        : AppTheme.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAddIncomeDialog(
                    context,
                    isDark,
                    budgetProvider,
                    settingsProvider,
                    currentBudget,
                    now,
                  );
                },
              ),

              const Divider(height: 32),

              // View Budget History
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(Responsive.wp(context, 3)),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.history,
                    color: AppTheme.primary,
                    size: Responsive.sp(context, 24),
                  ),
                ),
                title: Text(
                  'Manage Budget',
                  style: TextStyle(
                    fontSize: Responsive.sp(context, 16),
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'View budget history and adjustments',
                  style: TextStyle(
                    fontSize: Responsive.sp(context, 13),
                    color: isDark
                        ? AppTheme.textMutedDark
                        : AppTheme.textSecondary,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BudgetHistoryScreen(),
                    ),
                  );
                },
              ),

              SizedBox(height: Responsive.hp(context, 2)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddIncomeDialog(
    BuildContext context,
    bool isDark,
    BudgetProvider budgetProvider,
    SettingsProvider settingsProvider,
    dynamic currentBudget,
    DateTime now,
  ) async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.add_circle,
              color: AppTheme.success,
              size: Responsive.sp(context, 24),
            ),
            SizedBox(width: Responsive.wp(context, 2)),
            Text(
              'Add Income',
              style: TextStyle(
                color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Info
            Container(
              padding: EdgeInsets.all(Responsive.wp(context, 3)),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.success,
                    size: Responsive.sp(context, 16),
                  ),
                  SizedBox(width: Responsive.wp(context, 2)),
                  Expanded(
                    child: Text(
                      'This will increase your budget for this month',
                      style: TextStyle(
                        fontSize: Responsive.sp(context, 12),
                        color: AppTheme.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: Responsive.hp(context, 2)),

            // Amount field
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(
                color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: 'Enter amount',
                prefixText: '${settingsProvider.currency} ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            SizedBox(height: Responsive.hp(context, 2)),

            // Description field
            TextField(
              controller: descriptionController,
              style: TextStyle(
                color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g., Bonus, Gift',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                final description = descriptionController.text.isEmpty
                    ? 'Income'
                    : descriptionController.text;

                try {
                  // Use addMoneyToBudget method (convenience method for income)
                  await budgetProvider.addMoneyToBudget(
                    month: now.month,
                    year: now.year,
                    amount: amount,
                    note: description,
                  );

                  // ✅ CRITICAL: Reload the budget to refresh UI
                  budgetProvider.loadBudgetForMonth(now.month, now.year);

                  // Small delay to ensure stream updates
                  await Future.delayed(const Duration(milliseconds: 300));

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${settingsProvider.formatCurrency(amount)} added to budget!',
                        ),
                        backgroundColor: AppTheme.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppTheme.danger,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiBudgetWidget(
    BuildContext context,
    bool isDark,
    BudgetProvider budgetProvider,
    SettingsProvider settingsProvider,
  ) {
    final activeMultiBudgets = budgetProvider.activeMultiBudgets;

    // ✅ ONLY SHOW IF THERE ARE ACTIVE MULTI-BUDGETS
    if (activeMultiBudgets.isEmpty) {
      return const SizedBox.shrink();
    }

    // ✅ Get expenses for spending calculation
    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);
    final allExpenses = expenseProvider.expenses;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.wp(context, 4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: Responsive.hp(context, 2)),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(Responsive.wp(context, 2)),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.event_repeat,
                      color: const Color(0xFF34C759),
                      size: Responsive.sp(context, 16),
                    ),
                  ),
                  SizedBox(width: Responsive.wp(context, 2)),
                  Text(
                    'Active Multi-Month Budgets',
                    style: TextStyle(
                      fontSize: Responsive.sp(context, 14),
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (activeMultiBudgets.length > 1)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${activeMultiBudgets.length}',
                    style: TextStyle(
                      fontSize: Responsive.sp(context, 12),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF34C759),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: Responsive.hp(context, 1.5)),

          // Multi-Budget Cards (show first 2, or all if <=2)
          ...activeMultiBudgets.take(2).map((multiBudget) {
            final statusColor = const Color(0xFF34C759);

            // ✅ NEW: Calculate spending
            final totalSpent = multiBudget.calculateTotalSpent(allExpenses);
            final remaining = multiBudget.getRemainingBudget(allExpenses);
            final spendingProgress =
                multiBudget.getSpendingProgress(allExpenses);
            final isOverBudget = multiBudget.isOverBudget(allExpenses);
            final currentMonthSpent = multiBudget.calculateMonthSpent(
                allExpenses, multiBudget.currentMonthIndex);

            return GestureDetector(
              onTap: () {
                // Navigate to Budget History when tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BudgetHistoryScreen(),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.only(bottom: Responsive.hp(context, 1.5)),
                padding: EdgeInsets.all(Responsive.wp(context, 4)),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOverBudget
                        ? AppTheme.danger.withValues(alpha: 0.5)
                        : statusColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isOverBudget ? AppTheme.danger : statusColor)
                          .withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Icon
                        Container(
                          padding: EdgeInsets.all(Responsive.wp(context, 2.5)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                isOverBudget ? AppTheme.danger : statusColor,
                                (isOverBudget ? AppTheme.danger : statusColor)
                                    .withValues(alpha: 0.7)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isOverBudget ? Icons.warning : Icons.event_repeat,
                            color: Colors.white,
                            size: Responsive.sp(context, 18),
                          ),
                        ),
                        SizedBox(width: Responsive.wp(context, 3)),

                        // Name & Status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                multiBudget.name,
                                style: TextStyle(
                                  fontSize: Responsive.sp(context, 15),
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppTheme.textDark
                                      : AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: Responsive.hp(context, 0.3)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: (isOverBudget
                                          ? AppTheme.danger
                                          : statusColor)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isOverBudget
                                      ? 'OVER BUDGET'
                                      : 'Month ${multiBudget.currentMonthIndex + 1}/${multiBudget.durationMonths}',
                                  style: TextStyle(
                                    fontSize: Responsive.sp(context, 10),
                                    fontWeight: FontWeight.bold,
                                    color: isOverBudget
                                        ? AppTheme.danger
                                        : statusColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Remaining Amount
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              settingsProvider.formatCurrency(remaining.abs()),
                              style: TextStyle(
                                fontSize: Responsive.sp(context, 18),
                                fontWeight: FontWeight.bold,
                                color: remaining >= 0
                                    ? AppTheme.success
                                    : AppTheme.danger,
                              ),
                            ),
                            Text(
                              remaining >= 0 ? 'left' : 'over',
                              style: TextStyle(
                                fontSize: Responsive.sp(context, 10),
                                color: isDark
                                    ? AppTheme.textMutedDark
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: Responsive.hp(context, 1.5)),

                    // ✅ NEW: Spending Progress Bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.shopping_cart,
                                  size: Responsive.sp(context, 11),
                                  color: isDark
                                      ? AppTheme.textMutedDark
                                      : AppTheme.textSecondary,
                                ),
                                SizedBox(width: Responsive.wp(context, 1)),
                                Text(
                                  'Spent',
                                  style: TextStyle(
                                    fontSize: Responsive.sp(context, 11),
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppTheme.textMutedDark
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${settingsProvider.formatCurrency(totalSpent)} / ${settingsProvider.formatCurrency(multiBudget.totalAmount)}',
                              style: TextStyle(
                                fontSize: Responsive.sp(context, 11),
                                fontWeight: FontWeight.bold,
                                color: isOverBudget
                                    ? AppTheme.danger
                                    : (isDark
                                        ? AppTheme.textDark
                                        : AppTheme.textPrimary),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Responsive.hp(context, 0.8)),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: spendingProgress,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOverBudget ? AppTheme.danger : statusColor,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: Responsive.hp(context, 1)),

                    // ✅ NEW: Current Month Info
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding:
                                EdgeInsets.all(Responsive.wp(context, 2.5)),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: Responsive.sp(context, 10),
                                      color: AppTheme.primary,
                                    ),
                                    SizedBox(width: Responsive.wp(context, 1)),
                                    Text(
                                      'This Month',
                                      style: TextStyle(
                                        fontSize: Responsive.sp(context, 10),
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: Responsive.hp(context, 0.5)),
                                Text(
                                  '${settingsProvider.formatCurrency(currentMonthSpent)} / ${settingsProvider.formatCurrency(multiBudget.monthlyAmount)}',
                                  style: TextStyle(
                                    fontSize: Responsive.sp(context, 12),
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppTheme.textDark
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: Responsive.wp(context, 2)),
                        Expanded(
                          child: Container(
                            padding:
                                EdgeInsets.all(Responsive.wp(context, 2.5)),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: Responsive.sp(context, 10),
                                      color: statusColor,
                                    ),
                                    SizedBox(width: Responsive.wp(context, 1)),
                                    Text(
                                      'Days Left',
                                      style: TextStyle(
                                        fontSize: Responsive.sp(context, 10),
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: Responsive.hp(context, 0.5)),
                                Text(
                                  '${multiBudget.daysRemaining} days',
                                  style: TextStyle(
                                    fontSize: Responsive.sp(context, 12),
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppTheme.textDark
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          // "View All" button if more than 2
          if (activeMultiBudgets.length > 2)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BudgetHistoryScreen(),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: Responsive.hp(context, 1.2),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF34C759).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View All ${activeMultiBudgets.length} Multi-Month Budgets',
                      style: TextStyle(
                        fontSize: Responsive.sp(context, 13),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF34C759),
                      ),
                    ),
                    SizedBox(width: Responsive.wp(context, 2)),
                    Icon(
                      Icons.arrow_forward,
                      size: Responsive.sp(context, 16),
                      color: const Color(0xFF34C759),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
