/// صفحة/مشروع HTML محفوظ على الجهاز.
class HtmlApp {
  final String id, name, entry;
  final bool zip;
  final int ts;
  const HtmlApp({
    required this.id,
    required this.name,
    required this.zip,
    required this.ts,
    this.entry = 'index.html',
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'zip': zip, 'ts': ts, 'entry': entry};

  factory HtmlApp.fromJson(Map<String, dynamic> j) => HtmlApp(
        id: '${j['id']}',
        name: '${j['name']}',
        zip: j['zip'] == true,
        ts: (j['ts'] as num?)?.toInt() ?? 0,
        entry: '${j['entry'] ?? 'index.html'}',
      );
}
