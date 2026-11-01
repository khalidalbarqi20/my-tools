import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../pdf/pdf_common.dart' show OutFile, baseName, humanSize, pickPicked, saveOut, shareOut;
import 'meta_logic.dart';

class _Item {
  final String name;
  final int before;
  final StripResult? res;
  final String? err;
  _Item(this.name, this.before, this.res, this.err);
}

class MetaPage extends StatefulWidget {
  const MetaPage({super.key});
  @override
  State<MetaPage> createState() => _MetaPageState();
}

class _MetaPageState extends State<MetaPage> {
  final List<_Item> _items = [];
  bool _busy = false;

  Future<void> _pick() async {
    setState(() => _busy = true);
    try {
      final fs = await pickPicked(type: FileType.image);
      _items.clear();
      for (final f in fs) {
        try {
          if (f.bytes.length > 60 * 1024 * 1024) throw const FormatException('الصورة كبيرة (الحد 60 ميجابايت)');
          _items.add(_Item(f.name, f.bytes.length, stripMetadata(Uint8List.fromList(f.bytes)), null));
        } on FormatException catch (e) {
          _items.add(_Item(f.name, f.bytes.length, null, e.message));
        }
      }
    } catch (_) {
      _items.add(_Item('—', 0, null, 'تعذر قراءة الملفات'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  OutFile _out(_Item it) {
    final r = it.res!;
    return OutFile('${baseName(it.name)}_clean.${r.ext}', r.bytes, r.ext == 'png' ? 'image/png' : 'image/jpeg');
  }

  List<Widget> _findings(MetaInfo m) {
    final l = <String>[];
    if (m.gps) l.add('📍 موقع GPS (يكشف مكان التصوير)');
    if (m.device != null) l.add('📱 الجهاز: ${m.device}');
    if (m.date != null && m.date!.isNotEmpty) l.add('🕒 وقت التصوير: ${m.date}');
    if (m.software != null && m.software!.isNotEmpty) l.add('💻 البرنامج: ${m.software}');
    if (m.xmp) l.add('📄 بيانات XMP');
    if (m.found && l.isEmpty) l.add('بيانات وصفية أخرى');
    if (l.isEmpty) l.add('لا توجد بيانات وصفية ✅');
    return [for (final s in l) Text(s)];
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final ok = _items.where((e) => e.res != null).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('حذف بيانات الصور (EXIF)')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('اختر صورًا')),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
        const SizedBox(height: 12),
        for (final it in _items)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(it.name, style: t.textTheme.titleSmall, overflow: TextOverflow.ellipsis),
                if (it.err != null)
                  Text(it.err!, style: TextStyle(color: t.colorScheme.error))
                else ...[
                  Text('${humanSize(it.before)} ← ${humanSize(it.res!.bytes.length)}',
                      style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  ..._findings(it.res!.before),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    FilledButton.tonalIcon(
                        onPressed: () => saveOut(context, _out(it)),
                        icon: const Icon(Icons.save_alt),
                        label: const Text('حفظ النظيفة')),
                  ]),
                ],
              ]),
            ),
          ),
        if (ok.length > 1)
          OutlinedButton.icon(
              onPressed: () => shareOut(context, [for (final e in ok) _out(e)]),
              icon: const Icon(Icons.share),
              label: Text('مشاركة الكل (${ok.length})')),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
              'يحذف الموقع والجهاز والتاريخ وغيرها دون إعادة ضغط الصورة، فلا تتغير جودتها. يحتفظ باتجاه الصورة حتى لا تنقلب. يدعم JPG و PNG (الصيغ الأخرى حوّلها أولًا). اللقطات المرسلة عبر واتساب غالبًا بلا بيانات أصلًا.',
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ),
      ]),
    );
  }
}
