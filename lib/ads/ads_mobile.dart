import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../billing/billing.dart';
import '../remote/remote_store.dart';
import 'ad_ids.dart';
import 'ad_policy.dart';

class Ads {
  static bool _ready = false;
  static bool get ready => _ready;
  static InterstitialAd? _inter;
  static InterstitialPolicy? _policy;

  static Future<void> init() async {
    if (_ready || !Platform.isAndroid || Billing.adFree.value) return;
    try {
      await _consent();
      final can = await ConsentInformation.instance.canRequestAds();
      if (!can) return;
      await MobileAds.instance.initialize();
      _policy = InterstitialPolicy(start: DateTime.now());
      _ready = true;
      _loadInterstitial();
    } catch (_) {
      // أي فشل في الإعلانات لا يجب أن يؤثر على التطبيق.
    }
  }

  /// نموذج الموافقة (UMP) — يظهر فقط للمستخدمين الذين يتطلب القانون موافقتهم.
  static Future<void> _consent() {
    final c = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        ConsentForm.loadAndShowConsentFormIfRequired((FormError? e) {
          if (!c.isCompleted) c.complete();
        });
      },
      (FormError e) {
        if (!c.isCompleted) c.complete();
      },
    );
    return c.future.timeout(const Duration(seconds: 20), onTimeout: () {});
  }

  static void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialUnitId(),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _inter = ad,
        onAdFailedToLoad: (error) => _inter = null,
      ),
    );
  }

  /// يُستدعى عند رجوع المستخدم من أداة: نقطة طبيعية لإعلان بيني نادر.
  static void onToolClosed(String toolId) {
    final p = _policy;
    if (!_ready || p == null || Billing.adFree.value || noAdTools.contains(toolId)) {
      return;
    }
    final r = RemoteStore.config.value;
    if (r != null) {
      if (!r.ads.interstitial || r.noAdTools.contains(toolId)) return;
      p.everyN = r.ads.everyN;
      p.minGap = Duration(minutes: r.ads.minGapMin);
      p.warmup = Duration(seconds: r.ads.warmupSec);
    }
    p.registerFinish();
    final now = DateTime.now();
    if (!p.due(now)) return;
    final ad = _inter;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _inter = null;
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
    p.markShown(now);
  }

  static Widget banner() => _ready ? const _BannerSlot() : const SizedBox.shrink();
}

class _BannerSlot extends StatefulWidget {
  const _BannerSlot();
  @override
  State<_BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<_BannerSlot> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: bannerUnitId(),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    final t = Theme.of(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('إعلان',
          style: t.textTheme.labelSmall
              ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
      SizedBox(
        width: AdSize.banner.width.toDouble(),
        height: AdSize.banner.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
      const SizedBox(height: 4),
    ]);
  }
}
