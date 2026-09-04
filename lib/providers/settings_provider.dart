import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../services/currency_service.dart';

class SettingsProvider with ChangeNotifier {
  final SupabaseService _supabaseService;
  final CurrencyService _currencyService = CurrencyService();

  String _currency = '₹';
  String _currencyCode = 'INR';
  bool _isDarkMode = false;
  double _monthlyBudget = 5000.0;
  int _monthStartDay = 1;
  String? _userId;

  // ✅ NEW: Font size and language settings
  String _fontSize = 'Medium'; // Small, Medium, Large, Extra Large
  String _language = 'English (US)'; // Selected language
  String _privacyAccepted = ''; // Privacy policy version
  String _termsAccepted = ''; // Terms of service version

  // Live exchange rates (base: INR)
  Map<String, double> _liveRates = {};
  bool _ratesLoaded = false;
  DateTime? _ratesLastUpdated;

  String get currency => _currency;
  String get currencySymbol => _currency;
  String get currencyCode => _currencyCode;
  bool get isDarkMode => _isDarkMode;
  double get monthlyBudget => _monthlyBudget;
  int get monthStartDay => _monthStartDay;
  String? get userId => _userId;
  bool get ratesLoaded => _ratesLoaded;
  DateTime? get ratesLastUpdated => _ratesLastUpdated;

  // ✅ NEW: Getters for font size and language
  String get fontSize => _fontSize;
  String get language => _language;
  String get privacyAccepted => _privacyAccepted;
  String get termsAccepted => _termsAccepted;

  double get textScaleFactor {
    switch (_fontSize) {
      case 'Small':
        return 0.85;
      case 'Large':
        return 1.15;
      case 'Extra Large':
        return 1.30;
      case 'Medium':
      default:
        return 1.0;
    }
  }

  Locale get locale {
    switch (_language) {
      case 'Spanish':
        return const Locale('es');
      case 'French':
        return const Locale('fr');
      case 'German':
        return const Locale('de');
      case 'Hindi':
        return const Locale('hi');
      case 'English (UK)':
        return const Locale('en', 'GB');
      case 'English (US)':
      default:
        return const Locale('en', 'US');
    }
  }

  Map<String, String> get supportedCurrencies => {
        'INR': '₹',
        'USD': '\$',
        'EUR': '€',
        'GBP': '£',
        'JPY': '¥',
        'RUB': '₽',
        'BRL': 'R\$',
        'CAD': 'C\$',
        'AUD': 'A\$',
        'CHF': 'Fr',
        'SEK': 'kr',
      };

  SettingsProvider(this._supabaseService) {
    _loadSettings();
    _loadUserId();
    _loadLiveRates();
  }

  // ✅ FIXED METHOD
  Future<void> _loadUserId() async {
    try {
      _userId = _supabaseService.supabase.auth.currentUser?.id;
      debugPrint('✅ SettingsProvider: User ID loaded: $_userId');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ SettingsProvider: Error loading user ID: $e');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString('currency') ?? '₹';
    _currencyCode = prefs.getString('currencyCode') ?? 'INR';
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _monthlyBudget = prefs.getDouble('monthlyBudget') ?? 5000.0;
    _monthStartDay = prefs.getInt('monthStartDay') ?? 1;

    // ✅ NEW: Load font size, language, and privacy settings
    _fontSize = prefs.getString('fontSize') ?? 'Medium';
    _language = prefs.getString('language') ?? 'English (US)';
    _privacyAccepted = prefs.getString('privacyAccepted') ?? '';
    _termsAccepted = prefs.getString('termsAccepted') ?? '';

    notifyListeners();
  }

  /// Loads (or refreshes) live exchange rates.
  Future<void> _loadLiveRates() async {
    try {
      _liveRates = await _currencyService.getRates();
      _ratesLastUpdated = await _currencyService.getLastUpdated();
      _ratesLoaded = true;
      debugPrint('✅ SettingsProvider: Live rates loaded');
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ SettingsProvider: Failed to load live rates: $e');
    }
  }

  /// Forces a fresh fetch of exchange rates from the network.
  Future<void> refreshRates() async {
    _ratesLoaded = false;
    notifyListeners();
    try {
      _liveRates = await _currencyService.fetchFreshRates();
      _ratesLastUpdated = await _currencyService.getLastUpdated();
      _ratesLoaded = true;
      debugPrint('✅ SettingsProvider: Rates refreshed');
      notifyListeners();
    } catch (e) {
      _ratesLoaded = true;
      notifyListeners();
      debugPrint('⚠️ SettingsProvider: Failed to refresh rates: $e');
    }
  }

  /// Returns live conversion rate from [fromCode] to [toCode].
  /// Falls back to static rates if live rates not loaded.
  double getLiveRate(String fromCode, String toCode) {
    final rates = _ratesLoaded && _liveRates.isNotEmpty
        ? _liveRates
        : _staticRates;
    return CurrencyService.convert(
      amount: 1.0,
      fromCode: fromCode,
      toCode: toCode,
      rates: rates,
    );
  }

  /// Compute a conversion ratio between two currency symbols using live rates.
  double getConversionRatio(String fromSymbol, String toSymbol) {
    final fromCode = _symbolToCode(fromSymbol);
    final toCode = _symbolToCode(toSymbol);
    return getLiveRate(fromCode, toCode);
  }

  static const Map<String, double> _staticRates = {
    'INR': 1.0,
    'USD': 0.01205,
    'EUR': 0.01110,
    'GBP': 0.00950,
    'JPY': 1.810,
    'RUB': 1.108,
    'BRL': 0.06060,
    'CAD': 0.01639,
    'AUD': 0.01852,
    'CHF': 0.01087,
    'SEK': 0.12820,
  };

  String _symbolToCode(String symbol) {
    return supportedCurrencies.entries
        .firstWhere((e) => e.value == symbol,
            orElse: () => const MapEntry('INR', '₹'))
        .key;
  }

  Future<void> setCurrency(String currency) async {
    _currency = currency;
    _currencyCode = _symbolToCode(currency);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
    await prefs.setString('currencyCode', _currencyCode);
    notifyListeners();
  }

  Future<void> updateCurrency(String currencyCode,
      {bool convertValues = false}) async {
    // Amounts are always stored in INR base; only the display currency changes.
    final symbol = supportedCurrencies[currencyCode] ?? '₹';
    await setCurrency(symbol);
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await toggleDarkMode();
  }

  Future<void> setMonthlyBudget(double budget) async {
    _monthlyBudget = budget;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthlyBudget', budget);
    notifyListeners();
  }

  Future<void> setMonthStartDay(int day) async {
    _monthStartDay = day;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('monthStartDay', day);
    notifyListeners();
  }

  Future<void> setFirstTimeLaunch(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('firstTimeLaunch', value);
    notifyListeners();
  }

  Future<bool> isFirstTimeLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('firstTimeLaunch') ?? true;
  }

