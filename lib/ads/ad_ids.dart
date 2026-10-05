/// معرّفات الإعلانات التجريبية الرسمية من Google (آمنة للاختبار).
const testBannerId = 'ca-app-pub-3940256099942544/6300978111';
const testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

/// المعرّفات الحقيقية تُمرَّر وقت البناء فقط:
/// flutter build apk --dart-define=ADMOB_BANNER=... --dart-define=ADMOB_INTERSTITIAL=...
/// وإذا لم تُمرَّر نستخدم الإعلانات التجريبية (حتى لا نعرض إعلانًا حقيقيًا أثناء التطوير).
const _banner = String.fromEnvironment('ADMOB_BANNER');
const _interstitial = String.fromEnvironment('ADMOB_INTERSTITIAL');

String pickUnitId(String configured, String test) =>
    configured.trim().isEmpty ? test : configured.trim();

String bannerUnitId() => pickUnitId(_banner, testBannerId);
String interstitialUnitId() => pickUnitId(_interstitial, testInterstitialId);
