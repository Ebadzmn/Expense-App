import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../Settings/appearance/ThemeController.dart';
import '../colors/app_colors.dart';

class WebPageScreen extends StatefulWidget {
  final String title;
  final String url;
  const WebPageScreen({super.key, required this.title, required this.url});

  @override
  State<WebPageScreen> createState() => _WebPageScreenState();
}

class _WebPageScreenState extends State<WebPageScreen> {
  late final WebViewController _controller;
  final ThemeController themeController = Get.find<ThemeController>();
  final RxDouble _progress = 0.0.obs;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (progress) => _progress.value = progress / 100.0,
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.isDarkModeActive;
    final screenWidth = MediaQuery.of(context).size.width;

    return Obx(() => Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black),
              onPressed: () => Get.back(),
            ),
            backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            elevation: 0,
            centerTitle: true,
            title: Text(
              widget.title,
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(_progress.value > 0 && _progress.value < 1 ? 3 : 0),
              child: _progress.value > 0 && _progress.value < 1
                  ? LinearProgressIndicator(value: _progress.value)
                  : const SizedBox.shrink(),
            ),
          ),
          body: WebViewWidget(controller: _controller),
        ));
  }
}