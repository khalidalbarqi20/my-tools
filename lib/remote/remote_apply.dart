import '../core/tool.dart';
import 'remote_model.dart';

Tool _override(Tool t, RToolCfg o) => Tool(
      id: t.id,
      nameAr: o.nameAr ?? t.nameAr,
      nameEn: o.nameEn ?? t.nameEn,
      category: o.category ?? t.category,
      keywords: [...t.keywords, ...o.keywords],
      icon: t.icon,
      builder: t.builder,
    );

/// يطبّق إعدادات اللوحة على أدوات التطبيق: إخفاء، ترتيب، أسماء، قسم، كلمات بحث، وأقل إصدار.
/// الأدوات التي لا ذكر لها في الإعدادات تبقى كما هي في آخر القائمة،
/// والإعدادات التي تشير لأدوات غير موجودة في هذه النسخة تُهمل.
List<Tool> applyToolConfig(List<Tool> base, RemoteConfig? cfg, int build) {
  if (cfg == null) return base;
  final byId = {for (final t in base) t.id: t};
  final seen = <String>{};
  final out = <Tool>[];
  for (final o in cfg.tools) {
    final t = byId[o.id];
    if (t == null || !seen.add(o.id)) continue;
    if (o.visible && build >= o.minBuild) out.add(_override(t, o));
  }
  for (final t in base) {
    if (!seen.contains(t.id)) out.add(t);
  }
  return out;
}
