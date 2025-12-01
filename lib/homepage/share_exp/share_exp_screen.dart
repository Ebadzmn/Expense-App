import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:your_expense/Settings/appearance/ThemeController.dart';
import 'package:your_expense/homepage/share_exp/share_exp_controller.dart';

class RateAndImproveScreen extends StatelessWidget {
  RateAndImproveScreen({super.key});
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Get the controller instance.
    final RateAndImproveController controller = Get.put(RateAndImproveController());
    final themeController = Get.find<ThemeController>();
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Obx(() => Scaffold(
      backgroundColor: themeController.isDarkModeActive ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: themeController.isDarkModeActive ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: themeController.isDarkModeActive ? Colors.white : Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Rate and Improve',
          style: TextStyle(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.w600,
            color: themeController.isDarkModeActive ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.03),
            Text(
              'Save and Grow Together',
              style: TextStyle(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.w700,
                color: themeController.isDarkModeActive ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              'Share your thoughts to help us improve',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: themeController.isDarkModeActive ? Colors.grey[400] : Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: screenHeight * 0.04),
            Text(
              'Rate your experience',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w600,
                color: themeController.isDarkModeActive ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Obx(() {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  // Determine if the current star should be selected.
                  bool isSelected = index < controller.starRating.value;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                    child: GestureDetector(
                      onTap: () => controller.setStarRating(index + 1),
                      child: ColorFiltered(
                        colorFilter: isSelected
                            ? const ColorFilter.mode(
                          Color(0xFF2196F3), // Blue for selected stars.
                          BlendMode.srcIn,
                        )
                            : ColorFilter.mode(
                          themeController.isDarkModeActive ? Colors.grey[600]! : Colors.grey, // Appropriate color for unselected stars.
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(
                          'assets/icons/star.png',
                          width: screenWidth * 0.08,
                          height: screenWidth * 0.08,
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
            SizedBox(height: screenHeight * 0.03),
            Text(
              'Share your feedback (optional)',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
                color: themeController.isDarkModeActive ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Container(
              decoration: BoxDecoration(
                color: themeController.isDarkModeActive ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
              ),
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: TextField(
                controller: controller.commentController,
                maxLines: 5,
                maxLength: 300,
                style: TextStyle(
                  color: themeController.isDarkModeActive ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Tell us what you think...',
                  hintStyle: TextStyle(color: themeController.isDarkModeActive ? Colors.grey[400] : Colors.grey.shade500),
                  border: InputBorder.none,
                  counterText: "", // Hide the default counter.
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Obx(() => SizedBox(
              width: double.infinity,
              height: screenHeight * 0.06,
              child: ElevatedButton(
                onPressed: controller.isLoading.value ? null : () => controller.submitFeedback(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
                ),
                child: controller.isLoading.value
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'Send Feedback',
                  style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.white),
                ),
              ),
            )),
          ],
        ),
      ),
    ));
  }
}