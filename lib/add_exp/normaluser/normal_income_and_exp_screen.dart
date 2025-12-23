import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:your_expense/Analytics/expense_controller.dart';
import 'package:your_expense/models/category_model.dart';

// Import your ThemeController

import '../../Settings/appearance/ThemeController.dart';
import '../../Settings/premium/paymentui.dart';
import '../../home/home_controller.dart';
import '../../make it pro/AdvertisementPage/add_ui.dart';
import '../../routes/app_routes.dart';
import 'package:intl/intl.dart';
import 'package:your_expense/Analytics/income_service.dart';
import 'package:your_expense/services/api_base_service.dart'; // Add this import
import 'package:your_expense/services/config_service.dart'; // Add this import
import 'package:your_expense/services/ocr_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:your_expense/Analytics/expense_model.dart';
import 'package:your_expense/services/subscription_service.dart';

class AppColors {
  static const Color text900 = Color(0xFF1E1E1E);
  static const Color text50 = Color(0xFFFAFAFA);
  static const Color primary = Colors.blueAccent;
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color green = Colors.green;
  static const Color orange = Colors.orange;
  static const Color purple = Colors.purple;
  static const Color yellow = Color(0xFFFFD700);
  static const Color expenseButtonIcon = Colors.black;
  static const Color expenseButtonBackground = Colors.yellow;
  static const Color incomeButtonIcon = Colors.black;
  static const Color incomeButtonBackground = Colors.green;
}

class AppStyles {
  static TextStyle sectionHeader(bool isDarkMode) => GoogleFonts.inter(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: isDarkMode ? Colors.white : AppColors.text900,
  );

  static TextStyle buttonText(bool isDarkMode) => GoogleFonts.inter(
    fontSize: 12,
    color: isDarkMode ? Colors.white : AppColors.text900,
  );

  static TextStyle saveButtonText(bool isDarkMode) => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: isDarkMode ? Colors.white : Colors.black,
  );

  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );
  static const EdgeInsets iconPadding = EdgeInsets.all(12);
  static const double defaultRadius = 12.0;
}

class ReceiptButton extends StatefulWidget {
  // Changed to Stateful for loading state if needed
  final String iconPath;
  final String label;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool isDarkMode;
  final VoidCallback onTap; // Added onTap prop

  const ReceiptButton({
    super.key,
    required this.iconPath,
    required this.label,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.isDarkMode,
    required this.onTap, // Required now
  });

  @override
  State<ReceiptButton> createState() => _ReceiptButtonState();
}

