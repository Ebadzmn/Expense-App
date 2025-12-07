import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'appearance/ThemeController.dart';
import '../services/currency_service.dart';

class CurrencyExchangeScreen extends StatelessWidget {
  const CurrencyExchangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final controller = Get.put(CurrencyController());

    return Obx(
      () => Scaffold(
        backgroundColor: themeController.isDarkModeActive
            ? const Color(0xFF121212)
            : const Color(0xFFF2F2F7),
        appBar: AppBar(
          backgroundColor: themeController.isDarkModeActive
              ? const Color(0xFF1E1E1E)
              : const Color(0xFFF2F2F7),
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: themeController.isDarkModeActive
                  ? Colors.white
                  : Colors.black,
              size: 16,
            ),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'currency_exchange'.tr,
            style: TextStyle(
              color: themeController.isDarkModeActive
                  ? Colors.white
                  : Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'choose_currency_desc'.tr,
                style: TextStyle(
                  fontSize: 14,
                  color: themeController.isDarkModeActive
                      ? Colors.grey[400]
                      : const Color(0xFF8E8E93),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: themeController.isDarkModeActive
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Obx(
                  () => Column(
                    children: [
                      for (
                        int i = 0;
                        i < controller.currencies.length;
                        i++
                      ) ...[
                        _buildCurrencyOption(
                          controller.currencies[i],
                          controller.selectedCurrencyIndex.value == i,
                          () {
                            controller.selectedCurrencyIndex.value = i;
                          },
                          isDarkMode: themeController.isDarkModeActive,
                        ),
                        if (i < controller.currencies.length - 1)
                          Container(
                            height: 0.5,
                            color: themeController.isDarkModeActive
                                ? const Color(0xFF333333)
                                : const Color(0xFFE5E5EA),
                            margin: const EdgeInsets.only(left: 16),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeController.isDarkModeActive
                    ? const Color(0xFF332900)
                    : const Color(0xFFFFF2CC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: themeController.isDarkModeActive
                        ? const Color(0xFFFFB300)
                        : const Color(0xFFFF9500),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Currency changes will be applied across the application.',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeController.isDarkModeActive
                            ? const Color(0xFFFFB300)
                            : const Color(0xFF8E6914),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  await controller.applyCurrencyChange();
                  Get.back();
                  Get.snackbar(
                    'success'.tr,
                    'currency_updated'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: themeController.isDarkModeActive
                        ? const Color(0xFF2A2A2A)
                        : Colors.blue,
                    colorText: Colors.white,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'apply_changes'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 34),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(
    Currency currency,
    bool isSelected,
    VoidCallback onTap, {
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.transparent,
        child: Row(
          children: [
            Text(
              '${currency.name} (${currency.symbol})',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const Spacer(),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF007AFF)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF007AFF)
                      : (isDarkMode
                            ? const Color(0xFF555555)
                            : const Color(0xFFD1D1D6)),
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurrencyController extends GetxController {
  final currencyService = Get.find<CurrencyService>();

  final List<Currency> currencies = [
    Currency('USD', 'United States Dollar', '\$'),
    Currency('EUR', 'Euro', '€'),
    Currency('GBP', 'British Pound', '£'),
    Currency('JPY', 'Japanese Yen', '¥'),
    Currency('CAD', 'Canadian Dollar', 'C\$'),
  ];

  RxInt selectedCurrencyIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Set the initial selected index based on current currency
    final currentCode = currencyService.currencyCode.value;
    final index = currencies.indexWhere((c) => c.code == currentCode);
    if (index != -1) {
      selectedCurrencyIndex.value = index;
    }
  }

  Future<void> applyCurrencyChange() async {
    final selected = currencies[selectedCurrencyIndex.value];
    await currencyService.saveCurrency(
      selected.code,
      selected.symbol,
      selected.name,
    );
    print('Selected Currency: ${selected.code} (${selected.symbol})');
  }
}

class Currency {
  final String code;
  final String name;
  final String symbol;

  Currency(this.code, this.name, this.symbol);
}
