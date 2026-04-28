import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../providers/ad_provider.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({
    super.key,
    required this.placement,
  });

  final BannerPlacement placement;

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adProvider).ensureLoaded(widget.placement);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    final provider = ref.watch(adProvider);
    final ad = widget.placement == BannerPlacement.top
        ? provider.topBannerAd
        : provider.bottomBannerAd;
    final isLoaded = widget.placement == BannerPlacement.top
        ? provider.isTopLoaded
        : provider.isBottomLoaded;

    if (!isLoaded || ad == null) {
      return const SizedBox(height: 50);
    }

    return SizedBox(
      height: 50,
      child: AdWidget(ad: ad),
    );
  }
}
