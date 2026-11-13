import 'package:flutter/material.dart';

@immutable
class CurrencyInfo {
  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    required this.longName,
    required this.flagColor,
    required this.flagIcon,
  });

  final String code;
  final String symbol;
  final String name;
  final String longName;
  final Color flagColor;
  final IconData flagIcon;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyInfo &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

abstract final class Currencies {
  static const CurrencyInfo bdt = CurrencyInfo(
    code: 'BDT',
    symbol: '৳',
    name: 'Taka',
    longName: 'Bangladesh Taka',
    flagColor: Color(0xFF006A4E),
    flagIcon: Icons.language,
  );

  static const CurrencyInfo usd = CurrencyInfo(
    code: 'USD',
    symbol: r'$',
    name: 'US Dollar',
    longName: 'US Dollar',
    flagColor: Color(0xFF3C3B6E),
    flagIcon: Icons.attach_money,
  );

  static const CurrencyInfo eur = CurrencyInfo(
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
    longName: 'Euro',
    flagColor: Color(0xFF003399),
    flagIcon: Icons.euro_symbol,
  );

  static const CurrencyInfo gbp = CurrencyInfo(
    code: 'GBP',
    symbol: '£',
    name: 'British Pound',
    longName: 'British Pound',
    flagColor: Color(0xFF012169),
    flagIcon: Icons.payments,
  );

  static const CurrencyInfo inr = CurrencyInfo(
    code: 'INR',
    symbol: '₹',
    name: 'Indian Rupee',
    longName: 'Indian Rupee',
    flagColor: Color(0xFFFF9933),
    flagIcon: Icons.currency_rupee,
  );

  static const CurrencyInfo aud = CurrencyInfo(
    code: 'AUD',
    symbol: r'A$',
    name: 'Australian Dollar',
    longName: 'Australian Dollar',
    flagColor: Color(0xFF00008B),
    flagIcon: Icons.attach_money,
  );

  static const CurrencyInfo cad = CurrencyInfo(
    code: 'CAD',
    symbol: r'C$',
    name: 'Canadian Dollar',
    longName: 'Canadian Dollar',
    flagColor: Color(0xFFFF0000),
    flagIcon: Icons.attach_money,
  );

  static const CurrencyInfo sgd = CurrencyInfo(
    code: 'SGD',
    symbol: r'S$',
    name: 'Singapore Dollar',
    longName: 'Singapore Dollar',
    flagColor: Color(0xFFED2939),
    flagIcon: Icons.attach_money,
  );

  static const CurrencyInfo myr = CurrencyInfo(
    code: 'MYR',
    symbol: 'RM',
    name: 'Malaysian Ringgit',
    longName: 'Malaysian Ringgit',
    flagColor: Color(0xFF010066),
    flagIcon: Icons.monetization_on,
  );

  static const CurrencyInfo sar = CurrencyInfo(
    code: 'SAR',
    symbol: 'ر.س',
    name: 'Saudi Riyal',
    longName: 'Saudi Riyal',
    flagColor: Color(0xFF006C35),
    flagIcon: Icons.monetization_on,
  );

  static const CurrencyInfo aed = CurrencyInfo(
    code: 'AED',
    symbol: 'د.إ',
    name: 'UAE Dirham',
    longName: 'UAE Dirham',
    flagColor: Color(0xFFFF0000),
    flagIcon: Icons.monetization_on,
  );

  static const CurrencyInfo pkr = CurrencyInfo(
    code: 'PKR',
    symbol: '₨',
    name: 'Pakistani Rupee',
    longName: 'Pakistani Rupee',
    flagColor: Color(0xFF01411C),
    flagIcon: Icons.currency_rupee,
  );

  static const CurrencyInfo lkr = CurrencyInfo(
    code: 'LKR',
    symbol: 'රු',
    name: 'Sri Lankan Rupee',
    longName: 'Sri Lankan Rupee',
    flagColor: Color(0xFF8D153A),
    flagIcon: Icons.currency_rupee,
  );

  static const CurrencyInfo npr = CurrencyInfo(
    code: 'NPR',
    symbol: 'रू',
    name: 'Nepalese Rupee',
    longName: 'Nepalese Rupee',
    flagColor: Color(0xFFDC143C),
    flagIcon: Icons.currency_rupee,
  );

  static const List<CurrencyInfo> primary = [
    bdt,
    usd,
    eur,
    gbp,
    inr,
  ];

  static const List<CurrencyInfo> all = [
    bdt,
    usd,
    eur,
    gbp,
    inr,
    aud,
    cad,
    sgd,
    myr,
    sar,
    aed,
    pkr,
    lkr,
    npr,
  ];

  static CurrencyInfo forCode(String? code) {
    final normalized = (code ?? 'BDT').trim().toUpperCase();
    for (final currency in all) {
      if (currency.code == normalized) return currency;
    }
    return bdt;
  }

  static String symbolForCode(String? code) => forCode(code).symbol;

  static String nameForCode(String? code) => forCode(code).name;
}
