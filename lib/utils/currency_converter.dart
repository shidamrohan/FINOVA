class CurrencyConverter {
  // Base currency: INR (₹)
  // All rates are: 1 INR = X currency

  static const Map<String, double> exchangeRates = {
    '₹': 1.0, // Indian Rupee (BASE)
    '\$': 0.012, // US Dollar (1 INR = 0.012 USD)
    '€': 0.011, // Euro (1 INR = 0.011 EUR)
    '£': 0.0095, // British Pound (1 INR = 0.0095 GBP)
    '¥': 1.79, // Japanese Yen (1 INR = 1.79 JPY)
    '₽': 1.10, // Russian Ruble (1 INR = 1.10 RUB)
    'R\$': 0.069, // Brazilian Real (1 INR = 0.069 BRL)
    'C\$': 0.017, // Canadian Dollar (1 INR = 0.017 CAD)
    'A\$': 0.019, // Australian Dollar (1 INR = 0.019 AUD)
    'Fr': 0.010, // Swiss Franc (1 INR = 0.010 CHF)
    'kr': 0.13, // Swedish Krona (1 INR = 0.13 SEK)
  };

  /// Convert amount from one currency to another
  /// Example: convert(5000, '₹', '\$') = 60.0
  static double convert(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;

    // Get exchange rates
    final fromRate = exchangeRates[fromCurrency] ?? 1.0;
    final toRate = exchangeRates[toCurrency] ?? 1.0;

    // Convert from -> INR -> to
    final inrAmount = amount / fromRate;
    final convertedAmount = inrAmount * toRate;

    return convertedAmount;
  }

  /// Get exchange rate between two currencies
  static double getRate(String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return 1.0;

    final fromRate = exchangeRates[fromCurrency] ?? 1.0;
    final toRate = exchangeRates[toCurrency] ?? 1.0;

    return toRate / fromRate;
  }

  /// Format conversion for display
  /// Example: "₹5,000 = $60.00"
  static String formatConversion(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) {
    final converted = convert(amount, fromCurrency, toCurrency);
    return '$fromCurrency${amount.toStringAsFixed(2)} = $toCurrency${converted.toStringAsFixed(2)}';
  }
}
