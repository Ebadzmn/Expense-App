import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:your_expense/Analytics/expense_controller.dart';
import 'package:your_expense/Analytics/income_controller.dart';
import 'package:your_expense/services/config_service.dart';

void main() {
  group('Month Switching Tests', () {
    late ExpenseController expenseController;
    late IncomeController incomeController;
    late ConfigService configService;

    setUp(() {
      // Initialize GetX
      Get.testMode = true;
      
      // Mock ConfigService
      configService = ConfigService();
      Get.put(configService);
      
      // Initialize controllers
      expenseController = ExpenseController();
      incomeController = IncomeController();
      
      Get.put(expenseController);
      Get.put(incomeController);
    });

    tearDown(() {
      Get.reset();
    });

    test('ExpenseController should initialize with current month', () {
      final currentMonth = configService.getCurrentMonth();
      expect(expenseController.selectedMonth.value, equals(currentMonth));
    });

    test('IncomeController should initialize with current month', () {
      final currentMonth = configService.getCurrentMonth();
      expect(incomeController.selectedMonth.value, equals(currentMonth));
    });

    test('ExpenseController should switch to current month', () {
      // Set a different month first
      expenseController.updateMonth('2023-12');
      expect(expenseController.selectedMonth.value, equals('2023-12'));
      
      // Switch back to current month
      expenseController.switchToCurrentMonth();
      final currentMonth = configService.getCurrentMonth();
      expect(expenseController.selectedMonth.value, equals(currentMonth));
    });

    test('IncomeController should switch to current month', () {
      // Set a different month first
      incomeController.updateMonth('2023-12');
      expect(incomeController.selectedMonth.value, equals('2023-12'));
      
      // Switch back to current month
      incomeController.switchToCurrentMonth();
      final currentMonth = configService.getCurrentMonth();
      expect(incomeController.selectedMonth.value, equals(currentMonth));
    });

    test('ExpenseController should detect if viewing current month', () {
      final currentMonth = configService.getCurrentMonth();
      
      // Should be true when viewing current month
      expenseController.updateMonth(currentMonth);
      expect(expenseController.isViewingCurrentMonth, isTrue);
      
      // Should be false when viewing different month
      expenseController.updateMonth('2023-12');
      expect(expenseController.isViewingCurrentMonth, isFalse);
    });

    test('IncomeController should detect if viewing current month', () {
      final currentMonth = configService.getCurrentMonth();
      
      // Should be true when viewing current month
      incomeController.updateMonth(currentMonth);
      expect(incomeController.isViewingCurrentMonth, isTrue);
      
      // Should be false when viewing different month
      incomeController.updateMonth('2023-12');
      expect(incomeController.isViewingCurrentMonth, isFalse);
    });

    test('Controllers should provide available months', () {
      // Test that available months method returns a list
      final expenseMonths = expenseController.availableMonths;
      final incomeMonths = incomeController.availableMonths;
      
      expect(expenseMonths, isA<List<String>>());
      expect(incomeMonths, isA<List<String>>());
    });
  });
}