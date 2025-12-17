import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Settings/appearance/ThemeController.dart';

import '../home/home_controller.dart';
import 'ComparisonPageController.dart';
import 'package:your_expense/services/subscription_service.dart';
import 'package:your_expense/routes/app_routes.dart';

class ComparisonPageScreen extends StatefulWidget {
  final bool isFromExpense;
  final bool isEmbeddedInMain;

  const ComparisonPageScreen({
    super.key,
    required this.isFromExpense,
    this.isEmbeddedInMain = false,
  });

  @override
  State<ComparisonPageScreen> createState() => _ComparisonPageScreenState();
}

class _ComparisonPageScreenState extends State<ComparisonPageScreen> {
  late final TextEditingController productNameController;
  late final TextEditingController maxPriceController;
  late final FocusNode _productNameFocus;
  late final FocusNode _maxPriceFocus;
  late final ComparisonPageController comparisonCtrl;
  String? _prevRoute;
  bool _overlayDismissed = false;

  void _restoreNavIndex() {
    try {
      final homeCtrl = Get.find<HomeController>();
      int idx = homeCtrl.selectedNavIndex.value;
      switch (_prevRoute) {
        case AppRoutes.analytics:
          idx = 1;
          break;
        case AppRoutes.settings:
          idx = 3;
          break;
        default:
          break;
      }
      homeCtrl.setNavIndex(idx);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    productNameController = TextEditingController();
    maxPriceController = TextEditingController();
    _productNameFocus = FocusNode();
    _maxPriceFocus = FocusNode();
    // Ensure a single instance across rebuilds
    comparisonCtrl = Get.put(ComparisonPageController());

    if (!widget.isEmbeddedInMain) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final homeCtrl = Get.find<HomeController>();
        _prevRoute = Get.previousRoute;
        if (homeCtrl.selectedNavIndex.value != 2) {
          homeCtrl.selectedNavIndex.value = 2;
        }
      });
    }
  }

  @override
  void dispose() {
    productNameController.dispose();
    maxPriceController.dispose();
    _productNameFocus.dispose();
    _maxPriceFocus.dispose();
    if (!widget.isEmbeddedInMain) {
      _restoreNavIndex();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final SubscriptionService sub = Get.find<SubscriptionService>();
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final bool isDarkMode = themeController.isDarkModeActive;
    final Color backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.white;

    return WillPopScope(
      onWillPop: () async {
        if (_productNameFocus.hasFocus || _maxPriceFocus.hasFocus) {
          _productNameFocus.unfocus();
          _maxPriceFocus.unfocus();
          return false;
        }
        if (!widget.isEmbeddedInMain) {
          _restoreNavIndex();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
          leading: widget.isEmbeddedInMain
              ? null
              : IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: isDarkMode ? Colors.white : Colors.black,
                    size: 20,
                  ),
                  onPressed: () {
                    _restoreNavIndex();
                    Get.back();
                  },
                ),
          automaticallyImplyLeading: !widget.isEmbeddedInMain,
          title: Text(
            'compare_save'.tr,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.02),

                  // Find Better Deals Section
                  Text(
                    'find_better_deals'.tr,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'find_better_deals_desc'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),

                  // Product Name Field
                  Text(
                    'product_name'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: productNameController,
                      focusNode: _productNameFocus,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        hintText: 'enter_product_name'.tr,
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[500] : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  // Max Price Field
                  Text(
                    'max_price'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: maxPriceController,
                      focusNode: _maxPriceFocus,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: '\$ Enter amount',
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[500] : Colors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  // Search Button
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: comparisonCtrl.isLoading.value
                            ? null
                            : () async {
                                // Gate search for non-pro users
                                final SubscriptionService sub =
                                    Get.find<SubscriptionService>();
                                if (!sub.isActivePro) {
                                  Get.snackbar(
                                    'upgradeToProToView'.tr,
                                    'graphsAndReports'.tr,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  Get.toNamed(AppRoutes.premiumPlans);
                                  return;
                                }
                                if (productNameController.text.isEmpty) {
                                  Get.snackbar(
                                    'error'.tr,
                                    'please_enter_product_name'.tr,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                final price =
                                    double.tryParse(maxPriceController.text) ??
                                    0.0;
                                if (price <= 0) {
                                  Get.snackbar(
                                    'error'.tr,
                                    'please_enter_valid_price'.tr,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                await comparisonCtrl.searchProducts(
                                  productNameController.text.trim(),
                                  price,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: comparisonCtrl.isLoading.value
                              ? Colors.grey
                              : Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        icon: comparisonCtrl.isLoading.value
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(Icons.search, color: Colors.white, size: 20),
                        label: comparisonCtrl.isLoading.value
                            ? Text(
                                'searching'.tr,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : Text(
                                'search'.tr,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),

                  // Error Message
                  Obx(() {
                    if (comparisonCtrl.errorMessage.isNotEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          comparisonCtrl.errorMessage.value,
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      );
                    }
                    return SizedBox();
                  }),

                  // Results Section
                  Obx(() {
                    if (comparisonCtrl.deals.isEmpty &&
                        !comparisonCtrl.isLoading.value) {
                      // Empty state message when no deals are found
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDarkMode
                                ? const Color(0xFF333333)
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black54,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'no_deals_found'.tr,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'try_different_product_or_increase_price'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: screenHeight * 0.03),

                        // Better Deals Found Section with Count
                        Text(
                          'better_deals_found_count'.trParams({
                            'count': comparisonCtrl.deals.length.toString(),
                          }),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),

                        // Loading Indicator
                        if (comparisonCtrl.isLoading.value)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: CircularProgressIndicator(),
                            ),
                          ),

                        // Deal Cards List
                        if (!comparisonCtrl.isLoading.value)
                          ...comparisonCtrl.deals.map(
                            (deal) => _buildDealCard(
                              context,
                              isDarkMode,
                              screenWidth,
                              screenHeight,
                              deal,
                              comparisonCtrl.currentSearchTerm.value,
                              comparisonCtrl.maxPrice.value,
                            ),
                          ),

                        SizedBox(height: screenHeight * 0.02),
                      ],
                    );
                  }),
                ],
              ),
            ),
            if (!sub.isActivePro && !_overlayDismissed)
              _buildProGateOverlay(screenWidth, screenHeight, isDarkMode),
          ],
        ),
      ),
    );
  }
}

