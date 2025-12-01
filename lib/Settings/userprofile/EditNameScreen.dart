import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:your_expense/Settings/userprofile/profile_services.dart';
import '../../services/config_service.dart';
import '../appearance/ThemeController.dart';


class EditNameScreen extends StatefulWidget {
  const EditNameScreen({super.key});

  @override
  _EditNameScreenState createState() => _EditNameScreenState();
}

class _EditNameScreenState extends State<EditNameScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ThemeController themeController = Get.find<ThemeController>();
  final ProfileService profileService = Get.find<ProfileService>();
  final ConfigService configService = Get.find<ConfigService>();
  String? profileImageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      setState(() => isLoading = true);
      await profileService.fetchUserProfile(); // Fetch profile to ensure latest data
      final fullName = profileService.userName.value;
      final nameParts = fullName.trim().split(' ');
      _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
      _lastNameController.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      profileImageUrl = profileService.getFullImageUrl();
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_load_profile'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: themeController.isDarkModeActive ? Color(0xFF121212) : Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: themeController.isDarkModeActive ? Color(0xFF1E1E1E) : Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: themeController.isDarkModeActive ? Colors.white : Colors.black,
            size: screenWidth * 0.05,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'edit_profile'.tr,
          style: TextStyle(
            color: themeController.isDarkModeActive ? Colors.white : Colors.black,
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.02,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.03),
              // Profile Picture (Display Only)
              Center(
                child: Container(
                  width: screenWidth * 0.25,
                  height: screenWidth * 0.25,
                  decoration: BoxDecoration(
                    color: themeController.isDarkModeActive ? Color(0xFF2D2D2D) : Color(0xFFE3F2FD),
                    shape: BoxShape.circle,
                    image: profileImageUrl != null && profileImageUrl!.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(profileImageUrl!),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        print('❌ Error loading image: $exception');
                      },
                    )
                        : null,
                  ),
                  child: profileImageUrl == null || profileImageUrl!.isEmpty
                      ? Icon(
                    Icons.person,
                    size: screenWidth * 0.15,
                    color: const Color(0xFF2196F3),
                  )
                      : null,
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              // Instruction Text
              Center(
                child: Text(
                  'name_appearance_info'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: themeController.isDarkModeActive ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
              // First Name Field
              Text(
                'first_name'.tr,
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  fontWeight: FontWeight.w500,
                  color: themeController.isDarkModeActive ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              TextFormField(
                controller: _firstNameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'first_name_required'.tr;
                  }
                  return null;
                },
                style: TextStyle(
                  color: themeController.isDarkModeActive ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'enter_first_name'.tr,
                  hintStyle: TextStyle(
                    color: themeController.isDarkModeActive ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  filled: true,
                  fillColor: themeController.isDarkModeActive ? Color(0xFF1E1E1E) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.02,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              // Last Name Field
              Text(
                'last_name'.tr,
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  fontWeight: FontWeight.w500,
                  color: themeController.isDarkModeActive ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              TextFormField(
                controller: _lastNameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'last_name_required'.tr;
                  }
                  return null;
                },
                style: TextStyle(
                  color: themeController.isDarkModeActive ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'enter_last_name'.tr,
                  hintStyle: TextStyle(
                    color: themeController.isDarkModeActive ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  filled: true,
                  fillColor: themeController.isDarkModeActive ? Color(0xFF1E1E1E) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.02,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
              // Save Button
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.065,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'save_changes'.tr,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => isLoading = true);
        final newFullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
        final success = await profileService.updateProfile(name: newFullName);
        if (success) {
          Get.back();
          Get.snackbar(
            'success'.tr,
            '${'name_updated_to'.tr} $newFullName',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'error'.tr,
            'failed_to_update_profile'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        Get.snackbar(
          'error'.tr,
          'failed_to_update_profile'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }
}