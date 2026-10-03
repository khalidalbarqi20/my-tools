import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/display_card.dart';
import 'text_logic.dart';

class WordCountPage extends StatefulWidget {
  const WordCountPage({super.key});
  @override
  State<WordCountPage> createState() => _WordCountPageState();
}

class _WordCountPageState extends State<WordCountPage> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    final t = d?.text;
    if (t != null && mounted) setState(() => _c.text = t);
  }

  Widget _tile(String n, String label) {
    final t = Theme.of(context);
    return DisplayCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(n,
              style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          Text(label,
              style: t.textTheme.bodySmall
                  ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = textStats(_c.text);
    final mins = s.readMinutes;
    final read = s.words == 0
        ? '—'
        : mins < 1
            ? 'أقل من دقيقة'
            : '${mins.ceil()} دقيقة';
    return Scaffold(
      appBar: AppBar(title: const Text('عداد الكلمات والأحرف')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _c,
            minLines: 6,
            maxLines: 14,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'اكتب أو الصق النص هنا...'),
          ),
          const SizedBox(height: 8),
          Row(children: [
            TextButton.icon(
                onPressed: _paste,
                icon: const Icon(Icons.content_paste, size: 18),
                label: const Text('لصق')),
            TextButton.icon(
                onPressed: _c.text.isEmpty ? null : () => setState(_c.clear),
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('مسح')),
          ]),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _tile('${s.words}', 'كلمة'),
              _tile('${s.chars}', 'حرف'),
              _tile('${s.charsNoSpaces}', 'حرف بدون مسافات'),
              _tile('${s.lines}', 'سطر'),
              _tile('${s.sentences}', 'جملة'),
              _tile('${s.paragraphs}', 'فقرة'),
            ],
          ),
          const SizedBox(height: 10),
          DisplayCard(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const Icon(Icons.menu_book_outlined),
              const SizedBox(width: 10),
              Expanded(child: Text('وقت القراءة التقريبي: $read')),
            ]),
          ),
        ],
      ),
    );
  }
}
