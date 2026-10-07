import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/category.dart';
import '../../models/expense.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import 'add_edit_expense_screen.dart';

class ExpenseDetailsScreen extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailsScreen({super.key, required this.expense});

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
            final category =
                categoryProvider.getCategoryById(expense.categoryId);

            return CustomScrollView(
              slivers: [
                _buildHeader(context, isDark, expenseProvider),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAmountCard(
                          isDark,
                          settingsProvider,
                          category?.name ?? 'Unknown',
                          category != null
                              ? IconData(
                                  category.iconCodePoint,
                                  fontFamily: 'MaterialIcons',
                                )
                              : Icons.category,
                          category != null
                              ? Color(category.colorValue)
                              : AppTheme.primary,
                        ),
                        const SizedBox(height: 24),
                        _buildInfoCard(isDark, category, settingsProvider),
                        if (expense.note != null &&
                            expense.note!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildNoteCard(isDark),
                        ],
                      ],
                    ),
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
      BuildContext context, bool isDark, ExpenseProvider expenseProvider) {
    return SliverAppBar(
      floating: true,
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back,
          color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
        ),
      ),
      title: Text(
        'Expense Details',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditExpenseScreen(expense: expense),
              ),
            );
          },
          icon: Icon(
            Icons.edit,
            color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
          ),
        ),
        IconButton(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
                title: Text(
                  'Delete Expense',
                  style: TextStyle(
                    color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                  ),
                ),
                content: Text(
                  'Are you sure you want to delete this expense?',
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.textMutedDark
                        : AppTheme.textSecondary,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: AppTheme.danger),
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true && context.mounted) {
              await expenseProvider.deleteExpense(expense.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Expense deleted'),
                      ],
                    ),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.delete, color: AppTheme.danger),
        ),
      ],
    );
  }

  Widget _buildAmountCard(
    bool isDark,
    SettingsProvider settingsProvider,
    String categoryName,
    IconData categoryIcon,
    Color categoryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            categoryColor.withValues(alpha: 0.2),
            categoryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(categoryIcon, size: 32, color: categoryColor),
          ),
          const SizedBox(height: 16),
          Text(
            settingsProvider.formatCurrency(expense.amount),
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: categoryColor,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            categoryName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    bool isDark,
    Category? category,
    SettingsProvider settingsProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            'Date & Time',
            DateFormat('EEEE, MMMM dd, yyyy • hh:mm a').format(expense.date),
            Icons.calendar_today,
            AppTheme.primary,
            isDark,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'Category',
            category?.name ?? 'Unknown',
            category != null
                ? IconData(category.iconCodePoint, fontFamily: 'MaterialIcons')
                : Icons.category,
            category != null ? Color(category.colorValue) : AppTheme.primary,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDark ? AppTheme.textMutedDark : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.note,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Note',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            expense.note!,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.textMutedDark : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
