class CurrencyHelper {
  static const Map<String, CurrencyFormat> currencyFormats = {
    '\$': CurrencyFormat(
      symbol: '\$',
      name: 'US Dollar',
      code: 'USD',
      decimals: 2,
      symbolPosition: SymbolPosition.before,
      thousandSeparator: ',',
      decimalSeparator: '.',
    ),
    '€': CurrencyFormat(
      symbol: '€',
      name: 'Euro',
      code: 'EUR',
      decimals: 2,
      symbolPosition: SymbolPosition.before,
      decimalSeparator: ',',
      thousandSeparator: '.',
    ),
    '£': CurrencyFormat(
      symbol: '£',
      name: 'British Pound',
      code: 'GBP',
      decimals: 2,
      symbolPosition: SymbolPosition.before,
      thousandSeparator: ',',
      decimalSeparator: '.',
    ),
    '¥': CurrencyFormat(
      symbol: '¥',
      name: 'Japanese Yen',
      code: 'JPY',
      decimals: 0,
      symbolPosition: SymbolPosition.before,
      thousandSeparator: ',',
      decimalSeparator: '.',
    ),
    '₹': CurrencyFormat(
      symbol: '₹',
      name: 'Indian Rupee',
      code: 'INR',
      decimals: 2,
      symbolPosition: SymbolPosition.before,
      thousandSeparator: ',',
      decimalSeparator: '.',
    ),
    '₽': CurrencyFormat(
      symbol: '₽',
      name: 'Russian Ruble',
      code: 'RUB',
      decimals: 2,
      symbolPosition: SymbolPosition.after,
      thousandSeparator: ' ',
      decimalSeparator: ',',
    ),
    'R\$': CurrencyFormat(
      symbol: 'R\$',
      name: 'Brazilian Real',
      code: 'BRL',
      decimals: 2,
      symbolPosition: SymbolPosition.before,
      thousandSeparator: '.',
      decimalSeparator: ',',
    ),
    'C\$': CurrencyFormat(
      symbol: 'C\$',
      name: 'Canadian Dollar',
      code: 'CAD',
      decimals: 2,
      symbolPosition: SymbolPosition.before,
      thousandSeparator: ',',
      decimalSeparator: '.',
    ),
    'A\$': CurrencyFormat(
      symbol: 'A\$',
      name: 'Australian Dollar',
      code: 'AUD',
      decimals: 2,
      symbolPosition: SymbolPosition.before,
      thousandSeparator: ',',
      decimalSeparator: '.',
    ),
    'Fr': CurrencyFormat(
      symbol: 'Fr',
      name: 'Swiss Franc',
      code: 'CHF',
      decimals: 2,
      symbolPosition: SymbolPosition.after,
      thousandSeparator: '\'',
      decimalSeparator: '.',
    ),
    'kr': CurrencyFormat(
      symbol: 'kr',
      name: 'Swedish Krona',
      code: 'SEK',
      decimals: 2,
      symbolPosition: SymbolPosition.after,
      thousandSeparator: ' ',
      decimalSeparator: ',',
    ),
  };

  static String format(double amount, String currencySymbol,
      {bool compact = false}) {
    final format = currencyFormats[currencySymbol] ?? currencyFormats['\$']!;

    final roundedAmount = _roundToDecimals(amount, format.decimals);

    final parts = roundedAmount.toStringAsFixed(format.decimals).split('.');
    final integerPart = parts[0];
    final decimalPart = format.decimals > 0 ? parts[1] : '';

    final formattedInteger = _addThousandSeparators(
      integerPart,
      format.thousandSeparator,
    );

    String formattedAmount = formattedInteger;
    if (format.decimals > 0 && !compact) {
      formattedAmount += format.decimalSeparator + decimalPart;
    }

    if (format.symbolPosition == SymbolPosition.before) {
      return '${format.symbol}$formattedAmount';
    } else {
      return '$formattedAmount ${format.symbol}';
    }
  }

  static String formatInput(double amount, String currencySymbol) {
    final format = currencyFormats[currencySymbol] ?? currencyFormats['\$']!;
    final roundedAmount = _roundToDecimals(amount, format.decimals);

    if (format.decimals == 0) {
      return roundedAmount.toStringAsFixed(0);
    }

    return roundedAmount.toStringAsFixed(format.decimals);
  }

  static int getDecimals(String currencySymbol) {
    final format = currencyFormats[currencySymbol] ?? currencyFormats['\$']!;
    return format.decimals;
  }

  static double _roundToDecimals(double value, int decimals) {
    final factor = decimals == 0 ? 1 : (10 * decimals);
    return (value * factor).round() / factor;
  }

  static String _addThousandSeparators(String number, String separator) {
    final cleaned = number.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.length <= 3) return cleaned;

    final buffer = StringBuffer();
    var count = 0;

    for (int i = cleaned.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write(separator);
      }
      buffer.write(cleaned[i]);
      count++;
    }

    return buffer.toString().split('').reversed.join('');
  }

  static String formatCompact(double amount, String currencySymbol) {
    final format = currencyFormats[currencySymbol] ?? currencyFormats['\$']!;

    String compactAmount;
    if (amount >= 1000000) {
      compactAmount = '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      compactAmount = '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      compactAmount = amount.toStringAsFixed(format.decimals);
    }

    if (format.symbolPosition == SymbolPosition.before) {
      return '${format.symbol}$compactAmount';
    } else {
      return '$compactAmount ${format.symbol}';
    }
  }
}

enum SymbolPosition { before, after }

class CurrencyFormat {
  final String symbol;
  final String name;
  final String code;
  final int decimals;
  final SymbolPosition symbolPosition;
  final String thousandSeparator;
  final String decimalSeparator;

  const CurrencyFormat({
    required this.symbol,
    required this.name,
    required this.code,
    required this.decimals,
    required this.symbolPosition,
    required this.thousandSeparator,
    required this.decimalSeparator,
  });
}
