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
      try {
        ref.read(adProvider).ensureLoaded(widget.placement);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    late final AdProvider provider;
    try {
      provider = ref.watch(adProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }
    final ad = widget.placement == BannerPlacement.top
        ? provider.topBannerAd
        : provider.bottomBannerAd;
    final isLoaded = widget.placement == BannerPlacement.top
        ? provider.isTopLoaded
        : provider.isBottomLoaded;

    if (!isLoaded || ad == null) {
      return const SizedBox(height: 50);
    }

    try {
      return SizedBox(
        height: 50,
        child: AdWidget(ad: ad),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
