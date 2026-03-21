import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _banner;
  bool _loaded = false;

  // ✅ 320x100
  static const AdSize _size = AdSize.largeBanner;

  @override
  void initState() {
    super.initState();

    _banner = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: _size,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          // ignore (no ad)
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _banner == null) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: SizedBox(
        width: _size.width.toDouble(),
        height: _size.height.toDouble(),
        child: AdWidget(ad: _banner!),
      ),
    );
  }

  /// ✅ Debug uses Google test ads.
  /// ✅ Release uses your real ad unit id.
  String get _adUnitId {
    if (kDebugMode) {
      // Google test banner ad unit id
      return 'ca-app-pub-3940256099942544/6300978111';
    }

    // 🔥 Replace this with YOUR real Banner Ad Unit ID from AdMob
    return 'ca-app-pub-9644346519201369/7067011694';
  }
}