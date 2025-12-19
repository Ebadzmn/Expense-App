import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LocationService extends GetxService {
  static const String _countryKey = 'user_country';
  final _country = ''.obs;
  String get country => _country.value;

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

      // First visit or country not stored
      String detectedCountry = await _getCountryViaGeolocation();

      if (detectedCountry.isEmpty) {
        // Fallback to IP-based detection
        detectedCountry = await _getCountryViaIP();
      }

      if (detectedCountry.isNotEmpty) {
        _country.value = detectedCountry;
        await prefs.setString(_countryKey, detectedCountry);
        debugPrint("Country: ${_country.value.toLowerCase()}");
      } else {
        debugPrint("Country: unknown (detection failed)");
      }
    } catch (e) {
      debugPrint("Location tracking system error: $e");
    }
  }

  Future<String> _getCountryViaGeolocation() async {
    try {
      // Geolocator works on Web, Android, iOS.
      // However, geocoding (placemarkFromCoordinates) might have issues on Web.
      if (kIsWeb) {
        return ''; // Default to IP for web to avoid geocoding issues
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location services are disabled.");
        return '';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // We only request if it's the first time or denied (not deniedForever)
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("Location permissions are denied.");
          return '';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permissions are permanently denied.");
        return '';
      }

      // If we reach here, we have permission
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        return placemarks.first.country ?? '';
      }
    } catch (e) {
      debugPrint("Geolocation detection error: $e");
    }
    return '';
  }

  Future<String> _getCountryViaIP() async {
    try {
      // Using ip-api.com which is free for non-commercial use and doesn't require an API key
      final response = await http
          .get(Uri.parse('http://ip-api.com/json'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['country'] ?? '';
        }
      }
    } catch (e) {
      debugPrint("IP-based location detection error: $e");
    }
    return '';
  }
}
