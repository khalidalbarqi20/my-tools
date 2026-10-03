import 'package:flutter/material.dart';
import '../../storage/prefs.dart';
import '../../theme/app_theme.dart';

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
