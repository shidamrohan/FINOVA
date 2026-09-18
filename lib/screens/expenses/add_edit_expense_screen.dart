import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddEditExpenseScreen({super.key, this.expense});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  String _amount = '0';
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      // Pre-fill with amount converted to the current display currency
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final settingsProvider =
            Provider.of<SettingsProvider>(context, listen: false);
        final displayAmount =
            settingsProvider.convertFromBase(widget.expense!.amount);
        setState(() {
          // Remove trailing zeros for a clean display (e.g. 200.0 → "200")
          _amount = displayAmount == displayAmount.truncate()
              ? displayAmount.toInt().toString()
              : displayAmount.toStringAsFixed(2);
        });
      });
      _selectedCategoryId = widget.expense!.categoryId;
      _selectedDate = widget.expense!.date;
      _noteController.text = widget.expense!.note ?? '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onNumberTap(String value) {
    setState(() {
      if (_amount == '0') {
        _amount = value;
      } else {
        _amount += value;
      }
    });
  }

  void _onDecimalTap() {
    setState(() {
      if (!_amount.contains('.')) {
        _amount += '.';
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  void _onSave() async {
    // Validate amount
    if (_amount == '0' || _amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text('Please enter an amount'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validate category
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text('Please select a category'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final expenseProvider = context.read<ExpenseProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    // Convert entered amount (in display currency) → INR base for storage
    final enteredAmount = double.parse(_amount);
    final baseAmount =
        settingsProvider.convertToBase(enteredAmount, settingsProvider.currencyCode);

    // Create expense
    final expense = Expense(
      id: widget.expense?.id ?? 'exp_${DateTime.now().millisecondsSinceEpoch}',
      amount: baseAmount, // Always stored in INR
      categoryId: _selectedCategoryId!,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    try {
      // Save to Firestore
      if (widget.expense == null) {
        await expenseProvider.addExpense(expense);
      } else {
        await expenseProvider.updateExpense(
            expense);
      }

      // ✅ Navigate back with success result
      if (!mounted) return;
      Navigator.pop(context, {
        'success': true,
        'amount': enteredAmount,
        'isEdit': widget.expense != null,
      });
    } catch (e) {
      // ❌ Show error and stay on screen
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: ${e.toString()}')),
            ],
          ),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: _onSave,
          ),
        ),
      );
      print('❌ Error saving expense: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Consumer<SettingsProvider>(
          builder: (context, settingsProvider, _) {
            return Column(
              children: [
                _buildHeader(isDark),
                _buildAmountDisplay(isDark, settingsProvider),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildCategorySelector(isDark),
                        const SizedBox(height: 20),
                        _buildDatePicker(isDark),
                        const SizedBox(height: 20),
                        _buildNoteInput(isDark),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _buildKeypad(isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              widget.expense == null ? 'Add Expense' : 'Edit Expense',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay(bool isDark, SettingsProvider settingsProvider) {
    String displayAmount = _amount;
    if (_amount == '0') {
      displayAmount = '0.00';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet,
            size: 64,
            color: AppTheme.danger,
          ),
          const SizedBox(height: 24),
          Text(
            'Expense Amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.textMutedDark : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  settingsProvider.currency,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.danger,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                displayAmount,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.danger,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: isDark ? AppTheme.textMutedDark : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Consumer<CategoryProvider>(
          builder: (context, categoryProvider, _) {
            final categories = categoryProvider.categories;

            if (categories.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Loading categories...',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.textMutedDark
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: categories.map((category) {
                final isSelected = _selectedCategoryId == category.id;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = category.id;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(category.colorValue).withValues(alpha: 0.2)
                          : (isDark
                              ? AppTheme.surfaceDark
                              : AppTheme.surfaceLight),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Color(category.colorValue)
                            : (isDark
                                ? Colors.transparent
                                : Colors.grey.shade200),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          IconData(
                            category.iconCodePoint,
                            fontFamily: 'MaterialIcons',
                          ),
                          color: Color(category.colorValue),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isDark
                                ? AppTheme.textDark
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDatePicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DATE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: isDark ? AppTheme.textMutedDark : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );

            if (pickedDate != null) {
              setState(() {
                _selectedDate = pickedDate;
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.transparent : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppTheme.danger,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOTE (OPTIONAL)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: isDark ? AppTheme.textMutedDark : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.transparent : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _noteController,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Add a note',
              hintStyle: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
              icon: const Icon(
                Icons.note,
                color: AppTheme.danger,
                size: 20,
              ),
            ),
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
            ),
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildKeypad(bool isDark) {
    final keypadBgColor =
        isDark ? const Color(0xFF0D1A12) : Colors.grey.shade100;
    final keyBgColor = isDark ? AppTheme.surfaceDark : Colors.white;
    final keyTextColor = isDark ? AppTheme.textDark : AppTheme.textPrimary;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: keypadBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(
            height: 240,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                          child: _buildKeypadButton(
                              '1', keyBgColor, keyTextColor)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildKeypadButton(
                              '2', keyBgColor, keyTextColor)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildKeypadButton(
                              '3', keyBgColor, keyTextColor)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildKeypadBackspace(isDark)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                          child: _buildKeypadButton(
                              '4', keyBgColor, keyTextColor)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildKeypadButton(
                              '5', keyBgColor, keyTextColor)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildKeypadButton(
                              '6', keyBgColor, keyTextColor)),
                      const SizedBox(width: 8),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                          child: _buildKeypadButton(
                              '7', keyBgColor, keyTextColor)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildKeypadButton(
                              '8', keyBgColor, keyTextColor)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildKeypadButton(
                              '9', keyBgColor, keyTextColor)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildKeypadSave(isDark)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                          child: _buildKeypadButton(
                              '.', keyBgColor, keyTextColor,
                              onTap: _onDecimalTap)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildKeypadButton(
                              '0', keyBgColor, keyTextColor)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildKeypadButton(
                              '00', keyBgColor, keyTextColor)),
                      const SizedBox(width: 8),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String label, Color bgColor, Color textColor,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => _onNumberTap(label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadBackspace(bool isDark) {
    return InkWell(
      onTap: _onBackspace,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF15251C) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadSave(bool isDark) {
    return InkWell(
      onTap: _onSave,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check,
              color: Colors.white,
              size: 28,
            ),
            SizedBox(height: 2),
            Text(
              'SAVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