  /// Returns the correct locale string for the current currency symbol.
  String _localeForCurrency(String symbol) {
    switch (symbol) {
      case '₹':
        return 'en_IN';
      case '\$':
        return 'en_US';
      case '€':
        return 'de_DE';
      case '£':
        return 'en_GB';
      case '¥':
        return 'ja_JP';
      case '₽':
        return 'ru_RU';
      case 'R\$':
        return 'pt_BR';
      case 'C\$':
        return 'en_CA';
      case 'A\$':
        return 'en_AU';
      case 'Fr':
        return 'de_CH';
      case 'kr':
        return 'sv_SE';
      default:
        return 'en_US';
    }
  }

  /// Convert an amount stored in INR (base) → current display currency.
  double convertFromBase(double amountInINR) {
    final rates = _ratesLoaded && _liveRates.isNotEmpty ? _liveRates : _staticRates;
    return CurrencyService.convert(
      amount: amountInINR,
      fromCode: 'INR',
      toCode: _currencyCode,
      rates: rates,
    );
  }

  /// Convert an amount in [fromCode] currency → INR (base) for storage.
  double convertToBase(double amount, String fromCode) {
    final rates = _ratesLoaded && _liveRates.isNotEmpty ? _liveRates : _staticRates;
    return CurrencyService.convert(
      amount: amount,
      fromCode: fromCode,
      toCode: 'INR',
      rates: rates,
    );
  }

  /// Format an INR-base amount, converting to the selected display currency first.
  String formatCurrency(double amountInINR, {bool compact = false}) {
    final converted = convertFromBase(amountInINR);
    final locale = _localeForCurrency(_currency);
    if (compact) {
      if (converted >= 1000000) {
        return '$currency${(converted / 1000000).toStringAsFixed(1)}M';
      } else if (converted >= 1000) {
        return '$currency${(converted / 1000).toStringAsFixed(1)}K';
      }
      return '$currency${converted.toStringAsFixed(0)}';
    }

    return NumberFormat.currency(
      locale: locale,
      symbol: currency,
      decimalDigits: 2,
    ).format(converted);
  }

  String getCurrencyCode() {
    switch (_currency) {
      case '₹':
        return 'INR - Indian Rupee';
      case '\$':
        return 'USD - US Dollar';
      case '€':
        return 'EUR - Euro';
      case '£':
        return 'GBP - British Pound';
      case '¥':
        return 'JPY - Japanese Yen';
      case '₽':
        return 'RUB - Russian Ruble';
      case 'R\$':
        return 'BRL - Brazilian Real';
      case 'C\$':
        return 'CAD - Canadian Dollar';
      case 'A\$':
        return 'AUD - Australian Dollar';
      case 'Fr':
        return 'CHF - Swiss Franc';
      case 'kr':
        return 'SEK - Swedish Krona';
      default:
        return 'Currency';
    }
  }

  // ✅ NEW: Font size setter
  Future<void> setFontSize(String size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontSize', size);
    debugPrint('✅ Font size changed to: $size');
    notifyListeners();
  }

  // ✅ NEW: Language setter
  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    debugPrint('✅ Language changed to: $lang');
    notifyListeners();
  }

  // ✅ NEW: Privacy policy acceptance
  Future<void> acceptPrivacyPolicy(String version) async {
    _privacyAccepted = version;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('privacyAccepted', version);
    debugPrint('✅ Privacy policy accepted (v$version)');
    notifyListeners();
  }

  // ✅ NEW: Terms of service acceptance
  Future<void> acceptTermsOfService(String version) async {
    _termsAccepted = version;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('termsAccepted', version);
    debugPrint('✅ Terms of service accepted (v$version)');
    notifyListeners();
  }

  // ✅ NEW: Get font size multiplier for responsive text
  double getFontSizeMultiplier() {
    switch (_fontSize) {
      case 'Small':
        return 0.85;
      case 'Medium':
        return 1.0;
      case 'Large':
        return 1.15;
      case 'Extra Large':
        return 1.3;
      default:
        return 1.0;
    }
  }

}

