/// Currency data for the app
class CurrencyData {
  final String code;
  final String name;
  final String symbol;

  const CurrencyData({
    required this.code,
    required this.name,
    required this.symbol,
  });
}

/// List of supported currencies
class Currencies {
  static const List<CurrencyData> all = [
    CurrencyData(code: 'USD', name: 'US Dollar', symbol: '\$'),
    CurrencyData(code: 'EUR', name: 'Euro', symbol: '€'),
    CurrencyData(code: 'GBP', name: 'British Pound', symbol: '£'),
    CurrencyData(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
    CurrencyData(code: 'CNY', name: 'Chinese Yuan', symbol: '¥'),
    CurrencyData(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
    CurrencyData(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$'),
    CurrencyData(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$'),
    CurrencyData(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF'),
    CurrencyData(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$'),
    CurrencyData(code: 'HKD', name: 'Hong Kong Dollar', symbol: 'HK\$'),
    CurrencyData(code: 'NZD', name: 'New Zealand Dollar', symbol: 'NZ\$'),
    CurrencyData(code: 'SEK', name: 'Swedish Krona', symbol: 'kr'),
    CurrencyData(code: 'NOK', name: 'Norwegian Krone', symbol: 'kr'),
    CurrencyData(code: 'DKK', name: 'Danish Krone', symbol: 'kr'),
    CurrencyData(code: 'MXN', name: 'Mexican Peso', symbol: 'Mex\$'),
    CurrencyData(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$'),
    CurrencyData(code: 'ZAR', name: 'South African Rand', symbol: 'R'),
    CurrencyData(code: 'RUB', name: 'Russian Ruble', symbol: '₽'),
    CurrencyData(code: 'KRW', name: 'South Korean Won', symbol: '₩'),
    CurrencyData(code: 'THB', name: 'Thai Baht', symbol: '฿'),
    CurrencyData(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM'),
    CurrencyData(code: 'IDR', name: 'Indonesian Rupiah', symbol: 'Rp'),
    CurrencyData(code: 'PHP', name: 'Philippine Peso', symbol: '₱'),
    CurrencyData(code: 'VND', name: 'Vietnamese Dong', symbol: '₫'),
    CurrencyData(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ'),
    CurrencyData(code: 'SAR', name: 'Saudi Riyal', symbol: '﷼'),
    CurrencyData(code: 'TRY', name: 'Turkish Lira', symbol: '₺'),
    CurrencyData(code: 'PLN', name: 'Polish Zloty', symbol: 'zł'),
    CurrencyData(code: 'CZK', name: 'Czech Koruna', symbol: 'Kč'),
  ];

  /// Get currency symbol by code
  static String getSymbol(String code) {
    try {
      return all.firstWhere((c) => c.code == code).symbol;
    } catch (e) {
      return '\$'; // Default to USD symbol
    }
  }

  /// Get currency name by code
  static String getName(String code) {
    try {
      return all.firstWhere((c) => c.code == code).name;
    } catch (e) {
      return 'US Dollar'; // Default to USD
    }
  }

  /// Get currency data by code
  static CurrencyData? getByCode(String code) {
    try {
      return all.firstWhere((c) => c.code == code);
    } catch (e) {
      return null;
    }
  }
}
