import 'package:flutter/material.dart';
import '../../storage/prefs.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'color_picker.dart';

const _accentPresets = [
  Color(0xFF1E6F5C), Color(0xFF1565C0), Color(0xFF6A1B9A), Color(0xFFC2185B),
  Color(0xFFE65100), Color(0xFF00838F), Color(0xFF455A64), Color(0xFF2E7D32),
  Color(0xFFB71C1C),
];
const _iconPresets = [..._accentPresets, Color(0xFFF9A825)];
const _bgPresets = [
  Color(0xFFFFFFFF), Color(0xFFFFF8E7), Color(0xFFEFF6FF), Color(0xFFF3EEFB),
  Color(0xFFFDEEF0), Color(0xFF121816), Color(0xFF0B1220), Color(0xFF000000),
];

class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Group({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8, right: 4, left: 4),
        child: Text(title,
            style: t.textTheme.titleSmall?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700)),
      ),
      Material(
        color: cardColor(context),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: softBorder(context)),
        ),
        child: Column(children: children),
      ),
    ]);
  }
}

class _Dot extends StatelessWidget {
  final Color? color;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final String tip;
  const _Dot({
    this.color,
    this.icon,
    required this.selected,
    required this.onTap,
    required this.tip,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fill = color ?? cs.surfaceContainerHighest;
    final fg = color == null
        ? cs.onSurfaceVariant
        : (ThemeData.estimateBrightnessForColor(color!) == Brightness.dark
            ? Colors.white
            : Colors.black);
    return Tooltip(
      message: tip,
      child: InkResponse(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(
                color: selected ? cs.primary : cs.outlineVariant,
                width: selected ? 3 : 1),
          ),
          child: Icon(selected && icon == null ? Icons.check : icon,
              size: 18, color: fg),
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final String title, autoTip;
  final Color? value;
  final List<Color> presets;
  final ValueChanged<Color?> onChanged;
  const _ColorRow({
    required this.title,
    required this.autoTip,
    required this.value,
    required this.presets,
    required this.onChanged,
  });

  bool _same(Color a, Color? b) => b != null && a.toARGB32() == b.toARGB32();

  @override
  Widget build(BuildContext context) {
    final custom = value != null && !presets.any((p) => _same(p, value));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: [
        _Dot(
            icon: Icons.auto_awesome,
            selected: value == null,
            onTap: () => onChanged(null),
            tip: autoTip),
        for (final p in presets)
          _Dot(
              color: p,
              selected: _same(p, value),
              onTap: () => onChanged(p),
              tip: ''),
        _Dot(
          color: custom ? value : null,
          icon: Icons.palette_outlined,
          selected: custom,
          tip: 'لون مخصص',
          onTap: () async {
            final c = await pickColor(context,
                initial: value ?? presets.first, title: title);
            if (c != null) onChanged(c);
          },
        ),
      ]),
    ]);
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _clearRecents(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('مسح سجل الاستخدام؟'),
        content: const Text('سيتم حذف قائمة آخر الأدوات المستخدمة. المفضلة لن تتأثر.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(c, true), child: const Text('مسح')),
        ],
      ),
    );
    if (ok == true) {
      Prefs.clearRecents();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم مسح السجل')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Text('الإعدادات',
              style: t.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          _Group(title: 'المظهر', children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: Prefs.themeMode,
                builder: (context, m, child) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('وضع العرض'),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(value: ThemeMode.system, label: Text('تلقائي')),
                          ButtonSegment(value: ThemeMode.light, label: Text('فاتح')),
                          ButtonSegment(value: ThemeMode.dark, label: Text('داكن')),
                        ],
                        selected: {m},
                        onSelectionChanged: (s) => Prefs.setTheme(s.first),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          _Group(title: 'الألوان', children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: ValueListenableBuilder<AppColors>(
                valueListenable: Prefs.colors,
                builder: (context, c, child) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ColorRow(
                      title: 'لون التطبيق',
                      autoTip: 'الافتراضي',
                      value: c.accent,
                      presets: _accentPresets,
                      onChanged: (v) => Prefs.setColors(c.withAccent(v)),
                    ),
                    const SizedBox(height: 20),
                    _ColorRow(
                      title: 'لون الخلفية',
                      autoTip: 'تلقائي',
                      value: c.bg,
                      presets: _bgPresets,
                      onChanged: (v) => Prefs.setColors(c.withBg(v)),
                    ),
                    const SizedBox(height: 20),
                    _ColorRow(
                      title: 'لون الأيقونات',
                      autoTip: 'ألوان الأقسام الافتراضية',
                      value: c.icon,
                      presets: _iconPresets,
                      onChanged: (v) => Prefs.setColors(c.withIcon(v)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'اختر خلفية داكنة ليتحول التطبيق كله للوضع الداكن تلقائيًا.',
                      style: t.textTheme.bodySmall
                          ?.copyWith(color: t.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed:
                          c.isDefault ? null : () => Prefs.setColors(const AppColors()),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('استعادة الألوان الافتراضية'),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          _Group(title: 'البيانات', children: [
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('مسح سجل الاستخدام'),
              onTap: () => _clearRecents(context),
            ),
          ]),
          _Group(title: 'حول التطبيق', children: [
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('أدواتي اليومية'),
              subtitle: Text('الإصدار 0.1.0'),
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('خصوصيتك'),
              subtitle: Text('معالجة الملفات تتم على جهازك ولا تُرفع إلى أي خادم'),
            ),
          ]),
        ],
      ),
    );
  }
}
