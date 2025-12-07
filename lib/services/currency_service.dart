import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService extends GetxService {
  static const String _currencyCodeKey = 'selected_currency_code';
  static const String _currencySymbolKey = 'selected_currency_symbol';
  static const String _currencyNameKey = 'selected_currency_name';

  // Reactive currency properties
  final RxString currencyCode = 'USD'.obs;
  final RxString currencySymbol = '\$'.obs;
  final RxString currencyName = 'United States Dollar'.obs;

  late SharedPreferences _prefs;

  // Initialize the service
  Future<CurrencyService> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSavedCurrency();
    return this;
  }

  // Load saved currency from SharedPreferences
  Future<void> _loadSavedCurrency() async {
    final savedCode = _prefs.getString(_currencyCodeKey);
    final savedSymbol = _prefs.getString(_currencySymbolKey);
    final savedName = _prefs.getString(_currencyNameKey);

    if (savedCode != null && savedSymbol != null && savedName != null) {
      currencyCode.value = savedCode;
      currencySymbol.value = savedSymbol;
      currencyName.value = savedName;
      print('💰 Loaded saved currency: $savedCode ($savedSymbol)');
    } else {
      print('💰 Using default currency: USD (\$)');
    }
  }

  // Save selected currency
  Future<void> saveCurrency(String code, String symbol, String name) async {
    await _prefs.setString(_currencyCodeKey, code);
    await _prefs.setString(_currencySymbolKey, symbol);
    await _prefs.setString(_currencyNameKey, name);

    currencyCode.value = code;
    currencySymbol.value = symbol;
    currencyName.value = name;

    print('💰 Currency saved: $code ($symbol)');
  }

  // Format amount with current currency symbol
  String formatAmount(double amount, {int decimals = 2}) {
    return '${currencySymbol.value}${amount.toStringAsFixed(decimals)}';
  }

  // Format amount with current currency symbol (no decimals)
  String formatAmountInt(double amount) {
    return '${currencySymbol.value}${amount.toStringAsFixed(0)}';
  }

  // Get currency display name
  String get displayName => '$currencyName (${currencySymbol.value})';
}
