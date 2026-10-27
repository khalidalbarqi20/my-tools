import 'package:flutter/material.dart';
import 'life_logic.dart';
import 'life_store.dart';

const _k = 'life_notes_v1';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Note> _all = [];
  String _q = '';

  @override
  void initState() {
    super.initState();
    loadList(_k).then((l) {
      if (mounted) setState(() => _all = [for (final m in l) Note.fromJson(m)]);
    });
  }

  Future<void> _save() async {
    _all.sort((a, b) => b.ts.compareTo(a.ts));
    await saveList(_k, [for (final n in _all) n.toJson()]);
  }

  Future<void> _edit([Note? n]) async {
    final res = await Navigator.push<Note>(
        context, MaterialPageRoute(builder: (_) => _NoteEditor(note: n)));
    if (res == null) return;
    setState(() {
      if (n == null) {
        _all.add(res);
      } else {
        n.title = res.title;
        n.body = res.body;
        n.ts = res.ts;
      }
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final list = searchNotes(_all, _q);
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('ملاحظاتي')),
      floatingActionButton: FloatingActionButton(onPressed: () => _edit(), child: const Icon(Icons.add)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'بحث في الملاحظات'),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text(_all.isEmpty ? 'ما فيه ملاحظات بعد. اضغط + للإضافة.' : 'لا نتائج.',
                      style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)))
              : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 88), children: [
                  for (final n in list)
                    Dismissible(
                      key: ValueKey(n.id),
                      background: Container(color: t.colorScheme.errorContainer),
                      onDismissed: (_) async {
                        setState(() => _all.removeWhere((x) => x.id == n.id));
                        await _save();
                      },
                      child: Card(
                        child: ListTile(
                          title: Text(n.title.isEmpty ? 'بدون عنوان' : n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                          onTap: () => _edit(n),
                        ),
                      ),
                    ),
                ]),
        ),
      ]),
    );
  }
}

class _NoteEditor extends StatefulWidget {
  final Note? note;
  const _NoteEditor({this.note});
  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final _t = TextEditingController(text: widget.note?.title ?? '');
  late final _b = TextEditingController(text: widget.note?.body ?? '');

  @override
  void dispose() {
    _t.dispose();
    _b.dispose();
    super.dispose();
  }

  void _done() {
    if (_t.text.trim().isEmpty && _b.text.trim().isEmpty) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(
        context,
        Note(widget.note?.id ?? newId(), _t.text.trim(), _b.text,
            DateTime.now().millisecondsSinceEpoch));
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _done();
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('ملاحظة'), actions: [
            TextButton(onPressed: _done, child: const Text('تم')),
          ]),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              TextField(controller: _t, decoration: const InputDecoration(labelText: 'العنوان')),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _b,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(labelText: 'النص', alignLabelWithHint: true),
                ),
              ),
            ]),
          ),
        ),
      );
}
