import 'dart:async';
import 'services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'providers/settings_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/money_note_provider.dart';
import 'providers/bill_provider.dart';
import 'providers/category_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/income_provider.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/expenses/expenses_screen.dart';
import 'screens/expenses/add_edit_expense_screen.dart';
import 'screens/money_notes/money_notes_screen.dart';
import 'screens/money_notes/add_edit_money_note_screen.dart';
import 'screens/bills/bills_screen.dart';
import 'screens/bills/add_edit_bill_screen.dart';
import 'screens/stats/stats_screen.dart';
import 'providers/savings_goal_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/app_state_provider.dart';
import 'services/notification_service.dart';

// ✅ Global keys
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<_MainNavigationScreenState> mainNavigationKey =
    GlobalKey<_MainNavigationScreenState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Read credentials from --dart-define-from-file=.env
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  assert(
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty,
    '\n\n❌ Missing credentials!\n'
    'Run with: flutter run --dart-define-from-file=.env\n'
    'Copy .env.example → .env and fill in your values.\n',
  );

  // ✅ Initialize Supabase
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    debugPrint('✅ Supabase initialized successfully!');
  } catch (e) {
    debugPrint('⚠️ Supabase initialization error: $e — continuing anyway');
  }

  runApp(
    MultiProvider(
      providers: [
        // ✅ 1. Provide SupabaseService FIRST
        Provider<SupabaseService>(
          create: (_) => SupabaseService(),
        ),

        // ✅ 2. Providers that need SupabaseService
        ChangeNotifierProvider(
          create: (context) =>
              SettingsProvider(context.read<SupabaseService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => IncomeProvider(context.read<SupabaseService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              SavingsGoalProvider(context.read<SupabaseService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ExpenseProvider(context.read<SupabaseService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              MoneyNoteProvider(context.read<SupabaseService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => BillProvider(context.read<SupabaseService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => BudgetProvider(context.read<SupabaseService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => DebtProvider(context.read<SupabaseService>()),
        ),

        // ✅ AppStateProvider — coordinates connectivity + global refresh
        ChangeNotifierProvider(
          create: (context) => AppStateProvider(
            expenseProvider: context.read<ExpenseProvider>(),
            incomeProvider: context.read<IncomeProvider>(),
            billProvider: context.read<BillProvider>(),
            budgetProvider: context.read<BudgetProvider>(),
            savingsGoalProvider: context.read<SavingsGoalProvider>(),
            debtProvider: context.read<DebtProvider>(),
          ),
        ),

        // ✅ 3. Notification providers
        Provider<NotificationService>(
          create: (_) => NotificationService(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              NotificationProvider(context.read<NotificationService>()),
        ),

        // ✅ 4. Providers that don't need SupabaseService
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// ==================== MY APP ====================

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isCheckingAuth = true;
  bool? _isFirstTimeLaunch;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _loadLaunchState();
    _initializeAuth();
  }

  Future<void> _loadLaunchState() async {
    final settingsProvider = context.read<SettingsProvider>();
    final isFirstTime = await settingsProvider.isFirstTimeLaunch();
    if (!mounted) return;
    setState(() {
      _isFirstTimeLaunch = isFirstTime;
    });
  }

  // ✅ Refresh all data providers after login — delegated to AppStateProvider
  Future<void> _refreshAllProviders() async {
    // Small delay to ensure auth token is fully propagated
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    debugPrint('🔄 Refreshing all providers after login...');
    await context.read<AppStateProvider>().refreshAll();
    debugPrint('✅ All providers refreshed');
  }

  // ✅ Initialize and listen to auth state
  Future<void> _initializeAuth() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      debugPrint('✅ Found existing session for: ${session.user.email}');
      debugPrint('✅ User ID: ${session.user.id}');
      // Ensure providers hydrate on cold start with an existing session.
      unawaited(_refreshAllProviders());
    } else {
      debugPrint('❌ No existing session found');
    }

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (session != null) {
        debugPrint(
            '🔄 Auth state changed - User logged in: ${session.user.email}');
        debugPrint('🔄 User ID: ${session.user.id}');
      } else {
        debugPrint('🔄 Auth state changed - User logged out');
      }

      if (event == AuthChangeEvent.signedIn) {
        unawaited(_refreshAllProviders());
        if (session != null && session.user.email != null) {
          try {
            final notificationProvider = context.read<NotificationProvider>();
            notificationProvider.sendLoginAlert(
              email: session.user.email!,
              deviceInfo: 'Mobile Device',
            );
          } catch (e) {
            debugPrint('⚠️ Could not send login alert: $e');
          }
        }
      }

      if (mounted) {
        setState(() {});
      }
    });

    if (!mounted) return;
    setState(() {
      _isCheckingAuth = false;
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, AuthProvider>(
      builder: (context, settingsProvider, authProvider, _) {
        return MaterialApp(
          title: 'Finova',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode:
              settingsProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          locale: settingsProvider.locale,
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('en', 'GB'),
            Locale('es'),
            Locale('fr'),
            Locale('de'),
            Locale('hi'),
          ],
          builder: (context, child) {
            final scale = settingsProvider.textScaleFactor;
            return MediaQuery(
              // ignore: deprecated_member_use
              data: MediaQuery.of(context).copyWith(textScaleFactor: scale),
              child: child!,
            );
          },
          home: (_isCheckingAuth || _isFirstTimeLaunch == null)
              ? const SplashScreen()
              : Builder(
                  builder: (context) {
                    final isLoggedIn =
                        Supabase.instance.client.auth.currentUser != null;

                    if (!isLoggedIn) {
                      return const LoginScreen();
                    }

                    return MainNavigationScreen(key: mainNavigationKey);
                  },
                ),
        );
      },
    );
  }
}

// ==================== MAIN NAVIGATION ====================

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final Set<int> _loadedTabs = {0};
  final List<Widget?> _cachedScreens = List<Widget?>.filled(5, null);

  Widget _buildScreen(int index) {
    _cachedScreens[index] ??= [
      const HomeScreen(),
      const ExpensesScreen(),
      const MoneyNotesScreen(),
      const BillsScreen(),
      const StatsScreen(),
    ][index];
    return _cachedScreens[index]!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuthStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          unawaited(_runStartupNotificationChecks());
        }
      });
    });
  }

  /// Check bills due today and savings goals behind schedule on app open
  Future<void> _runStartupNotificationChecks() async {
    try {
      final billProvider = context.read<BillProvider>();
      final savingsGoalProvider = context.read<SavingsGoalProvider>();
      await Future.wait([
        billProvider.checkBillsDueToday(),
        savingsGoalProvider.checkAllGoalsBehindSchedule(),
      ]);
      debugPrint('✅ Startup notification checks completed');
    } catch (e) {
      debugPrint('⚠️ Startup notification check error: $e');
    }
  }

  // ✅ Check authentication status
  void _checkAuthStatus() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      debugPrint('✅ MainNavigationScreen: User authenticated');
      debugPrint('📧 Email: ${user.email}');
      debugPrint('🆔 ID: ${user.id}');
    } else {
      debugPrint('❌ MainNavigationScreen: No user found');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 App resumed');
      _checkAuthStatus();
    }
  }

  /// ✅ PUBLIC METHOD: Navigate to specific tab from outside
  void navigateToTab(int index) {
    if (index >= 0 && index < _cachedScreens.length && mounted) {
      setState(() {
        _currentIndex = index;
        _loadedTabs.add(index);
      });
    }
  }

  /// ✅ PUBLIC METHOD: Get current tab index
  int get currentTabIndex => _currentIndex;

  void _onFabPressed() async {
    // ✅ Check auth before adding
    final user = Supabase.instance.client.auth.currentUser;
    debugPrint('🔘 FAB pressed - User: ${user?.email ?? "NOT LOGGED IN"}');

    if (user == null) {
      _showErrorSnackBar('Please login to add items');
      return;
    }

    FocusScope.of(context).unfocus();

    switch (_currentIndex) {
      case 0:
      case 1:
        await _addExpense();
        break;
      case 2:
        await _addMoneyNote();
        break;
      case 3:
        await _addBill();
        break;
      case 4:
        _showQuickActionSheet();
        break;
    }
  }

  Future<void> _addExpense() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditExpenseScreen(),
      ),
    );

    if (result != null && result['success'] == true && mounted) {
      final settingsProvider = context.read<SettingsProvider>();
      final isEdit = result['isEdit'] ?? false;
      final amount = result['amount'] ?? 0.0;

      _showSuccessSnackBar(
        icon: Icons.check_circle,
        message:
            '${isEdit ? "Expense updated" : "Expense added"}: ${settingsProvider.formatCurrency(amount)}',
      );
    }
  }

  Future<void> _addMoneyNote() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditMoneyNoteScreen(),
      ),
    );

    if (result != null && result['success'] == true && mounted) {
      _showSuccessSnackBar(
        icon: Icons.check_circle,
        message: 'Money Note saved!',
      );
    }
  }

  Future<void> _addBill() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditBillScreen(),
      ),
    );

    if (result != null && result['success'] == true && mounted) {
      _showSuccessSnackBar(
        icon: Icons.check_circle,
        message: 'Bill saved!',
      );
    }
  }

  void _showSuccessSnackBar({
    required IconData icon,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showQuickActionSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textDark : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _buildQuickActionTile(
                icon: Icons.receipt_long,
                iconColor: AppTheme.primary,
                title: 'Add Expense',
                onTap: () {
                  Navigator.pop(context);
                  _addExpense();
                },
              ),
              const SizedBox(height: 8),
              _buildQuickActionTile(
                icon: Icons.note,
                iconColor: AppTheme.success,
                title: 'Add Money Note',
                onTap: () {
                  Navigator.pop(context);
                  _addMoneyNote();
                },
              ),
              const SizedBox(height: 8),
              _buildQuickActionTile(
                icon: Icons.receipt,
                iconColor: Colors.blue,
                title: 'Add Bill',
                onTap: () {
                  Navigator.pop(context);
                  _addBill();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List<Widget>.generate(_cachedScreens.length, (index) {
          if (_loadedTabs.contains(index)) {
            return _buildScreen(index);
          }
          return const SizedBox.shrink();
        }),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _loadedTabs.add(index);
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor:
              isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.note_outlined),
              activeIcon: Icon(Icons.note),
              label: 'Notes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Bills',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Stats',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        elevation: 6,
        backgroundColor: AppTheme.primary,
        child: const Icon(
          Icons.add,
          size: 32,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ==================== HELPER FUNCTIONS ====================

void navigateToTab(int index) {
  mainNavigationKey.currentState?.navigateToTab(index);
}

int? getCurrentTabIndex() {
  return mainNavigationKey.currentState?.currentTabIndex;
}
