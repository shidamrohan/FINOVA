import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/slide_animation.dart';
import '../../widgets/premium_empty_state.dart';
import 'expense_details_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _selectedFilter = 'all';
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Consumer3<ExpenseProvider, CategoryProvider, SettingsProvider>(
          builder: (context, expenseProvider, categoryProvider,
              settingsProvider, _) {
            final allExpenses = expenseProvider.expenses
                .where((e) =>
                    e.date.month == _selectedMonth.month &&
                    e.date.year == _selectedMonth.year)
                .toList();
            final filteredExpenses = _selectedFilter == 'all'
                ? allExpenses
                : allExpenses
                    .where((e) => e.categoryId == _selectedFilter)
                    .toList();

            final monthTotal = expenseProvider.getTotalByMonth(_selectedMonth);

            return CustomScrollView(
              slivers: [
                _buildHeader(context, isDark),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      SizedBox(height: Responsive.hp(context, 2)),

                      // Animated Month Selector
                      SlideInAnimation(
                        delay: 0,
                        child: _buildMonthSelector(context, isDark),
                      ),

                      SizedBox(height: Responsive.hp(context, 2)),

                      // Animated Total Card
                      SlideInAnimation(
                        delay: 100,
                        child: _buildTotalCard(
                          context,
                          isDark,
                          monthTotal,
                          settingsProvider,
                          allExpenses.length,
                        ),
                      ),

                      SizedBox(height: Responsive.hp(context, 2)),

                      // Animated Category Filter
                      SlideInAnimation(
                        delay: 200,
                        child: _buildCategoryFilter(
                            context, isDark, categoryProvider),
                      ),

                      SizedBox(height: Responsive.hp(context, 2)),
                    ],
                  ),
                ),
                if (filteredExpenses.isEmpty)
                  SliverFillRemaining(
                    child: PremiumEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: _selectedFilter == 'all'
                          ? 'No Expenses Yet'
                          : 'No Expenses in This Category',
                      subtitle: _selectedFilter == 'all'
                          ? 'Start tracking your expenses\nto manage your budget better'
                          : 'Try selecting a different category',
                      iconColor: AppTheme.danger,
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return SlideInAnimation(
                          delay: 300 + (index * 50),
                          child: _buildExpenseCard(
                            context,
                            filteredExpenses[index],
                            isDark,
                            categoryProvider,
                            settingsProvider,
                          ),
                        );
                      },
                      childCount: filteredExpenses.length,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(height: Responsive.hp(context, 10)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return SliverAppBar(
      floating: true,
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.wp(context, 2)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF3B30), Color(0xFFFF6B6B)],
              ),
              borderRadius:
                  BorderRadius.circular(Responsive.borderRadius(context, 10)),
            ),
            child: Icon(
              Icons.receipt_long,
              color: Colors.white,
              size: Responsive.sp(context, 20),
            ),
          ),
          SizedBox(width: Responsive.wp(context, 2)),
          Text(
            'Expenses',
            style: TextStyle(
              fontSize: Responsive.sp(context, 22),
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, bool isDark) {
    final isCurrentMonth = _selectedMonth.month == DateTime.now().month &&
        _selectedMonth.year == DateTime.now().year;

    return PremiumCard(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.wp(context, 4),
        vertical: Responsive.hp(context, 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Month Button
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppTheme.primary.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(Responsive.borderRadius(context, 10)),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month - 1,
                  );
                });
              },
              icon: Icon(
                Icons.chevron_left,
                color: AppTheme.primary,
                size: Responsive.sp(context, 24),
              ),
            ),
          ),

          // Month Display
          Expanded(
            child: Column(
              children: [
                Text(
                  DateFormat('MMMM').format(_selectedMonth),
                  style: TextStyle(
                    fontSize: Responsive.sp(context, 18),
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                Text(
                  DateFormat('yyyy').format(_selectedMonth),
                  style: TextStyle(
                    fontSize: Responsive.sp(context, 13),
                    color: isDark
                        ? AppTheme.textMutedDark
                        : AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Next Month Button
          Container(
            decoration: BoxDecoration(
              color: isCurrentMonth
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.grey.withValues(alpha: 0.1))
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppTheme.primary.withValues(alpha: 0.1)),
              borderRadius:
                  BorderRadius.circular(Responsive.borderRadius(context, 10)),
            ),
            child: IconButton(
              onPressed: isCurrentMonth
                  ? null
                  : () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                        );
                      });
                    },
              icon: Icon(
                Icons.chevron_right,
                color: isCurrentMonth ? Colors.grey : AppTheme.primary,
                size: Responsive.sp(context, 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(
    BuildContext context,
    bool isDark,
    double total,
    SettingsProvider settingsProvider,
    int expenseCount,
  ) {
    return GradientCard(
      gradientColors: const [Color(0xFFFF3B30), Color(0xFFFF6B6B)],
      padding: EdgeInsets.all(Responsive.wp(context, 6)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(Responsive.wp(context, 1.5)),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.trending_down,
                        color: Colors.white,
                        size: Responsive.sp(context, 16),
                      ),
                    ),
                    SizedBox(width: Responsive.wp(context, 2)),
                    Text(
                      'Total Expenses',
                      style: TextStyle(
                        fontSize: Responsive.sp(context, 14),
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                SizedBox(height: Responsive.hp(context, 1.5)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    settingsProvider.formatCurrency(total),
                    style: TextStyle(
                      fontSize: Responsive.sp(context, 36),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
                SizedBox(height: Responsive.hp(context, 0.5)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.wp(context, 2),
                    vertical: Responsive.hp(context, 0.3),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$expenseCount transaction${expenseCount != 1 ? "s" : ""}',
                    style: TextStyle(
                      fontSize: Responsive.sp(context, 11),
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(Responsive.wp(context, 5)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius:
                  BorderRadius.circular(Responsive.borderRadius(context, 20)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: Responsive.sp(context, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(
    BuildContext context,
    bool isDark,
    CategoryProvider categoryProvider,
  ) {
    return SizedBox(
      height: Responsive.hp(context, 5.5),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: Responsive.wp(context, 4)),
        children: [
          _buildFilterChip(
              context, 'All', 'all', isDark, Icons.grid_view, null),
          SizedBox(width: Responsive.wp(context, 2.5)),
          ...categoryProvider.categories.map((category) {
            return Padding(
              padding: EdgeInsets.only(right: Responsive.wp(context, 2.5)),
              child: _buildFilterChip(
                context,
                category.name,
                category.id,
                isDark,
                IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                Color(category.colorValue),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String value,
    bool isDark,
    IconData? icon,
    Color? categoryColor,
  ) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.wp(context, 4),
          vertical: Responsive.hp(context, 1),
        ),
        decoration: BoxDecoration(
          gradient: isSelected && categoryColor != null
              ? LinearGradient(
                  colors: [categoryColor, categoryColor.withValues(alpha: 0.7)],
                )
              : null,
          color: isSelected && categoryColor == null
              ? AppTheme.primary
              : (isSelected
                  ? null
                  : (isDark ? AppTheme.surfaceDark : Colors.white)),
          borderRadius:
              BorderRadius.circular(Responsive.borderRadius(context, 25)),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade300),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (categoryColor ?? AppTheme.primary).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: Responsive.sp(context, 16),
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppTheme.textMutedDark : Colors.grey.shade700),
              ),
              SizedBox(width: Responsive.wp(context, 1.5)),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.sp(context, 13),
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppTheme.textMutedDark : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(
    BuildContext context,
    dynamic expense,
    bool isDark,
    CategoryProvider categoryProvider,
    SettingsProvider settingsProvider,
  ) {
    final category = categoryProvider.getCategoryById(expense.categoryId);
    final hasNote = expense.note != null && expense.note!.isNotEmpty;

    return AnimatedCard(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpenseDetailsScreen(expense: expense),
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
            // Category Icon
            Container(
              padding: EdgeInsets.all(Responsive.wp(context, 3.5)),
              decoration: BoxDecoration(
                gradient: category != null
                    ? LinearGradient(
                        colors: [
                          Color(category.colorValue).withValues(alpha: 0.2),
                          Color(category.colorValue).withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: category == null ? Colors.grey.shade100 : null,
                borderRadius: BorderRadius.circular(
                  Responsive.borderRadius(context, 14),
                ),
                border: Border.all(
                  color: category != null
                      ? Color(category.colorValue).withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Icon(
                category != null
                    ? IconData(category.iconCodePoint,
                        fontFamily: 'MaterialIcons')
                    : Icons.help_outline,
                color:
                    category != null ? Color(category.colorValue) : Colors.grey,
                size: Responsive.sp(context, 24),
              ),
            ),

            SizedBox(width: Responsive.wp(context, 3.5)),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.name ?? 'Unknown',
                    style: TextStyle(
                      fontSize: Responsive.sp(context, 16),
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Responsive.hp(context, 0.5)),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: Responsive.sp(context, 11),
                        color: isDark
                            ? AppTheme.textMutedDark
                            : AppTheme.textSecondary,
                      ),
                      SizedBox(width: Responsive.wp(context, 1)),
                      Flexible(
                        child: Text(
                          DateFormat('MMM dd, yyyy • HH:mm')
                              .format(expense.date),
                          style: TextStyle(
                            fontSize: Responsive.sp(context, 11),
                            color: isDark
                                ? AppTheme.textMutedDark
                                : AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (hasNote) ...[
                    SizedBox(height: Responsive.hp(context, 0.5)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.wp(context, 2),
                        vertical: Responsive.hp(context, 0.3),
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.note,
                            size: Responsive.sp(context, 10),
                            color: isDark
                                ? AppTheme.textMutedDark
                                : AppTheme.textSecondary,
                          ),
                          SizedBox(width: Responsive.wp(context, 1)),
                          Flexible(
                            child: Text(
                              expense.note!,
                              style: TextStyle(
                                fontSize: Responsive.sp(context, 10),
                                color: isDark
                                    ? AppTheme.textMutedDark
                                    : AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(width: Responsive.wp(context, 2)),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    settingsProvider.formatCurrency(expense.amount),
                    style: TextStyle(
                      fontSize: Responsive.sp(context, 19),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF3B30),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.hp(context, 0.5)),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? AppTheme.textMutedDark : Colors.grey.shade400,
                  size: Responsive.sp(context, 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
