import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads_service.dart';

/// Adaptive anchored banner. Renders nothing (zero height) until an ad loads,
/// so the layout never shows an empty grey block - required for a clean UX and
/// avoids accidental clicks near interactive controls.
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key, required this.ads});

  final AdsService ads;

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _ad;
  bool _loaded = false;
  int _loadedForWidth = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Ads initialise asynchronously after first frame, so a slot built before
    // that used to request nothing and stay blank forever. Listening means the
    // banner appears as soon as the SDK is ready.
    widget.ads.addListener(_onAdsChanged);
  }

  void _onAdsChanged() {
    if (mounted && !_loaded) _maybeLoad();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoad();
  }

  /// Loads (or reloads) the banner for the current width. Rotating the device
  /// changes the correct adaptive size, and the old ad would otherwise be left
  /// stretched or clipped.
  Future<void> _maybeLoad() async {
    if (!widget.ads.supported || !widget.ads.initialized) return;
    if (_loading) return;
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width <= 0 || width == _loadedForWidth) return;

    _loading = true;
    _loadedForWidth = width;
    try {
      final size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      if (size == null || !mounted) return;

      final previous = _ad;
      final ad = widget.ads.createBanner(
        size: size,
        onLoaded: () {
          if (mounted) setState(() => _loaded = true);
        },
      );
      _ad = ad;
      await ad.load();
      // Only dispose the old ad once its replacement exists, so the slot never
      // collapses to zero height mid-rotation.
      previous?.dispose();
    } finally {
      _loading = false;
    }
  }

  @override
  void dispose() {
    widget.ads.removeListener(_onAdsChanged);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
