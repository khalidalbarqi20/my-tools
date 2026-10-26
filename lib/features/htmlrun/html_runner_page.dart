import 'package:flutter/material.dart';
import 'html_host.dart';
import 'html_model.dart';

String _two(int n) => n < 10 ? '0$n' : '$n';
String _when(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.year}/${_two(d.month)}/${_two(d.day)}  ${_two(d.hour)}:${_two(d.minute)}';
}

/// تشغيل صفحة HTML أو مشروع كامل (ZIP). الملفات تُحفظ على تخزين الجهاز، وبيانات الصفحة نفسها تُحفظ في تخزين المتصفح المدمج.
class HtmlRunnerPage extends StatefulWidget {
  const HtmlRunnerPage({super.key});
  @override
  State<HtmlRunnerPage> createState() => _HtmlRunnerPageState();
}

class _HtmlRunnerPageState extends State<HtmlRunnerPage> {
  List<HtmlApp> _apps = [];
  bool _loading = true, _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final l = await hostList();
    if (mounted) {
      setState(() {
        _apps = l;
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      final a = await hostAdd();
      if (a != null) {
        await _reload();
        if (mounted) _open(a);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _err = e is FormatException ? e.message : 'تعذر فتح الملف.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _open(HtmlApp a) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => _ViewerPage(app: a)));
  }

  Future<void> _delete(HtmlApp a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('حذف «${a.name}»؟'),
        content: const Text('يُحذف الملف المحفوظ على الجهاز.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('لا')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      await hostDelete(a.id);
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('تشغيل صفحة HTML')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!hostSupported)
            Text('هذه الأداة غير مدعومة على هذا الجهاز.',
                style: TextStyle(color: t.colorScheme.error))
          else ...[
            FilledButton.icon(
              onPressed: _busy ? null : _add,
              icon: const Icon(Icons.upload_file),
              label: const Text('إضافة ملف HTML أو مشروع ZIP'),
            ),
            if (_busy)
              const Padding(
                  padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
            if (_err != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_err!, style: TextStyle(color: t.colorScheme.error)),
              ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_apps.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text('ما أضفت صفحات بعد.',
                    textAlign: TextAlign.center,
                    style: t.textTheme.bodyMedium
                        ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              )
            else
              for (final a in _apps)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(a.zip ? Icons.folder_zip_outlined : Icons.html),
                    title: Text(a.name, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${a.zip ? 'مشروع ZIP' : 'صفحة HTML'} • ${_when(a.ts)}'),
                    trailing: IconButton(
                      tooltip: 'حذف',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(a),
                    ),
                    onTap: () => _open(a),
                  ),
                ),
            const SizedBox(height: 12),
            Text(
                'الملف أو المشروع يُحفظ على تخزين جهازك، وما تضيفه داخل الصفحة نفسها يبقى محفوظًا في جهازك أيضًا. للمشاريع ZIP يلزم ملف index.html (أو أي ملف HTML واحد على الأقل). ربط الصفحات بقاعدة بيانات نضيفه لاحقًا.',
                style: t.textTheme.bodySmall
                    ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _ViewerPage extends StatelessWidget {
  final HtmlApp app;
  const _ViewerPage({required this.app});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(app.name, overflow: TextOverflow.ellipsis)),
        body: SafeArea(top: false, child: hostView(app)),
      );
}
