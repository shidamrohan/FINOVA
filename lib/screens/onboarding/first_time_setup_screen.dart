import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/settings_provider.dart';

import '/main.dart';

class FirstTimeSetupScreen extends StatefulWidget {
  const FirstTimeSetupScreen({super.key});

  @override
  State<FirstTimeSetupScreen> createState() => _FirstTimeSetupScreenState();
}

class _FirstTimeSetupScreenState extends State<FirstTimeSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedCurrency = '₹';
  double _monthlyBudget = 5000.0;

  final List<Map<String, String>> _currencies = [
    {'symbol': '₹', 'name': 'Indian Rupee', 'code': 'INR'},
    {'symbol': '\$', 'name': 'US Dollar', 'code': 'USD'},
    {'symbol': '€', 'name': 'Euro', 'code': 'EUR'},
    {'symbol': '£', 'name': 'British Pound', 'code': 'GBP'},
    {'symbol': '¥', 'name': 'Japanese Yen', 'code': 'JPY'},
    {'symbol': '₽', 'name': 'Russian Ruble', 'code': 'RUB'},
    {'symbol': 'R\$', 'name': 'Brazilian Real', 'code': 'BRL'},
    {'symbol': 'C\$', 'name': 'Canadian Dollar', 'code': 'CAD'},
    {'symbol': 'A\$', 'name': 'Australian Dollar', 'code': 'AUD'},
    {'symbol': 'Fr', 'name': 'Swiss Franc', 'code': 'CHF'},
    {'symbol': 'kr', 'name': 'Swedish Krona', 'code': 'SEK'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeSetup();
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeSetup() async {
    final settingsProvider = context.read<SettingsProvider>();

    // Save settings
    await settingsProvider.setCurrency(_selectedCurrency);
    await settingsProvider.setMonthlyBudget(_monthlyBudget);
    await settingsProvider.setFirstTimeLaunch(false);

    // Categories are auto-loaded in CategoryProvider constructor

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildWelcomePage(isDark),
                  _buildCurrencyPage(isDark),
                  _buildBudgetPage(isDark),
                ],
              ),
            ),
            _buildBottomBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.account_balance_wallet,
            size: 120,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 48),
          Text(
            'Welcome to\nExpense Tracker',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Track your expenses, manage bills,\nand stay on budget',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppTheme.textMutedDark : AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          _buildFeatureItem(
            Icons.trending_down,
            'Track Expenses',
            'Monitor your daily spending',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.receipt_long,
            'Manage Bills',
            'Never miss a payment',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.savings,
            'Set Budgets',
            'Stay within your limits',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
      IconData icon, String title, String subtitle, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isDark ? AppTheme.textMutedDark : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyPage(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Icon(
            Icons.attach_money,
            size: 80,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Select Your Currency',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose the currency you want to use',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.textMutedDark : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: _currencies.length,
              itemBuilder: (context, index) {
                final currency = _currencies[index];
                final isSelected = _selectedCurrency == currency['symbol'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : (isDark
                              ? Colors.transparent
                              : Colors.grey.shade200),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        _selectedCurrency = currency['symbol']!;
                      });
                    },
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.15)
                            : (isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          currency['symbol']!,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppTheme.primary
                                : (isDark
                                    ? AppTheme.textDark
                                    : AppTheme.textPrimary),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      currency['name']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? AppTheme.textDark : AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      currency['code']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.textMutedDark
                            : AppTheme.textSecondary,
                      ),
                    ),
                    trailing: isSelected
                        ? Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetPage(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          const Icon(
            Icons.savings,
            size: 80,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Set Your Monthly Budget',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'How much do you plan to spend each month?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.textMutedDark : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.2),
                  AppTheme.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Monthly Budget',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppTheme.textMutedDark
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _selectedCurrency,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _monthlyBudget.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Slider(
            value: _monthlyBudget,
            min: 1000,
            max: 50000,
            divisions: 98,
            activeColor: AppTheme.primary,
            inactiveColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            onChanged: (value) {
              setState(() {
                _monthlyBudget = value;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_selectedCurrency 1,000',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.textMutedDark
                        : AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '$_selectedCurrency 50,000',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.textMutedDark
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'You can always change this later in settings',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppTheme.primary
                      : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousPage,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (_currentPage > 0) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage == 2 ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.backgroundDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
