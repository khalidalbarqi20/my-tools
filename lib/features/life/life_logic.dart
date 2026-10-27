/// منطق الملاحظات والمهام والعادات (دوال نقية قابلة للاختبار).
library;

String two(int n) => n < 10 ? '0$n' : '$n';

/// مفتاح اليوم «2026-10-27».
String dayKey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

/// عدد الأيام المتتالية المنجزة. إن لم يُنجز اليوم بعد، يُحسب التسلسل المنتهي أمس.
int habitStreak(Set<String> days, DateTime today) {
  var d = DateTime(today.year, today.month, today.day);
  if (!days.contains(dayKey(d))) d = d.subtract(const Duration(days: 1));
  var n = 0;
  while (days.contains(dayKey(d))) {
    n++;
    d = DateTime(d.year, d.month, d.day - 1);
  }
  return n;
}

class Note {
  final String id;
  String title, body;
  int ts;
  Note(this.id, this.title, this.body, this.ts);
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'body': body, 'ts': ts};
  factory Note.fromJson(Map<String, dynamic> j) =>
      Note('${j['id']}', '${j['title']}', '${j['body']}', (j['ts'] as num?)?.toInt() ?? 0);
}

class Task {
  final String id;
  String text;
  bool done;
  Task(this.id, this.text, this.done);
  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'done': done};
  factory Task.fromJson(Map<String, dynamic> j) =>
      Task('${j['id']}', '${j['text']}', j['done'] == true);
}

class Habit {
  final String id;
  String name;
  final Set<String> days;
  Habit(this.id, this.name, this.days);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'days': days.toList()};
  factory Habit.fromJson(Map<String, dynamic> j) => Habit('${j['id']}', '${j['name']}',
      {for (final d in (j['days'] as List? ?? [])) '$d'});
}

/// فلتر المهام: 0 الكل، 1 المتبقية، 2 المنجزة.
List<Task> filterTasks(List<Task> all, int mode) => [
      for (final t in all)
        if (mode == 0 || (mode == 1 && !t.done) || (mode == 2 && t.done)) t
    ];

/// بحث في الملاحظات (العنوان أو النص).
List<Note> searchNotes(List<Note> all, String q) {
  final s = q.trim().toLowerCase();
  if (s.isEmpty) return all;
  return [
    for (final n in all)
      if (n.title.toLowerCase().contains(s) || n.body.toLowerCase().contains(s)) n
  ];
}
