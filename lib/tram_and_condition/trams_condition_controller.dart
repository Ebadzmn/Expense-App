import 'package:get/get.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';


import 'model/tram_and_condition_model.dart';

class TermsAndConditionsController extends GetxController {
  final ApiBaseService _apiService = Get.find();
  final ConfigService _configService = Get.find();

  final RxList<TermsAndConditions> termsList = <TermsAndConditions>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final Rx<TermsAndConditions?> latestTerms = Rx<TermsAndConditions?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchTermsAndConditions();
  }

  Future<void> fetchTermsAndConditions() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _apiService.request(
        'GET',
        _configService.termsAndConditionsEndpoint,
        requiresAuth: true,
      );

      if (response.containsKey('success') && response['success'] == true) {
        final termsResponse = TermsAndConditionsResponse.fromJson(response);
        termsList.value = termsResponse.data;

        // Sort by effectiveDate descending and get the latest terms
        if (termsList.isNotEmpty) {
          termsList.sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
          latestTerms.value = termsList.first;
        }
      } else {
        errorMessage.value = response['message'] ?? 'Failed to fetch terms';
      }
    } catch (e) {
      errorMessage.value = 'Failed to fetch terms and conditions: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshTerms() async {
    await fetchTermsAndConditions();
  }
}