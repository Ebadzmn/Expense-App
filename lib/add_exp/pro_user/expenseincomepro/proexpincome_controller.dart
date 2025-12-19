import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:your_expense/Analytics/expense_controller.dart';
import 'package:your_expense/models/category_model.dart';
import 'package:your_expense/Analytics/income_service.dart';
import 'package:your_expense/services/ocr_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// google_mlkit_text_recognition does not support web; guarded usage
import 'package:your_expense/services/api_base_service.dart'; // Add this import
import 'package:your_expense/services/config_service.dart'; // Add this import
import 'package:your_expense/Analytics/expense_model.dart';
import 'package:your_expense/home/home_controller.dart';
import 'package:your_expense/services/subscription_service.dart';


class ProExpensesIncomeController extends GetxController {
  // Form Controllers
  late final TextEditingController amountController;
  late final TextEditingController descriptionController;

  // Observable variables
  var currentTab = 0.obs;
  var initialTab = 0;
  var selectedExpenseCategory = ''.obs;
  var selectedIncomeCategory = ''.obs;
  var selectedPaymentMethod = ''.obs;
  var selectedDate = DateTime.now().obs;
  var selectedTime = TimeOfDay.now().obs;
  var isLoading = false.obs;
  var uploadedReceiptPath = ''.obs;
  var isProcessingOCR = false.obs;

  // Pro feature unlocks
  var isExpenseProUnlocked = false.obs;
  var isIncomeProUnlocked = false.obs;

  // Categories loaded from API for expenses
  final expenseCategories = <Map<String, dynamic>>[].obs;

  final incomeCategories = <Map<String, dynamic>>[].obs;

  // Custom name mapping for the 'Other' tiles
  final customExpenseOtherName = ''.obs;
  final customIncomeOtherName = ''.obs;

  final paymentMethods = <Map<String, dynamic>>[
    {'name': 'cash', 'icon': Icons.money},
    {'name': 'mobile', 'icon': Icons.phone_android},
    {'name': 'bank', 'icon': Icons.account_balance},
    {'name': 'card', 'icon': Icons.credit_card},
  ].obs;

  // Resolve dependency lazily to avoid startup ordering issues
  late final ExpenseController _expenseController;
  late final OcrService _ocrService;
  late final ApiBaseService _apiService;
  late final ConfigService _configService;
  late final SubscriptionService _subscriptionService;

  // Inline custom category input state
  final showCustomCategoryInput = false.obs;
  late final TextEditingController customCategoryController;

  @override
  void onInit() {
    super.onInit();
    _expenseController = Get.find<ExpenseController>();
    if (!Get.isRegistered<OcrService>()) {
      Get.put(OcrService()).init();
    }
    _ocrService = Get.find<OcrService>();
    _apiService = Get.find<ApiBaseService>();
    _configService = Get.find<ConfigService>();
    _subscriptionService = Get.find<SubscriptionService>();
    _initializeControllers();
    _loadUnlockStatus();
    _loadExpenseCategories();
    _loadIncomeCategories();

    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('defaultTab')) {
      initialTab = args['defaultTab'] ?? 0;
      currentTab.value = initialTab;
    }

