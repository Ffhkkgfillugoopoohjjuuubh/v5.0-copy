import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/api_config.dart';

enum BannerPlacement { top, bottom }

final adProvider = ChangeNotifierProvider<AdProvider>((ref) {
  final provider = AdProvider();
  ref.onDispose(provider.dispose);
  return provider;
});

class AdProvider extends ChangeNotifier {
  BannerAd? _topBannerAd;
  BannerAd? _bottomBannerAd;
  bool _topLoaded = false;
  bool _bottomLoaded = false;

  BannerAd? get topBannerAd => _topBannerAd;
  BannerAd? get bottomBannerAd => _bottomBannerAd;
  bool get isTopLoaded => _topLoaded;
  bool get isBottomLoaded => _bottomLoaded;

  void ensureLoaded(BannerPlacement placement) {
    if (kIsWeb) {
      return;
    }

    if (placement == BannerPlacement.top && _topBannerAd != null) {
      return;
    }

    if (placement == BannerPlacement.bottom && _bottomBannerAd != null) {
      return;
    }

    _createBanner(placement);
  }

  void reloadAds() {
    if (kIsWeb) {
      return;
    }

    _disposePlacement(BannerPlacement.top);
    _disposePlacement(BannerPlacement.bottom);
    _createBanner(BannerPlacement.top);
    _createBanner(BannerPlacement.bottom);
  }

  void _createBanner(BannerPlacement placement) {
    final ad = BannerAd(
      adUnitId: placement == BannerPlacement.top
          ? topBannerAdUnitId
          : bottomBannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (placement == BannerPlacement.top) {
            _topLoaded = true;
          } else {
            _bottomLoaded = true;
          }
          notifyListeners();
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (placement == BannerPlacement.top) {
            _topBannerAd = null;
            _topLoaded = false;
          } else {
            _bottomBannerAd = null;
            _bottomLoaded = false;
          }
          notifyListeners();
        },
      ),
    );

    if (placement == BannerPlacement.top) {
      _topBannerAd = ad;
      _topLoaded = false;
    } else {
      _bottomBannerAd = ad;
      _bottomLoaded = false;
    }

    ad.load();
    notifyListeners();
  }

  void _disposePlacement(BannerPlacement placement) {
    if (placement == BannerPlacement.top) {
      _topBannerAd?.dispose();
      _topBannerAd = null;
      _topLoaded = false;
    } else {
      _bottomBannerAd?.dispose();
      _bottomBannerAd = null;
      _bottomLoaded = false;
    }
  }

  @override
  void dispose() {
    _disposePlacement(BannerPlacement.top);
    _disposePlacement(BannerPlacement.bottom);
    super.dispose();
  }
}
