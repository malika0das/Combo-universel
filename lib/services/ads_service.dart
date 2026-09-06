import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Ad configuration.
///
/// Google test unit IDs are used by default so the app never serves live ads
/// during development (serving live ads on a dev build is an AdMob policy
/// violation). Replace the `real*` constants with your own unit IDs and build
/// with `--dart-define=USE_REAL_ADS=true` for release.
class AdIds {
  static const bool useReal =
      bool.fromEnvironment('USE_REAL_ADS', defaultValue: false);

  // TODO: replace with your real AdMob unit IDs before publishing.
  static const String realBannerAndroid = 'ca-app-pub-0000000000000000/0000000000';
  static const String realInterstitialAndroid = 'ca-app-pub-0000000000000000/1111111111';

  static const String testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';

  static String get banner =>
      useReal ? realBannerAndroid : testBannerAndroid;
  static String get interstitial =>
      useReal ? realInterstitialAndroid : testInterstitialAndroid;
}

class AdsService extends ChangeNotifier {
  bool _initialized = false;
  bool _personalized = false;
  InterstitialAd? _interstitial;
  int _navCount = 0;

  /// Show an interstitial at most every N qualifying navigations, and never
  /// on app open / back press. Keeps UX clean and Play-policy safe.
  static const int interstitialEvery = 6;

  bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  bool get initialized => _initialized;

  Future<void> init({required bool personalized}) async {
    _personalized = personalized;
    if (!supported) return;
    await MobileAds.instance.initialize();
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        maxAdContentRating: MaxAdContentRating.g,
      ),
    );
    _initialized = true;
    _preloadInterstitial();
    notifyListeners();
  }

  void setPersonalized(bool value) {
    _personalized = value;
    notifyListeners();
  }

  AdRequest get request => AdRequest(
        nonPersonalizedAds: !_personalized,
        keywords: const [
          'mobile repair',
          'smartphone spare parts',
          'lcd display',
          'mobile accessories',
        ],
      );

  BannerAd createBanner({required AdSize size, VoidCallback? onLoaded}) {
    return BannerAd(
      adUnitId: AdIds.banner,
      size: size,
      request: request,
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded?.call(),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    );
  }

  void _preloadInterstitial() {
    if (!supported || _interstitial != null) return;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Call on meaningful navigation events (e.g. opening a group detail).
  void maybeShowInterstitial() {
    if (!supported) return;
    _navCount++;
    if (_navCount % interstitialEvery != 0) return;
    final ad = _interstitial;
    if (ad == null) {
      _preloadInterstitial();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        _preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitial = null;
        _preloadInterstitial();
      },
    );
    ad.show();
    _interstitial = null;
  }

  @override
  void dispose() {
    _interstitial?.dispose();
    super.dispose();
  }
}
