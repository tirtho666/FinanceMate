import 'currencies.dart';

abstract final class Formatters {
  static String currency(String? currencyCode, double amount) {
    final symbol = Currencies.symbolForCode(currencyCode);
    return '$symbol ${_group(amount.abs())}';
  }

  static String signedCurrency(
    String? currencyCode,
    double amount, {
    required bool isIncome,
  }) {
    final formatted = currency(currencyCode, amount);
    return '${isIncome ? '+' : '-'} $formatted';
  }

  static String taka(double amount) => currency('BDT', amount);

  static String signedTaka(double amount, {required bool isIncome}) =>
      signedCurrency('BDT', amount, isIncome: isIncome);

  static String date(DateTime date) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  static String _group(double amount) {
    final digits = amount.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      if (i != 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
