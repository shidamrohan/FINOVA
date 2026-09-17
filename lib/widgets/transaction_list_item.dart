import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/expense.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';

class TransactionListItem extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionListItem({
    super.key,
    required this.expense,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<CategoryProvider, SettingsProvider>(
      builder: (context, categoryProvider, settingsProvider, _) {
        final category = categoryProvider.getCategoryById(expense.categoryId);

        return Dismissible(
          key: Key(expense.id),
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.danger,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
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
          },
          onDismissed: (direction) {
            if (onDelete != null) {
              onDelete!();
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: ListTile(
              onTap: onTap,
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: category != null
                      ? Color(category.colorValue).withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  category != null
                      ? IconData(category.iconCodePoint,
                          fontFamily: 'MaterialIcons')
                      : Icons.help_outline,
                  color: category != null
                      ? Color(category.colorValue)
                      : Colors.grey,
                  size: 24,
                ),
              ),
              title: Text(
                category?.name ?? 'Unknown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                ),
              ),
              subtitle: expense.note != null && expense.note!.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        expense.note!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppTheme.textMutedDark
                              : AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : null,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    settingsProvider.formatCurrency(expense.amount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.danger,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(expense.date),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.textMutedDark
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
