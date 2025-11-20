import 'package:get/get.dart';

// Controllers
import 'package:your_expense/Settings/appearance/ThemeController.dart';
import 'package:your_expense/Settings/language/language_controller.dart';
import 'package:your_expense/home/home_controller.dart';
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
    Get.lazyPut(() => LoginController(), fenix: true);
    Get.lazyPut(() => MonthlyBudgetController(), fenix: true);
    Get.lazyPut(() => ExpenseController(), fenix: true);
    Get.lazyPut(() => ProExpensesIncomeController(), fenix: true);
  }
}