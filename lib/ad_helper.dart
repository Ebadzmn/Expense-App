import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  static String _genericInterstitialId() {
    if (kIsWeb) return '';
    final bool isAndroid = defaultTargetPlatform == TargetPlatform.android;
    if (kDebugMode) {
      return isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return isAndroid
        ? 'ca-app-pub-7017672768951042/7242712146'
        : 'ca-app-pub-7017672768951042/7701877140';
  }

  static String _comparatorInterstitialId() {
    if (kIsWeb) return '';
    final bool isAndroid = defaultTargetPlatform == TargetPlatform.android;
    if (kDebugMode) {
      return isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return isAndroid
        ? 'ca-app-pub-7017672768951042/9014958816'
        : 'ca-app-pub-7017672768951042/4657019202';
  }

  static Future<void> showInterstitialAd({
    required VoidCallback onAdDismissed,
    required VoidCallback onAdFailed,
    bool comparator = false,
  }) async {
    if (kIsWeb) {
      debugPrint('Ads are not supported on web; continuing without ad.');
      onAdFailed();
      return;
    }
    debugPrint('Loading and showing interstitial ad...');
    final adUnitId = comparator ? _comparatorInterstitialId() : _genericInterstitialId();
    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('Ad loaded, showing...');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Ad dismissed');
              ad.dispose();
              onAdDismissed(); // Trigger navigation
            },
            onAdFailedToShowFullScreenContent: (ad, AdError error) {
              debugPrint('Ad failed to show: ${error.message}');
              ad.dispose();
              onAdFailed(); // Trigger navigation anyway
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Ad failed to load: ${error.message}');
          onAdFailed(); // Trigger navigation anyway
        },
      ),
    );
  }
}