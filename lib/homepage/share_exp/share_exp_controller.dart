import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/review_service.dart';

class RateAndImproveController extends GetxController {
  var starRating = 0.obs;
  var isLoading = false.obs;
  final TextEditingController commentController = TextEditingController();

  void setStarRating(int rating) {
    if (starRating.value == rating) {
      starRating.value = 0;
    } else {
      starRating.value = rating;
    }
  }

  Future<void> submitFeedback() async {
    if (starRating.value == 0) {
      Get.snackbar(
        'Error',
        'Please select a rating',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      final ReviewService reviewService = Get.find();
      final response = await reviewService.submitReview(
        starRating.value,
        commentController.text,
      );

      // Verify response structure
      if (response['success'] == true) {
        Get.snackbar(
          'Thank You!',
          'Your feedback has been submitted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );

        // Clear form
        starRating.value = 0;
        commentController.clear();

        // Navigate back after a delay
        Future.delayed(const Duration(seconds: 2), () {
          Get.back();
        });
      } else {
        throw Exception(response['message'] ?? 'Submission failed. Please try again.');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit feedback: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }
}