Widget _buildProGateOverlay(
  double screenWidth,
  double screenHeight,
  bool isDark,
) {
  return Positioned.fill(
    child: Container(
      color: Colors.black.withOpacity(0.45),
      child: Center(
        child: Container(
          width: screenWidth * 0.7,
          padding: EdgeInsets.all(screenWidth * 0.04),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock,
                size: screenWidth * 0.08,
                color: const Color(0xFF2196F3),
              ),
              SizedBox(height: screenWidth * 0.03),
              Text(
                'upgradeToProToView'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: screenWidth * 0.015),
              Text(
                'graphsAndReports'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
              SizedBox(height: screenWidth * 0.035),
              SizedBox(
                width: double.infinity,
                height: screenWidth * 0.09,
                child: ElevatedButton(
                  onPressed: () => Get.toNamed(AppRoutes.premiumPlans),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                  ),
                  child: Text(
                    'upgrade_now'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              SizedBox(
                width: double.infinity,
                height: screenWidth * 0.09,
                child: OutlinedButton(
                  onPressed: () => Get.toNamed(
                    AppRoutes.advertisement,
                    arguments: {'isFromExpense': false},
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2196F3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                  ),
                  child: Text(
                    'watchVideoToUnlock'.tr,
                    style: TextStyle(
                      color: const Color(0xFF2196F3),
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildDealCard(
  BuildContext context,
  bool isDarkMode,
  double screenWidth,
  double screenHeight,
  dynamic deal,
  String searchTerm,
  double maxPrice,
) {
  final siteName = deal['siteName'] ?? 'unknown_site'.tr;
  final title = deal['title'] ?? '';
  final price = (deal['price'] ?? 0.0).toDouble();
  final imageUrl = deal['image'] ?? '';
  final rating = (deal['rating'] ?? 0.0).toDouble();
  final url = deal['url'] ?? '';
  final dealType = deal['type'] ?? 'generic';

  String displayTitle = (title is String && title.trim().isNotEmpty)
      ? title.toString().trim()
      : searchTerm;

  // Calculate percentage savings and amount saved
  double savingsPercentage = 0.0;
  double savingsAmount = 0.0;
  bool hasSavings = false;

  if (maxPrice > 0 && price > 0 && price < maxPrice) {
    savingsAmount = maxPrice - price;
    savingsPercentage = (savingsAmount / maxPrice) * 100;
    hasSavings = true;
  }

  return Column(
    children: [
      Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top section with logo, product details, and save badge
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Site Logo with optional product image for specific deals
                  if (dealType == 'specific' && imageUrl.isNotEmpty) ...[
                    // Show product image for specific deals
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildSiteLogo(isDarkMode, siteName);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ] else ...[
                    // Show site logo for generic deals
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey[800]!
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: _buildSiteLogo(isDarkMode, siteName),
                      ),
                    ),
                  ],
                  SizedBox(width: screenWidth * 0.03),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                siteName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            if (dealType == 'specific' && rating > 0) ...[
                              SizedBox(width: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          displayTitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Colors.grey[300]
                                : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        // Show price for specific deals, hide for generic
                        if (dealType == 'specific' && price > 0)
                          Text(
                            '\$${price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[600],
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (hasSavings)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Save \$${savingsAmount.toStringAsFixed(2)} (${savingsPercentage.toStringAsFixed(0)}%)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else if (price > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'best_deal'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Divider
            Divider(
              height: 1,
              thickness: 1,
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
            ),

            // Bottom section with Compare and Copy Link buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Compare Button
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        _showCompareDialog(
                          context,
                          isDarkMode,
                          deal,
                          maxPrice,
                          price,
                          searchTerm,
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(0, 36),
                      ),
                      icon: _buildCompareIcon(isDarkMode),
                      label: Text(
                        'compare'.tr,
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // Vertical Divider
                  Container(
                    height: 24,
                    width: 1,
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),

                  // Copy Link Button
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        _copyToClipboard(url, siteName);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(0, 36),
                      ),
                      icon: _buildCopyLinkIcon(isDarkMode),
                      label: Text(
                        'copy_link'.tr,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: screenHeight * 0.015),
    ],
  );
}

// Copy to clipboard function
Future<void> _copyToClipboard(String text, String siteName) async {
  if (text.isEmpty) {
    Get.snackbar(
      'error'.tr,
      'no_link_available_to_copy'.tr,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    return;
  }

  try {
    await Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'success'.tr,
      'product_link_copied'.trParams({'siteName': siteName}),
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: Duration(seconds: 2),
    );
    print('📋 Copied to clipboard: $text');

    final uri = Uri.tryParse(text.trim());
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    print('❌ Error copying to clipboard: $e');
    Get.snackbar(
      'error'.tr,
      'failed_to_copy_link'.trParams({'error': e.toString()}),
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

// Helper method to build site logo based on site name
Widget _buildSiteLogo(bool isDarkMode, String siteName) {
  String logoPath = 'assets/icons/${siteName.toLowerCase()}.png';

  return Image.asset(
    logoPath,
    width: 24,
    height: 24,
    fit: BoxFit.contain,
    errorBuilder: (context, error, stackTrace) {
      return Text(
        siteName.substring(0, 1),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black54,
        ),
      );
    },
  );
}

// Helper method to build copy link icon
Widget _buildCopyLinkIcon(bool isDarkMode) {
  try {
    return Image.asset(
      'assets/icons/attachment-02.png',
      width: 20,
      height: 20,
      color: isDarkMode ? Colors.white : Colors.black54,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.link,
          size: 20,
          color: isDarkMode ? Colors.white : Colors.black54,
        );
      },
    );
  } catch (e) {
    return Icon(
      Icons.link,
      size: 20,
      color: isDarkMode ? Colors.white : Colors.black54,
    );
  }
}

// Helper method to build compare icon
Widget _buildCompareIcon(bool isDarkMode) {
  try {
    return Image.asset(
      'assets/icons/compare.png',
      width: 20,
      height: 20,
      color: Colors.blue,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/icons/Group 4.png',
          width: 20,
          height: 20,
          color: Colors.blue,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.compare_arrows, size: 20, color: Colors.blue);
          },
        );
      },
    );
  } catch (e) {
    return Icon(Icons.compare_arrows, size: 20, color: Colors.blue);
  }
}

// Updated Show compare dialog with product name
void _showCompareDialog(
  BuildContext context,
  bool isDarkMode,
  dynamic deal,
  double maxPrice,
  double actualPrice,
  String productName,
) {
  final comparisonCtrl = Get.find<ComparisonPageController>();
  final TextEditingController maxPriceController = TextEditingController(
    text: maxPrice.toStringAsFixed(2),
  );
  final TextEditingController actualPriceController = TextEditingController(
    text: actualPrice.toStringAsFixed(2),
  );
  final TextEditingController categoryController = TextEditingController(
    text: productName,
  );

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // Prevent dialog content from exceeding viewport height
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'compare_with_site'.trParams({
                          'site': deal['siteName'],
                        }),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Max Price Field
                      Text(
                        'original_price_max'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? Color(0xFF121212) : Colors.white,
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: maxPriceController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            hintText: '\$ Enter original price',
                            hintStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey[500]
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Actual Price Field
                      Text(
                        'price_with_tool'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? Color(0xFF121212) : Colors.white,
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: actualPriceController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            hintText: '\$ Enter price with tool',
                            hintStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey[500]
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Category Field
                      Text(
                        'product_category'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? Color(0xFF121212) : Colors.white,
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: categoryController,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            hintText: 'enter_product_category'.tr,
                            hintStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey[500]
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Savings Preview
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Color(0xFF2D2D2D)
                              : Colors.grey[50]!,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.green[700]!
                                : Colors.green[200]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'savings_preview'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'you_save_label'.tr,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '\$${(double.tryParse(maxPriceController.text) ?? 0) - (double.tryParse(actualPriceController.text) ?? 0)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Continue Button with loading state
                      Obx(
                        () => SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: comparisonCtrl.isCreatingSavings.value
                                ? null
                                : () async {
                                    // Validate inputs
                                    final maxPrice = double.tryParse(
                                      maxPriceController.text,
                                    );
                                    final actualPrice = double.tryParse(
                                      actualPriceController.text,
                                    );

                                    if (maxPrice == null || maxPrice <= 0) {
                                      Get.snackbar(
                                        'error'.tr,
                                        'please_enter_valid_original_price'.tr,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }

                                    if (actualPrice == null ||
                                        actualPrice <= 0) {
                                      Get.snackbar(
                                        'error'.tr,
                                        'please_enter_valid_price_with_tool'.tr,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }

                                    if (categoryController.text.isEmpty) {
                                      Get.snackbar(
                                        'error'.tr,
                                        'please_enter_product_category'.tr,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }

                                    // Prepare comparison data for graph
                                    final comparisonData = {
                                      'initialPrice': maxPrice,
                                      'actualPrice': actualPrice,
                                      'savings': maxPrice - actualPrice,
                                      'category': categoryController.text
                                          .trim(),
                                      'productName': productName,
                                      'siteName': deal['siteName'],
                                      'savingsPercentage':
                                          ((maxPrice - actualPrice) /
                                                  maxPrice *
                                                  100)
                                              .toStringAsFixed(1),
                                    };

                                    // Call the savings API
                                    final success = await comparisonCtrl
                                        .createSavingsRecord(
                                          category: categoryController.text
                                              .trim(),
                                          initialPrice: maxPrice,
                                          actualPrice: actualPrice,
                                        );

                                    if (success) {
                                      // Close dialog and navigate to comparison graph WITH DATA
                                      Navigator.of(context).pop();
                                      Get.snackbar(
                                        'success'.tr,
                                        'savings_record_created_successfully'
                                            .tr,
                                        backgroundColor: Colors.green,
                                        colorText: Colors.white,
                                      );
                                      // Navigate to comparison graph with the data
                                      Get.toNamed(
                                        '/comparisonGraph',
                                        arguments: comparisonData,
                                      );
                                    } else {
                                      Get.snackbar(
                                        'error'.tr,
                                        'failed_to_create_savings_record'.tr,
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  comparisonCtrl.isCreatingSavings.value
                                  ? Colors.grey
                                  : Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: comparisonCtrl.isCreatingSavings.value
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'purchase_confirm_show_graph'.tr,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
