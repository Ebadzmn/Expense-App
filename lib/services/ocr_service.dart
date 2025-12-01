import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:your_expense/services/api_base_service.dart';
import 'package:your_expense/services/config_service.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:your_expense/services/api_base_service.dart';

class OcrService extends GetxService {
  late final ApiBaseService _api;
  late final ConfigService _config;

  Future<OcrService> init() async {
    _api = Get.find<ApiBaseService>();
    _config = Get.find<ConfigService>();
    return this;
  }

  // Unified per spec: POST /expense/ocr-raw
  Future<Map<String, dynamic>> processOCR(String rawText) async {
    final payload = { 'rawText': rawText };
    final resp = await _api.request(
      'POST',
      _config.expenseOcrRawEndpoint,
      body: payload,
      requiresAuth: true,
    );
    return _normalizeResponse(resp);
  }

  // Backward-compat helpers used elsewhere
  Future<Map<String, dynamic>> processRawTextToExpense(String rawText) => processOCR(rawText);
  Future<Map<String, dynamic>> processRawTextToIncome(String rawText) => processOCR(rawText);

  // Local OCR using Google MLKit Text Recognition (mobile only)
  Future<String?> extractTextFromImagePath(String imagePath) async {
    if (kIsWeb) return null; // Web not supported for MLKit
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizer = TextRecognizer();
      final recognized = await recognizer.processImage(inputImage);
      await recognizer.close();
      final text = recognized.text.trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _normalizeResponse(dynamic resp) {
    if (resp is Map<String, dynamic>) {
      return resp;
    }
    return { 'success': false, 'message': 'Invalid OCR response format', 'data': {} };
  }
}