    // Apply subscription-based unlocks now and react to changes
    _applyProSubscriptionUnlock();
    ever(_subscriptionService.isPro, (_) => _applyProSubscriptionUnlock());
    ever<DateTime?>(_subscriptionService.expiryDate, (_) => _applyProSubscriptionUnlock());
    ever<DateTime?>(_subscriptionService.temporaryProExpiry, (_) => _applyProSubscriptionUnlock());
  }

  void _loadExpenseCategories() {
    // Use only fixed frontend categories for both pro and non-pro users
    _loadStaticExpenseCategories();
  }

  void _loadIncomeCategories() {
    final cats = CategoryModel.getIncomeCategories();
    incomeCategories.assignAll(cats.map((c) => {
      'name': c.name,
      'iconPath': c.icon,
    }).toList());
    if (incomeCategories.isNotEmpty) {
      selectedIncomeCategory.value = incomeCategories.first['name'];
    }
  }

  void _loadStaticExpenseCategories() {
    final cats = CategoryModel.getExpenseCategories();
    expenseCategories.assignAll(cats.map((c) => {
      'name': c.name,
      'iconPath': c.icon,
    }).toList());
    if (expenseCategories.isNotEmpty) {
      selectedExpenseCategory.value = expenseCategories.first['name'];
    }
  }

  void _initializeControllers() {
    amountController = TextEditingController();
    descriptionController = TextEditingController();
    customCategoryController = TextEditingController();
  }

  @override
  void onClose() {
    amountController.dispose();
    descriptionController.dispose();
    customCategoryController.dispose();
    super.onClose();
  }

  // Helper to show Scaffold-based SnackBar messages with graceful fallback
  void _showScaffoldMessage(String message, {bool isError = false}) {
    final ctx = Get.context;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).clearSnackBars();
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Fallback to Get.snackbar if no context available
      Get.snackbar(
        isError ? 'Error' : 'Success',
        message,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> _loadUnlockStatus() async {
    // Do not persist ad-based unlocks across app restarts
    isExpenseProUnlocked.value = false;
    isIncomeProUnlocked.value = false;
  }

  void _applyProSubscriptionUnlock() {
    if (_subscriptionService.isActivePro) {
      isExpenseProUnlocked.value = true;
      isIncomeProUnlocked.value = true;
    } else if (_subscriptionService.isProUser && _subscriptionService.isExpiredNow) {
      // Optional: lock back if expired
      isExpenseProUnlocked.value = false;
      isIncomeProUnlocked.value = false;
    }
  }

  Future<void> unlockProFeatures(bool isExpense) async {
    // Unlock both features while temporary/premium is active; do NOT persist
    isExpenseProUnlocked.value = true;
    isIncomeProUnlocked.value = true;
  }

  void switchToTab(int tab) {
    currentTab.value = tab;
    clearSelections();
    // keep custom name input visibility consistent per tab
    showCustomCategoryInput.value = false;
  }

  void selectExpenseCategory(String category) {
    if (category.toLowerCase() == 'other' && customExpenseOtherName.value.isNotEmpty) {
      selectedExpenseCategory.value = customExpenseOtherName.value;
    } else {
      selectedExpenseCategory.value = category;
    }
  }


  void selectIncomeCategory(String category) {
    if (category.toLowerCase() == 'other income' && customIncomeOtherName.value.isNotEmpty) {
      selectedIncomeCategory.value = customIncomeOtherName.value;
    } else {
      selectedIncomeCategory.value = category;
    }
  }

  void selectPaymentMethod(String method) {
    selectedPaymentMethod.value = method;
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
  }

  void selectTime(TimeOfDay time) {
    selectedTime.value = time;
  }

  void clearSelections() {
    selectedExpenseCategory.value = '';
    selectedIncomeCategory.value = '';
    selectedPaymentMethod.value = '';
  }

  // Custom category helpers
  void toggleCustomCategoryInput() {
    showCustomCategoryInput.toggle();
  }

  void useCustomCategoryFromInput() {
    final name = customCategoryController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Error', 'Please enter a category name');
      return;
    }
    if (currentTab.value == 0) {
      customExpenseOtherName.value = name;
      selectExpenseCategory('Other');
    } else {
      customIncomeOtherName.value = name;
      selectIncomeCategory('Other Income');
    }
    showCustomCategoryInput.value = false;
  }

  Future<void> addTransactionWithCustomCategory() async {
    useCustomCategoryFromInput();
    // If validation failed, it already showed a snackbar
    if (currentTab.value == 0 && selectedExpenseCategory.value.isEmpty) return;
    if (currentTab.value == 1 && selectedIncomeCategory.value.isEmpty) return;
    await addTransaction();
  }

  // New method for processing OCR raw text for expenses
  Future<void> processOcrExpense(String rawText) async {
    if (!isExpenseProUnlocked.value) {
      Get.snackbar('Error', 'Pro feature required. Watch ad to unlock.');
      return;
    }
    isLoading.value = true;
    try {
      final response = await _apiService.request(
        'POST',
        _configService.ocrRawEndpoint,
        body: {'rawText': rawText},
        requiresAuth: true,
      );
      if (response['success'] == true) {
        Get.snackbar('Success', 'Expense created from OCR text');
        amountController.clear();
        descriptionController.clear();
        clearSelections();
        // Optionally navigate back or refresh parent screen
        // Get.back();
      } else {
        Get.snackbar('Error', response['message'] ?? 'Failed to process OCR');
      }
    } catch (e) {
      Get.snackbar('Error', 'API Error: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // New method for processing OCR raw text for income
  Future<void> processOcrIncome(String rawText) async {
    if (!isIncomeProUnlocked.value) {
      Get.snackbar('Error', 'Pro feature required. Watch ad to unlock.');
      return;
    }
    // Income OCR not supported yet - use expense endpoint for now
    Get.snackbar('Info', 'Income OCR coming soon. Use expense OCR for now.');
    return;
  }

  // Unified method for OCR processing based on current tab
  Future<void> processOcrRawText(String rawText) async {
    if (currentTab.value == 0) {
      await processOcrExpense(rawText);
    } else {
      await processOcrIncome(rawText);
    }
  }

  // Keep existing addTransaction implementation (calls _expenseController.addExpense for expenses)
  Future<void> addTransaction() async {
    if (currentTab.value == 0) {
      // Expense
      final text = amountController.text.trim();
      if (text.isEmpty) {
        _showScaffoldMessage('Please enter an amount', isError: true);
        return;
      }
      final amount = double.tryParse(text);
      if (amount == null || amount <= 0) {
        _showScaffoldMessage('Enter a valid positive amount', isError: true);
        return;
      }
      if (selectedExpenseCategory.value.isEmpty) {
        _showScaffoldMessage('Please select a category', isError: true);
        return;
      }
      isLoading.value = true;
      // Build effective date from selected date & time
      final d = selectedDate.value;
      final t = selectedTime.value;
      final DateTime effectiveDate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      final success = await _expenseController.addExpense(
        amount: amount,
        category: selectedExpenseCategory.value,
        note: selectedExpenseCategory.value,
        date: effectiveDate,
      );
      isLoading.value = false;
      if (success) {
        _showScaffoldMessage('Expense added');
        amountController.clear();
        descriptionController.clear();
        clearSelections();
      } else {
        _showScaffoldMessage(
          _expenseController.errorMessage.value.isNotEmpty
              ? _expenseController.errorMessage.value
              : 'Failed to add expense',
          isError: true,
        );
      }
    } else {
      // Income: Wire to IncomeService
      final text = amountController.text.trim();
      if (text.isEmpty) {
        _showScaffoldMessage('Please enter an amount', isError: true);
        return;
      }
      final amount = double.tryParse(text);
      if (amount == null || amount <= 0) {
        _showScaffoldMessage('Enter a valid positive amount', isError: true);
        return;
      }
      if (selectedIncomeCategory.value.isEmpty) {
        _showScaffoldMessage('Please select an income source', isError: true);
        return;
      }
      isLoading.value = true;
      try {
        final incomeService = Get.find<IncomeService>();
        final d = selectedDate.value;
        final t = selectedTime.value;
        final DateTime effectiveDate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
        await incomeService.createIncome(
          source: selectedIncomeCategory.value,
          amount: amount,
          date: effectiveDate,
        );
        try {
          final home = Get.find<HomeController>();
          home.addTransaction(selectedIncomeCategory.value, amount.toStringAsFixed(0), true);
          await home.fetchBudgetData();
          await home.fetchRecentTransactions();
        } catch (_) {}
        _showScaffoldMessage('Income added');
        amountController.clear();
        descriptionController.clear();
        clearSelections();
      } catch (e) {
        _showScaffoldMessage('Failed to add income', isError: true);
      } finally {
        isLoading.value = false;
      }
    }
  }


  // OCR helpers
  Future<void> processOCRFromCamera(bool isExpense) async {
    if (!isExpense) {
      Get.snackbar('Error', 'OCR currently supports expenses only');
      return;
    }
    try {
      isProcessingOCR.value = true;
      // For web, fallback to manual entry dialog
      if (kIsWeb) {
        await _promptAndProcessRawText(isExpense);
        return;
      }
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (image == null) {
        isProcessingOCR.value = false;
        return;
      }
      final rawText = await _extractTextFromImagePath(image.path);
      if ((rawText ?? '').trim().isEmpty) {
        Get.snackbar('Warning', 'No readable text found. Enter manually.');
        await _promptAndProcessRawText(isExpense);
        return;
      }
      await _handleOcrRawText(rawText!.trim(), isExpense);
    } catch (e) {
      Get.snackbar('Error', 'Camera OCR failed: ${e.toString()}');
    } finally {
      isProcessingOCR.value = false;
    }
  }

  Future<void> processOCRFromGallery(bool isExpense) async {
    if (!isExpense) {
      Get.snackbar('Error', 'OCR currently supports expenses only');
      return;
    }
    try {
      isProcessingOCR.value = true;
      if (kIsWeb) {
        await _promptAndProcessRawText(isExpense);
        return;
      }
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image == null) {
        isProcessingOCR.value = false;
        return;
      }
      final rawText = await _extractTextFromImagePath(image.path);
      if ((rawText ?? '').trim().isEmpty) {
        Get.snackbar('Warning', 'No readable text found. Enter manually.');
        await _promptAndProcessRawText(isExpense);
        return;
      }
      await _handleOcrRawText(rawText!.trim(), isExpense);
    } catch (e) {
      Get.snackbar('Error', 'Gallery OCR failed: ${e.toString()}');
    } finally {
      isProcessingOCR.value = false;
    }
  }

  Future<void> _promptAndProcessRawText(bool isExpense, {String title = 'Enter Receipt Text'}) async {
    final textController = TextEditingController();
    await Get.defaultDialog(
      title: title,
      content: Column(
        children: [
          Text('Paste the receipt text to process.'),
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
            Get.snackbar('Error', 'Text cannot be empty');
            return;
          }
          Get.back();
          await _handleOcrRawText(text, isExpense);
        },
        child: const Text('Post'),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
    );
  }

  Future<void> _handleOcrRawText(String rawText, bool isExpense) async {
    try {
      isProcessingOCR.value = true;
      final resp = await _ocrService.processOCR(rawText);
      final success = (resp['success'] == true);
      if (!success) {
        Get.snackbar('Warning', 'Unable to extract data. Please try again or enter manually.');
        return;
      }
      final data = resp['data'] as Map<String, dynamic>?;
      if (data == null) {
        Get.snackbar('Warning', 'No data returned from OCR.');
        return;
      }
      await _addExpenseFromOCRData(data);
      Get.snackbar('Success', 'Expense created successfully from OCR text.');
    } on Exception catch (e) {
      Get.snackbar('Error', 'OCR request failed: ${e.toString()}');
    } finally {
      isProcessingOCR.value = false;
    }
  }

  Future<void> _addExpenseFromOCRData(Map<String, dynamic> data) async {
    try {
      // Create local ExpenseItem and insert into lists via controller
      final item = ExpenseItem.fromJson(data);
      _expenseController.allExpenses.insert(0, item);
      _expenseController.applyMonthFilter();

      // Update Home recent transactions and budget
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
    } catch (e) {
      Get.snackbar('Error', 'Failed to sync OCR expense locally: ${e.toString()}');
    }
  }

  Future<String?> _extractTextFromImagePath(String path) async {
    try {
      // For now, rely on backend rawText flow; MLKit can be integrated later.
      // Return null to prompt manual entry when local OCR is not implemented.
      return await _ocrService.extractTextFromImagePath(path);
    } catch (_) {
      return null;
    }
  }
}
