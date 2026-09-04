import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String defaultSymbol = '₹';
  static String defaultCode = 'INR';

  /// Formats amount in Indian Rupee style: e.g. 5000 -> ₹5,000, 125000 -> ₹1,25,000
  static String format(
    double amount, {
    String? symbol,
    bool showDecimals = false,
    bool compact = false,
  }) {
    final sym = symbol ?? defaultSymbol;
    final isNegative = amount < 0;
    final absAmount = amount.abs();

    if (compact && absAmount >= 10000000) {
      // 1 Crore = 10,000,000
      final cr = absAmount / 10000000;
      return '${isNegative ? '-' : ''}$sym${cr.toStringAsFixed(cr.truncateToDouble() == cr ? 0 : 2)} Cr';
    } else if (compact && absAmount >= 100000) {
      // 1 Lakh = 100,000
      final lk = absAmount / 100000;
      return '${isNegative ? '-' : ''}$sym${lk.toStringAsFixed(lk.truncateToDouble() == lk ? 0 : 2)} L';
    }

    String formattedNumber;
    try {
      final pattern = showDecimals ? '#,##,##0.00' : '#,##,##0';
      final formatter = NumberFormat(pattern, 'en_IN');
      formattedNumber = formatter.format(absAmount);
    } catch (_) {
      // Fallback if locale data is unavailable
      formattedNumber = _formatIndianSystem(absAmount, showDecimals);
    }

    return '${isNegative ? '-' : ''}$sym$formattedNumber';
  }

  static String _formatIndianSystem(double amount, bool showDecimals) {
    final parts = amount.toStringAsFixed(showDecimals ? 2 : 0).split('.');
    String integerPart = parts[0];
    final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    if (integerPart.length <= 3) {
      return integerPart + decimalPart;
    }

    final lastThree = integerPart.substring(integerPart.length - 3);
    String remaining = integerPart.substring(0, integerPart.length - 3);

    final groups = <String>[];
    while (remaining.length > 2) {
      groups.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) {
      groups.insert(0, remaining);
    }

    return '${groups.join(',')},$lastThree$decimalPart';
  }
}
