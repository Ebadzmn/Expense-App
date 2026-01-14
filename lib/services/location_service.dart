import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService extends GetxService {
  static const String _countryKey = 'user_country';
  final _country = ''.obs;
  String get country => _country.value;
  set country(String value) => _country.value = value;

  Future<void> setCountryManually(String countryName) async {
    final prefs = await SharedPreferences.getInstance();
    _country.value = countryName;
    await prefs.setString(_countryKey, countryName);
    debugPrint("Country manually set: ${_country.value.toLowerCase()}");
  }

  Future<LocationService> init() async {
    await _detectAndStoreLocation();
    return this;
  }

  Future<void> _detectAndStoreLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? storedCountry = prefs.getString(_countryKey);

      if (storedCountry != null && storedCountry.isNotEmpty) {
        _country.value = storedCountry;
        debugPrint("Country: ${_country.value.toLowerCase()}");
        return;
      }

      // No auto-detection. User must set manually.
      debugPrint("Country: not set (waiting for manual selection)");
    } catch (e) {
      debugPrint("Location service error: $e");
    }
  }
}
