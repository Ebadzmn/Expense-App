import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:your_expense/Settings/appearance/ThemeController.dart';


import 'package:your_expense/services/location_service.dart';

class CountrySelectionScreen extends StatelessWidget {
  CountrySelectionScreen({super.key});

  final LocationService _locationService = Get.find<LocationService>();

  final List<String> _countries = const [
    'United States',
    'United Kingdom',
    'Germany',
    'France',
    'India',
    'Italy',
    'Australia',
  ];

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final bool isDarkMode = themeController.isDarkModeActive;
      final String selectedCountry = _locationService.country;

      return Scaffold(
        appBar: AppBar(
          title: Text('country_change'.tr),
          backgroundColor:
              isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          foregroundColor: isDarkMode ? Colors.white : Colors.black,
          elevation: 0,
        ),
        backgroundColor:
            isDarkMode ? const Color(0xFF121212) : Colors.white,
        body: ListView.builder(
          itemCount: _countries.length,
          itemBuilder: (context, index) {
            final country = _countries[index];
            final bool isSelected =
                selectedCountry.toLowerCase() == country.toLowerCase();

            return ListTile(
              title: Text(
                country,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: const Color(0xFF007AFF),
                    )
                  : null,
              onTap: () async {
                await _locationService.setCountryManually(country);
                Get.back();
              },
            );
          },
        ),
      );
    });
  }
}
