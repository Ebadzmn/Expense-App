import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import '../Settings/appearance/ThemeController.dart';

import '../home/home_controller.dart';
import '../reuseablenav/reuseablenavui.dart';
import 'ComparisonPageController.dart';

class ComparisonPageScreen extends StatefulWidget {
  final bool isFromExpense;

  const ComparisonPageScreen({super.key, required this.isFromExpense});

  @override
  State<ComparisonPageScreen> createState() => _ComparisonPageScreenState();
}

class _ComparisonPageScreenState extends State<ComparisonPageScreen> {
  late final TextEditingController productNameController;
  late final TextEditingController maxPriceController;
  late final ComparisonPageController comparisonCtrl;

  @override
  void initState() {
    super.initState();
    productNameController = TextEditingController();
    maxPriceController = TextEditingController();
    // Ensure a single instance across rebuilds
    comparisonCtrl = Get.put(ComparisonPageController());

    // Position nav selection after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeCtrl = Get.find<HomeController>();
      if (homeCtrl.selectedNavIndex.value != 2) {
        homeCtrl.selectedNavIndex.value = 2;
      }
    });
  }

  @override
  void dispose() {
    productNameController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final bool isDarkMode = themeController.isDarkModeActive;
    final Color backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDarkMode ? Colors.white : Colors.black,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
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
      body: SingleChildScrollView(
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
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: productNameController,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  hintText: 'Enter product name',
                  hintStyle: TextStyle(color: isDarkMode ? Colors.grey[500] : Colors.grey),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            // Max Price Field
            Text(
              'Max Price',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: maxPriceController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: '\$ Enter amount',
                  hintStyle: TextStyle(color: isDarkMode ? Colors.grey[500] : Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            // Search Button
            Obx(() => SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: comparisonCtrl.isLoading.value
                    ? null
                    : () async {
                  if (productNameController.text.isEmpty) {
                    Get.snackbar(
                      'Error',
                      'Please enter a product name',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  final price = double.tryParse(maxPriceController.text) ?? 0.0;
                  if (price <= 0) {
                    Get.snackbar(
                      'Error',
                      'Please enter a valid price',
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 20,
                ),
                label: comparisonCtrl.isLoading.value
                    ? Text(
                  'Searching...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                )
                    : Text(
                  'Search',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )),
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
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    comparisonCtrl.errorMessage.value,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                );
              }
              return SizedBox();
            }),

            // Results Section
            Obx(() {
              if (comparisonCtrl.deals.isEmpty && !comparisonCtrl.isLoading.value) {
                // Empty state message when no deals are found
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF333333) : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: isDarkMode ? Colors.white : Colors.black54,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'No deals found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Try a different product name or increase max price.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
                    'Better Deals Found (${comparisonCtrl.deals.length})',
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
                    ...comparisonCtrl.deals.map((deal) =>
                        _buildDealCard(
                            context,
                            isDarkMode,
                            screenWidth,
                            screenHeight,
                            deal,
                            comparisonCtrl.currentSearchTerm.value,
                            comparisonCtrl.maxPrice.value
                        )
                    ),

                  SizedBox(height: screenHeight * 0.02),
                ],
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        isDarkMode: isDarkMode,
      ),
    );
  }

  Widget _buildDealCard(BuildContext context, bool isDarkMode, double screenWidth, double screenHeight, dynamic deal, String searchTerm, double maxPrice) {
    final siteName = deal['siteName'] ?? 'Unknown Site';
    final title = deal['title'] ?? '';
    final price = (deal['price'] ?? 0.0).toDouble();
    final imageUrl = deal['image'] ?? '';
    final rating = (deal['rating'] ?? 0.0).toDouble();
    final url = deal['url'] ?? '';
    final dealType = deal['type'] ?? 'generic';

    // Use the actual searched product name
    String displayTitle = searchTerm;

    // Calculate percentage savings
    double savingsPercentage = 0.0;
    bool hasSavings = false;

    if (maxPrice > 0 && price > 0 && price < maxPrice) {
      savingsPercentage = ((maxPrice - price) / maxPrice) * 100;
      hasSavings = true;
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!),
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
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
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
                          color: isDarkMode ? Colors.grey[800]! : Colors.grey[100],
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
                              Text(
                                siteName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : Colors.black,
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
                                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
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
                              color: isDarkMode ? Colors.grey[300] : Colors.black87,
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

                    // Savings Badge - Different logic for generic vs specific
                    if (dealType == 'specific' && hasSavings)
                    // For specific deals with savings, show percentage
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Save ${savingsPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (dealType == 'specific')
                    // For specific deals without savings, show price badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    // For generic deals, always show "Best Deal"
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Best Deal',
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
                          _showCompareDialog(context, isDarkMode, deal, maxPrice, price, searchTerm);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, 36),
                        ),
                        icon: _buildCompareIcon(isDarkMode),
                        label: Text(
                          'Compare',
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
                          'Copy Link',
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
  void _copyToClipboard(String text, String siteName) {
    if (text.isEmpty) {
      Get.snackbar(
        'Error',
        'No link available to copy',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      Clipboard.setData(ClipboardData(text: text));
      Get.snackbar(
        'Success',
        'Product link from $siteName copied to clipboard',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
      print('📋 Copied to clipboard: $text');
    } catch (e) {
      print('❌ Error copying to clipboard: $e');
      Get.snackbar(
        'Error',
        'Failed to copy link: $e',
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
              return Icon(
                Icons.compare_arrows,
                size: 20,
                color: Colors.blue,
              );
            },
          );
        },
      );
    } catch (e) {
      return Icon(
        Icons.compare_arrows,
        size: 20,
        color: Colors.blue,
      );
    }
  }

  // Updated Show compare dialog with product name
  void _showCompareDialog(BuildContext context, bool isDarkMode, dynamic deal, double maxPrice, double actualPrice, String productName) {
    final comparisonCtrl = Get.find<ComparisonPageController>();
    final TextEditingController maxPriceController = TextEditingController(text: maxPrice.toStringAsFixed(2));
    final TextEditingController actualPriceController = TextEditingController(text: actualPrice.toStringAsFixed(2));
    final TextEditingController categoryController = TextEditingController(text: productName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Compare ${deal['siteName']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Max Price Field
                    Text(
                      'Original Price (Max)',
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
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
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
                            color: isDarkMode ? Colors.grey[500] : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Actual Price Field
                    Text(
                      'Price With Tool',
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
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
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
                            color: isDarkMode ? Colors.grey[500] : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Category Field
                    Text(
                      'Product Category',
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
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
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
                          hintText: 'Enter product category',
                          hintStyle: TextStyle(
                            color: isDarkMode ? Colors.grey[500] : Colors.grey,
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
                        color: isDarkMode ? Color(0xFF2D2D2D) : Colors.grey[50]!,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDarkMode ? Colors.green[700]! : Colors.green[200]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Savings Preview',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'You Save:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
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
                    Obx(() => SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: comparisonCtrl.isCreatingSavings.value
                            ? null
                            : () async {
                          // Validate inputs
                          final maxPrice = double.tryParse(maxPriceController.text);
                          final actualPrice = double.tryParse(actualPriceController.text);

                          if (maxPrice == null || maxPrice <= 0) {
                            Get.snackbar(
                              'Error',
                              'Please enter a valid original price',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          if (actualPrice == null || actualPrice <= 0) {
                            Get.snackbar(
                              'Error',
                              'Please enter a valid price with tool',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          if (categoryController.text.isEmpty) {
                            Get.snackbar(
                              'Error',
                              'Please enter a product category',
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
                            'category': categoryController.text.trim(),
                            'productName': productName,
                            'siteName': deal['siteName'],
                            'savingsPercentage': ((maxPrice - actualPrice) / maxPrice * 100).toStringAsFixed(1),
                          };

                          // Call the savings API
                          final success = await comparisonCtrl.createSavingsRecord(
                            category: categoryController.text.trim(),
                            initialPrice: maxPrice,
                            actualPrice: actualPrice,
                          );

                          if (success) {
                            // Close dialog and navigate to comparison graph WITH DATA
                            Navigator.of(context).pop();
                            Get.snackbar(
                              'Success',
                              'Savings record created successfully!',
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                            );
                            // Navigate to comparison graph with the data
                            Get.toNamed('/comparisonGraph', arguments: comparisonData);
                          } else {
                            Get.snackbar(
                              'Error',
                              'Failed to create savings record',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: comparisonCtrl.isCreatingSavings.value
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : Text(
                          'Purchase Confirm and show graph',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}