class _ReceiptButtonState extends State<ReceiptButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: widget.borderColor, width: 1.5),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      widget.iconPath,
                      color: widget.iconColor,
                      width: 30,
                      height: 30,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.error,
                          color: widget.isDarkMode ? Colors.white : Colors.red,
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(widget.label.tr, style: AppStyles.buttonText(widget.isDarkMode)),
        ],
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDarkMode;

  const CategoryItem({
    super.key,
    required this.iconPath,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: AppStyles.iconPadding,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDarkMode
                          ? const Color(0xFF2A2A2A)
                          : AppColors.grey200),
                borderRadius: BorderRadius.circular(AppStyles.defaultRadius),
              ),
              child: Image.asset(
                iconPath,
                color: isSelected
                    ? AppColors.text50
                    : (isDarkMode ? Colors.white : AppColors.text900),
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.error,
                    color: isDarkMode ? Colors.white : Colors.red,
                  );
                },
              ),
            ),
            const SizedBox(height: 5),
            Text(label.tr, style: AppStyles.buttonText(isDarkMode)),
          ],
        ),
      ),
    );
  }
}

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  int _selectedIndex = 0;
  final themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _selectedIndex = args != null ? (args['initialIndex'] ?? 0) : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => DefaultTabController(
        length: 2,
        initialIndex: _selectedIndex,
        child: Scaffold(
          backgroundColor: themeController.isDarkModeActive
              ? const Color(0xFF121212)
              : AppColors.text50,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: themeController.isDarkModeActive
                    ? Colors.white
                    : Colors.black,
              ),
              onPressed: Get.back,
            ),
            title: Text(
              _selectedIndex == 0 ? 'addExpense'.tr : 'addIncome'.tr,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: themeController.isDarkModeActive
                    ? Colors.white
                    : AppColors.text900,
              ),
            ),
            centerTitle: true,
            backgroundColor: themeController.isDarkModeActive
                ? const Color(0xFF1E1E1E)
                : AppColors.text50,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: themeController.isDarkModeActive
                        ? const Color(0xFF2A2A2A)
                        : AppColors.grey200,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: AppColors.primary,
                    ),
                    labelColor: AppColors.text50,
                    unselectedLabelColor: themeController.isDarkModeActive
                        ? Colors.white
                        : AppColors.text900,
                    onTap: (index) => setState(() => _selectedIndex = index),
                    tabs: [
                      Tab(text: 'expense'.tr),
                      Tab(text: 'income'.tr),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: TabBarView(
            children: [
              ExpensePage(isDarkMode: themeController.isDarkModeActive),
              IncomePage(isDarkMode: themeController.isDarkModeActive),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpensePage extends StatefulWidget {
  final bool isDarkMode;

  const ExpensePage({super.key, required this.isDarkMode});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  int _selectedCategoryIndex = 0;
  int _selectedPaymentIndex = 0;
  final ScrollController _categoryController = ScrollController();
  final ScrollController _paymentController = ScrollController();
  final ExpenseController _expenseController = Get.find();
  final TextEditingController _amountController = TextEditingController();
  final ApiBaseService _apiService =
      Get.find<ApiBaseService>(); // Add API service
  final ConfigService _configService =
      Get.find<ConfigService>(); // Add config service
  bool _isSavingExpense = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Categories from CategoryModel
  // late final List<Map<String, String>> _expenseCategories;
  List<Map<String, String>> _expenseCategories = [];

  @override
  void initState() {
    super.initState();
    // Initialize with static categories for immediate UI, then overwrite with backend
    _expenseCategories = CategoryModel.getExpenseCategories()
        .map((c) => {'name': c.name, 'iconPath': c.icon})
        .toList();
    if (!Get.isRegistered<OcrService>()) {
      Get.put(OcrService()).init();
    }
    _ocrService = Get.find<OcrService>();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _paymentController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final DateTime initialDate = _selectedDate ?? DateTime.now();
    final TimeOfDay initialTime = _selectedTime ?? TimeOfDay.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate != null) {
      // Prompt for time but don't discard date if time is cancelled
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );
      
      setState(() {
        _selectedDate = pickedDate;
        if (pickedTime != null) {
          _selectedTime = pickedTime;
        }
      });
    }
  }

  Future<void> _handleOcrRaw(String rawText) async {
    try {
      final response = await _apiService.request(
        'POST',
        _configService.ocrRawEndpoint,
        body: {'rawText': rawText},
        requiresAuth: true,
      );

      if (response['success'] == true) {
        Get.snackbar(
          'success'.tr,
          'Expense created from raw OCR text'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        // Optionally clear fields or refresh
        _amountController.clear();
      } else {
        Get.snackbar(
          'error'.tr,
          response['message'] ?? 'ocrError'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'apiError'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // OCR handlers for ExpensePage
  late final OcrService _ocrService;
  var _isProcessingOCR = false.obs;

  Future<void> _processOCRFromCamera() async {
    final sub = Get.find<SubscriptionService>();
    if (!sub.isActivePro) {
      _showProGateDialog(isExpense: true);
      return;
    }
    try {
      _isProcessingOCR.value = true;
      // Web fallback: ask for manual text
      if (kIsWeb) {
        await _promptAndProcessRawText();
        return;
      }
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image == null) {
        _isProcessingOCR.value = false;
        return;
      }
      final rawText = await _ocrService.extractTextFromImagePath(image.path);
      if ((rawText ?? '').trim().isEmpty) {
        Get.snackbar('warning'.tr, 'noTextFound'.tr);
        await _promptAndProcessRawText();
        return;
      }
      await _handleOcrRawText(rawText!.trim());
    } catch (e) {
      Get.snackbar('error'.tr, 'cameraOcrFailed'.tr);
    } finally {
      _isProcessingOCR.value = false;
    }
  }

  Future<void> _processOCRFromGallery() async {
    final sub = Get.find<SubscriptionService>();
    if (!sub.isActivePro) {
      _showProGateDialog(isExpense: true);
      return;
    }
    try {
      _isProcessingOCR.value = true;
      if (kIsWeb) {
        await _promptAndProcessRawText();
        return;
      }
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) {
        _isProcessingOCR.value = false;
        return;
      }
      final rawText = await _ocrService.extractTextFromImagePath(image.path);
      if ((rawText ?? '').trim().isEmpty) {
        Get.snackbar('warning'.tr, 'noTextFound'.tr);
        await _promptAndProcessRawText();
        return;
      }
      await _handleOcrRawText(rawText!.trim());
    } catch (e) {
      Get.snackbar('error'.tr, 'galleryOcrFailed'.tr);
    } finally {
      _isProcessingOCR.value = false;
    }
  }

  void _showProGateDialog({required bool isExpense}) {
    Get.dialog(
      Dialog(
        backgroundColor: widget.isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, color: const Color(0xFF2196F3), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'upgradeToProToView'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'graphsAndReports'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isDarkMode
                          ? Colors.white70
                          : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back();
                            Get.toNamed(AppRoutes.premiumPlans);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                          ),
                          child: Text('upgrade_now'.tr),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Get.back();
                            Get.toNamed(
                              AppRoutes.advertisement,
                              arguments: {'isFromExpense': isExpense},
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2196F3)),
                          ),
                          child: Text('watchVideoToUnlock'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                ),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }

  Future<void> _promptAndProcessRawText({String? title}) async {
    final textController = TextEditingController();
    await Get.defaultDialog(
      title: title ?? 'enterReceiptText'.tr,
      content: Column(
        children: [
          Text('pasteReceiptText'.tr),
          const SizedBox(height: 8),
          TextField(
            controller: textController,
            maxLines: 6,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () async {
          final text = textController.text.trim();
          if (text.isEmpty) {
            Get.snackbar('error'.tr, 'textEmpty'.tr);
            return;
          }
          Get.back();
          await _handleOcrRawText(text);
        },
        child: Text('post'.tr),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
    );
  }

  Future<void> _handleOcrRawText(String rawText) async {
    try {
      _isProcessingOCR.value = true;
      final resp = await _ocrService.processOCR(rawText);
      if (resp['success'] != true) {
        Get.snackbar('warning'.tr, 'ocrUnableExtract'.tr);
        return;
      }
      final data = resp['data'] as Map<String, dynamic>?;
      if (data == null) {
        Get.snackbar('warning'.tr, 'noDataReturned'.tr);
        return;
      }
      final item = ExpenseItem.fromJson(data);
      _expenseController.allExpenses.insert(0, item);
      _expenseController.applyMonthFilter();
      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();
        final source = (data['source']?.toString() ?? '').isNotEmpty
            ? data['source'].toString()
            : (data['category']?.toString() ?? 'Expense');
        final amountStr = (data['amount'] ?? 0).toString();
        home.addTransaction(source, amountStr, false);
        Future(() async {
          try {
            await home.fetchBudgetData();
            await home.fetchRecentTransactions();
          } catch (_) {}
        });
      }
      Get.snackbar(
        'success'.tr,
        'ocrExpenseCreated'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'ocrRequestFailed'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isProcessingOCR.value = false;
    }
  }

  String _iconForCategoryName(String name) {
    final match = CategoryModel.getExpenseCategories().firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => CategoryModel(
        name: name,
        icon: 'assets/icons/money.png',
        type: 'expense',
      ),
    );
    return match.icon;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: AppStyles.defaultPadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'scanOrUploadReceipt'.tr,
                  style: AppStyles.sectionHeader(widget.isDarkMode),
                ),
                const SizedBox(height: 10),
                _buildReceiptButtons(),
                const SizedBox(height: 20),
                _buildCategorySection(),
                const SizedBox(height: 20),
                _buildAddCustomCategory(),
                const SizedBox(height: 20),
                _buildAmountSection(),
                const SizedBox(height: 20),
                SizedBox.shrink(),
                const SizedBox(height: 20),
                _buildDateTimeSection(),
                const SizedBox(height: 20),
                _buildUpgradeButtons(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptButtons({bool isExpense = false}) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ReceiptButton(
            iconPath: 'assets/icons/cameraoc.png',
            label: 'camera'.tr,
            iconColor: AppColors.expenseButtonIcon,
            backgroundColor: AppColors.expenseButtonBackground,
            borderColor: Colors.black.withOpacity(0.3),
            isDarkMode: widget.isDarkMode,
            onTap: () => _processOCRFromCamera(),
          ),
          ReceiptButton(
            iconPath: 'assets/icons/galleryoc.png',
            label: 'gallery'.tr,
            iconColor: AppColors.expenseButtonIcon,
            backgroundColor: AppColors.expenseButtonBackground,
            borderColor: Colors.black.withOpacity(0.3),
            isDarkMode: widget.isDarkMode,
            onTap: () => _processOCRFromGallery(),
          ),
        ],
      ),
    );
  }

  // ... (rest of the methods remain the same as in the original code, except for _buildUpgradeButtons where you can add similar for income if needed)
  Widget _buildCategorySection() {
    final items = _expenseCategories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'selectCategory'.tr,
          style: AppStyles.sectionHeader(widget.isDarkMode),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            controller: _categoryController,
            scrollDirection: Axis.horizontal,
            itemCount: items.length + 2,
            itemBuilder: (context, index) {
              if (index == 0 || index == items.length + 1) {
                return const SizedBox(width: 8);
              }
              final i = index - 1;
              final cat = items[i];
              final label = cat['name']!;
              final iconPath = cat['iconPath']!;
              return CategoryItem(
                iconPath: iconPath,
                label: label,
                isSelected: _selectedCategoryIndex == i,
                onTap: () => setState(() => _selectedCategoryIndex = i),
                isDarkMode: widget.isDarkMode,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddCustomCategory() {
    return Container(
      padding: AppStyles.defaultPadding,
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF2A2A2A) : AppColors.grey200,
        borderRadius: BorderRadius.circular(AppStyles.defaultRadius),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'addCustomCategory'.tr,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                color: widget.isDarkMode ? Colors.grey[400] : AppColors.grey500,
                size: 16,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  'proFeatureOnly'.tr,
                  style: GoogleFonts.inter(
                    color: widget.isDarkMode
                        ? Colors.grey[400]
                        : AppColors.grey500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('amount'.tr, style: AppStyles.sectionHeader(widget.isDarkMode)),
        const SizedBox(height: 10),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'enterAmount'.tr,
            hintStyle: GoogleFonts.inter(
              color: widget.isDarkMode ? Colors.grey[400] : AppColors.grey500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.defaultRadius),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.defaultRadius),
              borderSide: BorderSide(
                color: widget.isDarkMode
                    ? const Color(0xFF444444)
                    : AppColors.grey200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.defaultRadius),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: AppStyles.buttonPadding,
            filled: widget.isDarkMode,
            fillColor: widget.isDarkMode
                ? const Color(0xFF2A2A2A)
                : Colors.transparent,
          ),
          style: GoogleFonts.inter(
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'paymentMethod'.tr,
          style: AppStyles.sectionHeader(widget.isDarkMode),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView(
            controller: _paymentController,
            scrollDirection: Axis.horizontal,
            children: [
              const SizedBox(width: 8),
              CategoryItem(
                iconPath: 'assets/icons/cashoc.png',
                label: 'cash'.tr,
                isSelected: _selectedPaymentIndex == 0,
                onTap: () => setState(() => _selectedPaymentIndex = 0),
                isDarkMode: widget.isDarkMode,
              ),
              const SizedBox(width: 20),
              CategoryItem(
                iconPath: 'assets/icons/mobileoc.png',
                label: 'mobile'.tr,
                isSelected: _selectedPaymentIndex == 1,
                onTap: () => setState(() => _selectedPaymentIndex = 1),
                isDarkMode: widget.isDarkMode,
              ),
              const SizedBox(width: 20),
              CategoryItem(
                iconPath: 'assets/icons/bankoc.png',
                label: 'bank'.tr,
                isSelected: _selectedPaymentIndex == 2,
                onTap: () => setState(() => _selectedPaymentIndex = 2),
                isDarkMode: widget.isDarkMode,
              ),
              const SizedBox(width: 20),
              CategoryItem(
                iconPath: 'assets/icons/cardoc.png',
                label: 'card'.tr,
                isSelected: _selectedPaymentIndex == 3,
                onTap: () => setState(() => _selectedPaymentIndex = 3),
                isDarkMode: widget.isDarkMode,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    final DateTime now = DateTime.now();
    final String defaultLabel = DateFormat('yyyy-MM-dd HH:mm').format(now);
    final DateTime? picked = (_selectedDate != null)
        ? DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            (_selectedTime ?? TimeOfDay.now()).hour,
            (_selectedTime ?? TimeOfDay.now()).minute,
          )
        : null;
    final String pickedLabel = picked != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(picked)
        : 'tapToSet'.tr;

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'default'.tr,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: widget.isDarkMode ? Colors.white : AppColors.text900,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: AppStyles.buttonPadding,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppStyles.defaultRadius),
                ),
                child: Center(
                  child: Text(
                    defaultLabel,
                    style: GoogleFonts.inter(
                      color: AppColors.text50,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'setDateTime'.tr,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: widget.isDarkMode ? Colors.white : AppColors.text900,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectDateTime,
                child: Container(
                  padding: AppStyles.buttonPadding,
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? const Color(0xFF2A2A2A)
                        : AppColors.grey200,
                    borderRadius: BorderRadius.circular(
                      AppStyles.defaultRadius,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      pickedLabel,
                      style: GoogleFonts.inter(
                        color: widget.isDarkMode
                            ? Colors.white
                            : AppColors.text900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeButtons() {
    return Column(
      children: [
        _buildUpgradeButton(
          icon: Icons.play_circle_outline,
          text: 'watchVideoForFree'.tr,
          color: AppColors.primary.withOpacity(0.1),
          borderColor: AppColors.primary,
        ),
        const SizedBox(height: 10),
        _buildUpgradeButton(
          icon: Icons.check_circle_outline,
          text: 'upgradeToPro'.tr,
          color: widget.isDarkMode
              ? const Color(0xFF2A2A2A)
              : AppColors.grey200,
          borderColor: widget.isDarkMode
              ? Colors.grey[600]!
              : AppColors.grey500,
        ),
        const SizedBox(height: 10),
        _buildAddButton(), // New Add button added here
      ],
    );
  }

  Widget _buildUpgradeButton({
    required IconData icon,
    required String text,
    required Color color,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: () async {
        if (text.contains('watchVideoForFree'.tr)) {
          final result = await Get.to<bool>(
            () => AdvertisementPage(isFromExpense: true),
            routeName: AppRoutes.advertisement,
          );

          if (result == true) {
            Get.offNamed(
              AppRoutes.proExpensesIncome,
              arguments: {'defaultTab': 0},
            );
          }
        } else if (text.contains('upgradeToPro'.tr)) {
          Get.to(() => PremiumPlansScreen());
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppStyles.defaultRadius),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: borderColor == AppColors.primary
                  ? AppColors.primary
                  : (widget.isDarkMode ? Colors.white : AppColors.text900),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: borderColor == AppColors.primary
                      ? AppColors.primary
                      : (widget.isDarkMode ? Colors.white : AppColors.text900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New Add button method
  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () async {
        if (_isSavingExpense) return;
        final text = _amountController.text.trim();
        if (text.isEmpty) {
          Get.snackbar(
            'error'.tr,
            'enterAmountError'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        final amount = double.tryParse(text);
        if (amount == null) {
          Get.snackbar(
            'error'.tr,
            'enterAmountError'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        final index = _selectedCategoryIndex.clamp(
          0,
          _expenseCategories.length - 1,
        );
        final categoryName = _expenseCategories[index]['name']!;
        DateTime effectiveDate;
        if (_selectedDate != null) {
          final time = _selectedTime ?? TimeOfDay.now();
          effectiveDate = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            time.hour,
            time.minute,
          );
        } else {
          effectiveDate = DateTime.now();
        }
        setState(() {
          _isSavingExpense = true;
        });
        try {
          final success = await _expenseController.addExpense(
            amount: amount,
            category: categoryName,
            note: categoryName,
            date: effectiveDate,
          );
          if (success) {
            Get.snackbar(
              'success'.tr,
              'transactionSuccess'.tr,
              snackPosition: SnackPosition.BOTTOM,
            );
            _amountController.clear();
            setState(() {
              _selectedDate = null;
              _selectedTime = null;
            });
          } else {
            final msg = _expenseController.errorMessage.value.isNotEmpty
                ? _expenseController.errorMessage.value
                : 'transactionError'.tr;
            Get.snackbar('error'.tr, msg, snackPosition: SnackPosition.BOTTOM);
          }
        } finally {
          setState(() {
            _isSavingExpense = false;
          });
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppStyles.defaultRadius),
          border: Border.all(color: AppColors.green),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _isSavingExpense
              ? [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ]
              : [
                  Icon(Icons.add, color: AppColors.green),
                  const SizedBox(width: 8),
                  Text(
                    'add'.tr,
                    style: GoogleFonts.inter(
                      color: AppColors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}

// Similar updates for IncomePage
class IncomePage extends StatefulWidget {
  final bool isDarkMode;

  const IncomePage({super.key, required this.isDarkMode});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  int _selectedCategoryIndex = 0;
  int _selectedPaymentIndex = 0;
  final ScrollController _categoryController = ScrollController();
  final ScrollController _paymentController = ScrollController();
  final IncomeService _incomeService = Get.find();
  final TextEditingController _incomeAmountController = TextEditingController();
  final ApiBaseService _apiService =
      Get.find<ApiBaseService>(); // Add API service
  final ConfigService _configService =
      Get.find<ConfigService>(); // Add config service
  bool _isSavingIncome = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Categories from CategoryModel
  late final List<Map<String, String>> _incomeCategories;

  @override
  void initState() {
    super.initState();
    _incomeCategories = CategoryModel.getIncomeCategories()
        .map((c) => {'name': c.name, 'iconPath': c.icon})
        .toList();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _paymentController.dispose();
    _incomeAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final DateTime initialDate = _selectedDate ?? DateTime.now();
    final TimeOfDay initialTime = _selectedTime ?? TimeOfDay.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );
      
      setState(() {
        _selectedDate = pickedDate;
        if (pickedTime != null) {
          _selectedTime = pickedTime;
        }
      });
    }
  }

  Future<void> _handleOcrRaw(String rawText) async {
    // Income OCR is not supported currently; show notice and exit
    Get.snackbar(
      'info'.tr,
      'ocrSupportsExpensesOnly'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
    return;
  }

  Future<void> _simulateOcr(String option) async {
    final sub = Get.find<SubscriptionService>();
    if (!sub.isActivePro) {
      _showProGateDialogIncome();
      return;
    }
    String rawText = "income: salary, amount tk 5000 received on oct 2025";
    // TODO: Implement actual OCR using google_ml_kit or similar for camera/gallery
    // For barcode, use barcode scanner package to get code, then format as rawText
    await Future.delayed(const Duration(seconds: 2)); // Simulate processing
    await _handleOcrRaw(rawText);
  }

  void _showProGateDialogIncome() {
    final isDark = widget.isDarkMode;
    Get.dialog(
      Dialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, color: const Color(0xFF2196F3), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'upgradeToProToView'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'graphsAndReports'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back();
                            Get.toNamed(AppRoutes.premiumPlans);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                          ),
                          child: Text('upgrade_now'.tr),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Get.back();
                            Get.toNamed(
                              AppRoutes.advertisement,
                              arguments: {'isFromExpense': false},
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2196F3)),
                          ),
                          child: Text('watchVideoToUnlock'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: AppStyles.defaultPadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'scanOrUploadReceipt'.tr,
                  style: AppStyles.sectionHeader(widget.isDarkMode),
                ),
                const SizedBox(height: 10),
                _buildReceiptButtons(),
                const SizedBox(height: 20),
                _buildCategorySection(),
                const SizedBox(height: 20),
                _buildAddCustomCategory(),
                const SizedBox(height: 20),
                _buildAmountSection(),
                const SizedBox(height: 20),
                SizedBox.shrink(),
                const SizedBox(height: 20),
                _buildDateTimeSection(),
                const SizedBox(height: 20),
                _buildUpgradeButtons(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptButtons() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ReceiptButton(
            iconPath: 'assets/icons/cameraoc.png',
            label: 'camera'.tr,
            iconColor: AppColors.incomeButtonIcon,
            backgroundColor: AppColors.incomeButtonBackground,
            borderColor: Colors.black.withOpacity(0.3),
            isDarkMode: widget.isDarkMode,
            onTap: () => _simulateOcr('camera'), // Added onTap
          ),
          ReceiptButton(
            iconPath: 'assets/icons/galleryoc.png',
            label: 'gallery'.tr,
            iconColor: AppColors.incomeButtonIcon,
            backgroundColor: AppColors.incomeButtonBackground,
            borderColor: Colors.black.withOpacity(0.3),
            isDarkMode: widget.isDarkMode,
            onTap: () => _simulateOcr('gallery'), // Added onTap
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    final items = _incomeCategories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'selectCategory'.tr,
          style: AppStyles.sectionHeader(widget.isDarkMode),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            controller: _categoryController,
            scrollDirection: Axis.horizontal,
            itemCount: items.length + 2,
            itemBuilder: (context, index) {
              if (index == 0 || index == items.length + 1) {
                return const SizedBox(width: 8);
              }
              final i = index - 1;
              final cat = items[i];
              final label = cat['name']!;
              final iconPath = cat['iconPath']!;
              return CategoryItem(
                iconPath: iconPath,
                label: label.tr,
                isSelected: _selectedCategoryIndex == i,
                onTap: () => setState(() => _selectedCategoryIndex = i),
                isDarkMode: widget.isDarkMode,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddCustomCategory() {
    return Container(
      padding: AppStyles.defaultPadding,
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF2A2A2A) : AppColors.grey200,
        borderRadius: BorderRadius.circular(AppStyles.defaultRadius),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'addCustomCategory'.tr,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                color: widget.isDarkMode ? Colors.grey[400] : AppColors.grey500,
                size: 16,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  'proFeatureOnly'.tr,
                  style: GoogleFonts.inter(
                    color: widget.isDarkMode
                        ? Colors.grey[400]
                        : AppColors.grey500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('amount'.tr, style: AppStyles.sectionHeader(widget.isDarkMode)),
        const SizedBox(height: 10),
        TextField(
          controller: _incomeAmountController,
          decoration: InputDecoration(
            hintText: 'enterAmount'.tr,
            hintStyle: GoogleFonts.inter(
              color: widget.isDarkMode ? Colors.grey[400] : AppColors.grey500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.defaultRadius),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.defaultRadius),
              borderSide: BorderSide(
                color: widget.isDarkMode
                    ? const Color(0xFF444444)
                    : AppColors.grey200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.defaultRadius),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: AppStyles.buttonPadding,
            filled: widget.isDarkMode,
            fillColor: widget.isDarkMode
                ? const Color(0xFF2A2A2A)
                : Colors.transparent,
          ),
          style: GoogleFonts.inter(
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'paymentMethod'.tr,
          style: AppStyles.sectionHeader(widget.isDarkMode),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView(
            controller: _paymentController,
            scrollDirection: Axis.horizontal,
            children: [
              const SizedBox(width: 8),
              CategoryItem(
                iconPath: 'assets/icons/cashoc.png',
                label: 'cash'.tr,
                isSelected: _selectedPaymentIndex == 0,
                onTap: () => setState(() => _selectedPaymentIndex = 0),
                isDarkMode: widget.isDarkMode,
              ),
              const SizedBox(width: 20),
              CategoryItem(
                iconPath: 'assets/icons/mobileoc.png',
                label: 'mobile'.tr,
                isSelected: _selectedPaymentIndex == 1,
                onTap: () => setState(() => _selectedPaymentIndex = 1),
                isDarkMode: widget.isDarkMode,
              ),
              const SizedBox(width: 20),
              CategoryItem(
                iconPath: 'assets/icons/bankoc.png',
                label: 'bank'.tr,
                isSelected: _selectedPaymentIndex == 2,
                onTap: () => setState(() => _selectedPaymentIndex = 2),
                isDarkMode: widget.isDarkMode,
              ),
              const SizedBox(width: 20),
              CategoryItem(
                iconPath: 'assets/icons/cardoc.png',
                label: 'card'.tr,
                isSelected: _selectedPaymentIndex == 3,
                onTap: () => setState(() => _selectedPaymentIndex = 3),
                isDarkMode: widget.isDarkMode,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    final DateTime now = DateTime.now();
    final String defaultLabel = DateFormat('yyyy-MM-dd HH:mm').format(now);
    final DateTime? picked = (_selectedDate != null)
        ? DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            (_selectedTime ?? TimeOfDay.now()).hour,
            (_selectedTime ?? TimeOfDay.now()).minute,
          )
        : null;
    final String pickedLabel = picked != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(picked)
        : 'tapToSet'.tr;

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'default'.tr,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: widget.isDarkMode ? Colors.white : AppColors.text900,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: AppStyles.buttonPadding,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppStyles.defaultRadius),
                ),
                child: Center(
                  child: Text(
                    defaultLabel,
                    style: GoogleFonts.inter(
                      color: AppColors.text50,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'setDateTime'.tr,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: widget.isDarkMode ? Colors.white : AppColors.text900,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectDateTime,
                child: Container(
                  padding: AppStyles.buttonPadding,
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? const Color(0xFF2A2A2A)
                        : AppColors.grey200,
                    borderRadius: BorderRadius.circular(
                      AppStyles.defaultRadius,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      pickedLabel,
                      style: GoogleFonts.inter(
                        color: widget.isDarkMode
                            ? Colors.white
                            : AppColors.text900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeButtons() {
    return Column(
      children: [
        _buildUpgradeButton(
          icon: Icons.play_circle_outline,
          text: 'watchVideoForFree'.tr,
          color: AppColors.primary.withOpacity(0.1),
          borderColor: AppColors.primary,
        ),
        const SizedBox(height: 10),
        _buildUpgradeButton(
          icon: Icons.check_circle_outline,
          text: 'upgradeToPro'.tr,
          color: widget.isDarkMode
              ? const Color(0xFF2A2A2A)
              : AppColors.grey200,
          borderColor: widget.isDarkMode
              ? Colors.grey[600]!
              : AppColors.grey500,
        ),
        const SizedBox(height: 10),
        _buildAddButton(), // New Add button added here
      ],
    );
  }

  Widget _buildUpgradeButton({
    required IconData icon,
    required String text,
    required Color color,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: () async {
        if (text.contains('watchVideoForFree'.tr)) {
          final result = await Get.to<bool>(
            () => AdvertisementPage(isFromExpense: false),
            routeName: AppRoutes.advertisement,
          );

          if (result == true) {
            Get.offNamed(
              AppRoutes.proExpensesIncome,
              arguments: {'defaultTab': 1},
            );
          }
        } else if (text.contains('upgradeToPro'.tr)) {
          Get.to(() => PremiumPlansScreen());
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppStyles.defaultRadius),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: borderColor == AppColors.primary
                  ? AppColors.primary
                  : (widget.isDarkMode ? Colors.white : AppColors.text900),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  color: borderColor == AppColors.primary
                      ? AppColors.primary
                      : (widget.isDarkMode ? Colors.white : AppColors.text900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New Add button method
  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () async {
        if (_isSavingIncome) return;
        final text = _incomeAmountController.text.trim();
        if (text.isEmpty) {
          Get.snackbar(
            'error'.tr,
            'enterAmountError'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        final amount = double.tryParse(text);
        if (amount == null || amount <= 0) {
          Get.snackbar(
            'error'.tr,
            'enterAmountError'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        final index = _selectedCategoryIndex.clamp(
          0,
          _incomeCategories.length - 1,
        );
        final source = _incomeCategories[index]['name']!;
        DateTime effectiveDate;
        if (_selectedDate != null) {
          final time = _selectedTime ?? TimeOfDay.now();
          effectiveDate = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            time.hour,
            time.minute,
          );
        } else {
          effectiveDate = DateTime.now();
        }
        setState(() {
          _isSavingIncome = true;
        });
        try {
          await _incomeService.createIncome(
            source: source,
            amount: amount,
            date: effectiveDate,
          );
          try {
            final home = Get.find<HomeController>();
            home.addTransaction(source, amount.toStringAsFixed(0), true);
            await home.fetchBudgetData();
            await home.fetchRecentTransactions();
          } catch (_) {}
          Get.snackbar(
            'success'.tr,
            'transactionSuccess'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
          _incomeAmountController.clear();
          setState(() {
            _selectedDate = null;
            _selectedTime = null;
          });
        } catch (e) {
          Get.snackbar(
            'error'.tr,
            'transactionError'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
        } finally {
          setState(() {
            _isSavingIncome = false;
          });
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppStyles.defaultRadius),
          border: Border.all(color: AppColors.green),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _isSavingIncome
              ? [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ]
              : [
                  Icon(Icons.add, color: AppColors.green),
                  const SizedBox(width: 8),
                  Text(
                    'add'.tr, // Make sure you have this translation key
                    style: GoogleFonts.inter(
                      color: AppColors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}
