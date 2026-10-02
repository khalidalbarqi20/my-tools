import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'pdf_common.dart';
import 'pdf_ops.dart';

class MergePage extends StatefulWidget {
  const MergePage({super.key});
  @override
  State<MergePage> createState() => _MergePageState();
}

class _MergePageState extends State<MergePage> {
  final List<Picked> _files = [];
  bool _busy = false;
  String? _err;
  List<OutFile> _out = [];

  Future<void> _add() async {
    try {
      final f = await pickPicked(type: FileType.custom, exts: ['pdf']);
      if (f.isEmpty || !mounted) return;
      setState(() {
        _files.addAll(f);
        _out = [];
        _err = null;
      });
    } catch (e) {
      if (mounted) setState(() => _err = friendlyError(e));
    }
  }

  Future<void> _merge() async {
    setState(() {
      _busy = true;
      _err = null;
      _out = [];
    });
    try {
      final o = await mergePdfs(_files);
      if (mounted) setState(() => _out = [o]);
    } catch (e) {
      if (mounted) setState(() => _err = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('دمج PDF')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : _add,
            icon: const Icon(Icons.add),
            label: const Text('إضافة ملفات PDF'),
          ),
          const SizedBox(height: 8),
          if (_files.length > 1)
            Text('اسحب ≡ لترتيب الملفات قبل الدمج',
                style: t.textTheme.bodySmall
                    ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _files.length,
            onReorder: (a, b) => setState(() {
              if (b > a) b--;
              _files.insert(b, _files.removeAt(a));
            }),
            itemBuilder: (c, i) => ListTile(
              key: ObjectKey(_files[i]),
              contentPadding: EdgeInsets.zero,
              leading: ReorderableDragStartListener(
                  index: i, child: const Icon(Icons.drag_handle)),
              title: Text(_files[i].name, overflow: TextOverflow.ellipsis),
              subtitle: Text(humanSize(_files[i].bytes.length)),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _files.removeAt(i);
                          _out = [];
                        }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: (_files.length < 2 || _busy) ? null : _merge,
            child: const Text('دمج الملفات'),
          ),
          if (_files.length == 1)
            const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('أضف ملفًا ثانيًا على الأقل')),
          if (_busy)
            const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator()),
          if (_err != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_err!, style: TextStyle(color: t.colorScheme.error)),
            ),
          ResultList(_out),
        ],
      ),
    );
  }
}
