import 'package:get/get.dart';

// Controllers
import 'package:your_expense/Settings/appearance/ThemeController.dart';
import 'package:your_expense/Settings/language/language_controller.dart';
import 'package:your_expense/home/home_controller.dart';
import 'package:your_expense/homepage/service/budget_service.dart';
import 'package:your_expense/homepage/service/transaction_service.dart';
import 'package:your_expense/login/login_controller.dart';
import 'package:your_expense/Analytics/expense_controller.dart';
import 'package:your_expense/add_exp/pro_user/expenseincomepro/proexpincome_controller.dart';
import 'package:your_expense/homepage/model_and _controller_of_monthlybudgetpage/monthly_budget_controller.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    // Core UI dependencies
    if (!Get.isRegistered<ThemeController>()) {
      Get.put(ThemeController(), permanent: true);
    }
    if (!Get.isRegistered<LanguageController>()) {
      Get.put(LanguageController(), permanent: true);
    }

    // Lazily create other controllers when first used
    Get.lazyPut(() => HomeController(), fenix: true);
    // Ensure feature services needed by Home are available early
    Get.lazyPut(() => TransactionService(), fenix: true);
    Get.lazyPut(() => BudgetService(), fenix: true);
    // Keep LoginController permanent to avoid disposing TextEditingControllers
    // while LoginScreen remains in the navigation stack.
    if (!Get.isRegistered<LoginController>()) {
      Get.put(LoginController(), permanent: true);
    }
    Get.lazyPut(() => MonthlyBudgetController(), fenix: true);
    Get.lazyPut(() => ExpenseController(), fenix: true);
    // ProExpensesIncomeController is registered permanently in main.dart to avoid
    // disposing TextEditingControllers while its screen remains in the stack.
  }
}