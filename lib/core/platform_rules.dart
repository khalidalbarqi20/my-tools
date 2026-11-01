/// جدول المنصات: أين تعمل كل أداة، ولماذا نخفيها حيث لا تعمل.
/// app = تطبيق أندرويد، web = المتصفح (أندرويد/كمبيوتر)، iosWeb = المتصفح على آيفون/آيباد.
library;

enum Plat { app, web, iosWeb }

class PlatRule {
  final Set<Plat> works;

  /// سبب الإخفاء (يظهر للمستخدم في «أدوات غير متاحة على جهازك»).
  final String why;

  /// تنبيه يظهر عند فتح الأداة على آيفون (للأدوات التي تعمل لكن بتحفظ).
  final String? iosCaution;
  const PlatRule(this.works, {this.why = '', this.iosCaution});
}

const _appOnly = {Plat.app};
const _noIos = {Plat.app, Plat.web};

const platformRules = <String, PlatRule>{
  // لا تعمل في المتصفح إطلاقًا
  'dev_info': PlatRule(_appOnly, why: 'قراءة معلومات الجهاز متاحة في تطبيق الأندرويد فقط'),
  'dev_flashlight': PlatRule(_appOnly, why: 'المتصفح لا يسمح بالتحكم في الكشاف'),
  'net_site': PlatRule(_appOnly, why: 'المتصفح يمنع فحص المواقع الأخرى'),
  // لا تعمل على آيفون
  'dev_compass': PlatRule(_noIos, why: 'آيفون يمنع المستشعرات في المتصفح غالبًا'),
  'dev_level': PlatRule(_noIos, why: 'آيفون يمنع المستشعرات في المتصفح غالبًا'),
  'dev_sensors': PlatRule(_noIos, why: 'آيفون يمنع المستشعرات في المتصفح غالبًا'),
  'dev_vibration': PlatRule(_noIos, why: 'آيفون لا يدعم الاهتزاز من المتصفح'),
  // تعمل على آيفون لكن بتحفظ
  'img_removebg': PlatRule({Plat.app, Plat.web, Plat.iosWeb},
      iosCaution: 'أول استخدام ينزّل نموذجًا بحجم ٤٥ ميجابايت، والصور الكبيرة قد تفشل بسبب ذاكرة Safari.'),
  'img_compress': PlatRule({Plat.app, Plat.web, Plat.iosWeb},
      iosCaution: 'صيغة WebP أضعف في Safari، يفضّل JPG أو PNG.'),
  'img_convert': PlatRule({Plat.app, Plat.web, Plat.iosWeb},
      iosCaution: 'صيغة WebP أضعف في Safari، يفضّل JPG أو PNG.'),
  'vid_to_audio': PlatRule({Plat.app, Plat.web, Plat.iosWeb}, iosCaution: _vid),
  'vid_audio_convert': PlatRule({Plat.app, Plat.web, Plat.iosWeb}, iosCaution: _vid),
  'vid_audio_to_video': PlatRule({Plat.app, Plat.web, Plat.iosWeb}, iosCaution: _vid),
  'vid_trim': PlatRule({Plat.app, Plat.web, Plat.iosWeb}, iosCaution: _vid),
  'vid_text': PlatRule({Plat.app, Plat.web, Plat.iosWeb}, iosCaution: _vid),
  'vid_convert': PlatRule({Plat.app, Plat.web, Plat.iosWeb}, iosCaution: _vid),
  'vid_compress': PlatRule({Plat.app, Plat.web, Plat.iosWeb}, iosCaution: _vid),
  'vid_mute': PlatRule({Plat.app, Plat.web, Plat.iosWeb}, iosCaution: _vid),
  'qr_scan': PlatRule({Plat.app, Plat.web, Plat.iosWeb},
      iosCaution: 'يحتاج السماح بالكاميرا من Safari.'),
  'dev_camera': PlatRule({Plat.app, Plat.web, Plat.iosWeb},
      iosCaution: 'يحتاج السماح بالكاميرا من Safari.'),
  'dev_mic': PlatRule({Plat.app, Plat.web, Plat.iosWeb},
      iosCaution: 'يحتاج السماح بالميكروفون من Safari.'),
};

const _vid = 'ذاكرة Safari محدودة: الملفات الكبيرة قد تفشل، يفضّل مقاطع قصيرة.';

/// هل تعمل الأداة [id] على المنصة [p]؟ (الأدوات التي بلا قاعدة تعمل في كل مكان)
bool supportedOn(String id, Plat p) => platformRules[id]?.works.contains(p) ?? true;

String? whyNot(String id) => platformRules[id]?.why;

String? cautionOn(String id, Plat p) => p == Plat.iosWeb ? platformRules[id]?.iosCaution : null;
