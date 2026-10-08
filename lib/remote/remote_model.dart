/// نموذج الإعدادات البعيدة (تأتي من لوحة الإدارة). كل شيء هنا تحقق دفاعي:
/// أي بيانات غير صالحة تُهمل، وإذا فشل التحليل كله نستخدم إعدادات التطبيق المضمّنة.

class RToolCfg {
  final String id;
  final bool visible, ads;
  final String? nameAr, nameEn, category;
  final List<String> keywords;
  final int minBuild;
  const RToolCfg({
    required this.id,
    this.visible = true,
    this.ads = true,
    this.nameAr,
    this.nameEn,
    this.category,
    this.keywords = const [],
    this.minBuild = 0,
  });
}

class RCategoryCfg {
  final String id, nameAr, nameEn, icon;
  final bool visible;
  const RCategoryCfg({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.icon = 'apps',
    this.visible = true,
  });
}

class RAdsCfg {
  final bool banner, interstitial;
  final int everyN, minGapMin, warmupSec;
  const RAdsCfg({
    this.banner = true,
    this.interstitial = true,
    this.everyN = 5,
    this.minGapMin = 3,
    this.warmupSec = 90,
  });
}

class RAnnouncement {
  final bool enabled;
  final String id, title, body;
  const RAnnouncement({this.enabled = false, this.id = '', this.title = '', this.body = ''});
}

class RMaintenance {
  final bool enabled;
  final String message;
  const RMaintenance({this.enabled = false, this.message = ''});
}

class RUpdate {
  final int minBuild;
  final String message, url;
  const RUpdate({this.minBuild = 0, this.message = '', this.url = ''});
}

class RemoteConfig {
  final int version;
  final List<RToolCfg> tools;
  final List<RCategoryCfg> categories;
  final RAdsCfg ads;
  final RAnnouncement announcement;
  final RMaintenance maintenance;
  final RUpdate update;
  const RemoteConfig({
    required this.version,
    this.tools = const [],
    this.categories = const [],
    this.ads = const RAdsCfg(),
    this.announcement = const RAnnouncement(),
    this.maintenance = const RMaintenance(),
    this.update = const RUpdate(),
  });

  /// أدوات أوقفت لوحة الإدارة إعلاناتها.
  Set<String> get noAdTools => {for (final t in tools) if (!t.ads) t.id};
}

// ───────────── أدوات التحليل الدفاعي ─────────────

/// Firebase يحوّل المصفوفات أحيانًا إلى خريطة مفاتيحها أرقام، فنقبل الشكلين.
List<dynamic> _asList(Object? v) {
  if (v is List) return v;
  if (v is Map) {
    final keys = v.keys.map((k) => k.toString()).toList()
      ..sort((a, b) => (int.tryParse(a) ?? 1 << 30).compareTo(int.tryParse(b) ?? 1 << 30));
    return [for (final k in keys) v[k]];
  }
  return const [];
}

String _s(Object? v, int max, [String d = '']) {
  if (v is! String) return d;
  final t = v.trim();
  return t.length > max ? t.substring(0, max) : t;
}

String? _sn(Object? v, int max) {
  final t = _s(v, max);
  return t.isEmpty ? null : t;
}

bool _b(Object? v, bool d) => v is bool ? v : d;

int _i(Object? v, int d, int lo, int hi) {
  if (v is! num || !v.isFinite) return d;
  final x = v.toInt();
  return x < lo ? lo : (x > hi ? hi : x);
}

Map<dynamic, dynamic> _m(Object? v) => v is Map ? v : const {};

RemoteConfig? parseRemoteConfig(Object? j) {
  try {
    if (j is! Map) return null;
    final version = _i(j['version'], 0, 0, 1 << 30);
    if (version < 1) return null;

    final tools = <RToolCfg>[];
    for (final e in _asList(j['tools']).take(500)) {
      if (e is! Map) continue;
      final id = _s(e['id'], 64);
      if (id.isEmpty) continue;
      tools.add(RToolCfg(
        id: id,
        visible: _b(e['visible'], true),
        ads: _b(e['ads'], true),
        nameAr: _sn(e['nameAr'], 60),
        nameEn: _sn(e['nameEn'], 60),
        category: _sn(e['category'], 40),
        keywords: [
          for (final k in _asList(e['keywords']).take(30))
            if (k is String && k.trim().isNotEmpty) _s(k, 40),
        ],
        minBuild: _i(e['minBuild'], 0, 0, 1 << 30),
      ));
    }

    final cats = <RCategoryCfg>[];
    for (final e in _asList(j['categories']).take(50)) {
      if (e is! Map) continue;
      final id = _s(e['id'], 40);
      final ar = _s(e['nameAr'], 40);
      if (id.isEmpty || ar.isEmpty) continue;
      cats.add(RCategoryCfg(
        id: id,
        nameAr: ar,
        nameEn: _s(e['nameEn'], 40, ar),
        icon: _s(e['icon'], 30, 'apps'),
        visible: _b(e['visible'], true),
      ));
    }

    final a = _m(j['ads']);
    final an = _m(j['announcement']);
    final mt = _m(j['maintenance']);
    final up = _m(j['update']);
    return RemoteConfig(
      version: version,
      tools: tools,
      categories: cats,
      ads: RAdsCfg(
        banner: _b(a['banner'], true),
        interstitial: _b(a['interstitial'], true),
        everyN: _i(a['everyN'], 5, 1, 50),
        minGapMin: _i(a['minGapMin'], 3, 0, 120),
        warmupSec: _i(a['warmupSec'], 90, 0, 600),
      ),
      announcement: RAnnouncement(
        enabled: _b(an['enabled'], false),
        id: _s(an['id'], 40, 'v$version'),
        title: _s(an['title'], 80),
        body: _s(an['body'], 600),
      ),
      maintenance: RMaintenance(
        enabled: _b(mt['enabled'], false),
        message: _s(mt['message'], 300),
      ),
      update: RUpdate(
        minBuild: _i(up['minBuild'], 0, 0, 1 << 30),
        message: _s(up['message'], 300),
        url: _s(up['url'], 300),
      ),
    );
  } catch (_) {
    return null;
  }
}
