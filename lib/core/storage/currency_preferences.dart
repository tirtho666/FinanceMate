import 'package:shared_preferences/shared_preferences.dart';

import '../utils/currencies.dart';

/// Persists the currency the user picked on the device.
///
/// The selection is a local preference (it drives the symbol shown across the
/// whole app), so `shared_preferences` is used rather than the keystore. The
/// value is mirrored in RAM so it can be read synchronously by the provider
/// layer without awaiting the platform channel.
class CurrencyPreferences {
  CurrencyPreferences([this._preferences]);

  static const String _codeKey = 'settings.currency_code';
  static const String _symbolKey = 'settings.currency_symbol';

  SharedPreferences? _preferences;
  String? _code;
  String? _symbol;
  bool _isLoaded = false;

  /// Selected ISO currency code, or `null` when the user never picked one.
  String? get code => _code;

  /// Symbol belonging to the selection, falling back to the BDT symbol.
  String get symbol => _symbol ?? Currencies.symbolForCode(_code);

  bool get hasSelection => (_code ?? '').isNotEmpty;

  /// Loads the persisted selection into RAM. Safe to call more than once.
  Future<void> load() async {
    if (_isLoaded) return;
    final preferences = await _instance();
    _code = preferences.getString(_codeKey);
    _symbol = preferences.getString(_symbolKey);
    _isLoaded = true;
  }

  Future<void> save(String code, {String? symbol}) async {
    final normalized = code.trim().toUpperCase();
    final resolvedSymbol = symbol ?? Currencies.symbolForCode(normalized);
    final preferences = await _instance();
    await preferences.setString(_codeKey, normalized);
    await preferences.setString(_symbolKey, resolvedSymbol);
    _code = normalized;
    _symbol = resolvedSymbol;
    _isLoaded = true;
  }

  Future<SharedPreferences> _instance() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }
}
