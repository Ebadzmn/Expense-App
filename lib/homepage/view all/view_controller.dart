import 'package:get/get.dart';

import '../model/transaction.dart';


class AllTransactionsController extends GetxController {
  var allTransactions = <Transaction>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Get transactions passed from home screen
    final arguments = Get.arguments;
    if (arguments != null && arguments is List<Transaction>) {
      allTransactions.assignAll(arguments);
    }
  }
}