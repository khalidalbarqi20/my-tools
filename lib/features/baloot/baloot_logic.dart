/// منطق حاسبة البلوت (منقول حرفيًا من حاسبة البلوت الأصلية: صن وحكم).
library;

enum BalootKind { sun, hakam }

class _Cfg {
  final String name;
  final int base, total;

  /// (الاسم، نقاط المشروع الواحد، أعداده)
  final List<(String, int, int)> projects;

  /// نقاط البلوت (حكم فقط): 0 = لا يوجد.
  final int balotPts;
  const _Cfg(this.name, this.base, this.total, this.projects, this.balotPts);
}

const _cfgSun = _Cfg('حسبة الصن', 26, 130,
    [('سرا', 20, 4), ('خمسين', 50, 10), ('مية', 100, 20), ('أربعمية', 200, 40)], 0);
const _cfgHakam = _Cfg('حسبة الحكم', 16, 162,
    [('سرا', 20, 2), ('خمسين', 50, 5), ('مية', 100, 10)], 2);

_Cfg _cfg(BalootKind k) => k == BalootKind.sun ? _cfgSun : _cfgHakam;

String balootTitle(BalootKind k) => _cfg(k).name;
int balootTotal(BalootKind k) => _cfg(k).total;
List<String> balootProjectNames(BalootKind k) =>
    [for (final p in _cfg(k).projects) p.$1];
bool balootHasBalot(BalootKind k) => _cfg(k).balotPts > 0;

/// تحويل نقاط الأوراق إلى «أعداد» (الأسكور الصغير).
int balootConv(BalootKind k, int x) {
  if (x < 5) return 0;
  if (k == BalootKind.sun) {
    if (x % 10 == 5) return 2 * (x ~/ 10) + 1;
    return 2 * (x / 10).round();
  }
  if (x <= 15) return 1;
  return (x + 4) ~/ 10;
}

/// مدخلات فريق: عدد كل مشروع + عدد البلوت.
class TeamInput {
  final List<int> n;
  final int bal;
  const TeamInput(this.n, this.bal);
}

class _TeamInfo {
  final int top, pts, un, bal, bp;
  const _TeamInfo(this.top, this.pts, this.un, this.bal, this.bp);
}

_TeamInfo _team(BalootKind k, TeamInput t) {
  final c = _cfg(k);
  var top = -1, pts = 0, un = 0;
  for (var j = 0; j < c.projects.length; j++) {
    final n = j < t.n.length ? t.n[j] : 0;
    if (n != 0) {
      top = j;
      pts += n * c.projects[j].$2;
      un += n * c.projects[j].$3;
    }
  }
  final nb = c.balotPts > 0 ? t.bal : 0;
  return _TeamInfo(top, pts, un, nb * c.balotPts, nb * 20);
}

class _PInfo {
  final _TeamInfo a, b;
  final List<int> pu, pp;
  final int total;
  const _PInfo(this.a, this.b, this.pu, this.pp, this.total);
}

_PInfo _pinfo(BalootKind k, TeamInput ta, TeamInput tb) {
  final c = _cfg(k);
  final a = _team(k, ta), b = _team(k, tb);
  final pu = [0, 0], pp = [0, 0];
  if (a.top > b.top || (a.top == b.top && a.pts > b.pts)) {
    pu[0] = a.un;
    pp[0] = a.pts;
  } else if (b.top > a.top || (a.top == b.top && b.pts > a.pts)) {
    pu[1] = b.un;
    pp[1] = b.pts;
  }
  return _PInfo(a, b, pu, pp, c.total + pp[0] + pp[1] + a.bp + b.bp);
}

/// إجمالي اللعب مع المشاريع (يظهر فوق خانات الأوراق).
int balootGameTotal(BalootKind k, TeamInput a, TeamInput b) =>
    _pinfo(k, a, b).total;

class BalootResult {
  final bool outOfRange;
  final int total;
  final List<int> points; // نقاط كل فريق مع المشاريع
  final List<int> cards; // نقاط الأوراق
  final List<int> counts; // الأعداد
  final bool tie, ok;
  final List<int> fin; // النتيجة النهائية
  const BalootResult({
    required this.outOfRange,
    required this.total,
    this.points = const [0, 0],
    this.cards = const [0, 0],
    this.counts = const [0, 0],
    this.tie = false,
    this.ok = false,
    this.fin = const [0, 0],
  });
}

/// [by] رقم فريق المشتري (0 أو 1)، [fb] نقاط أوراق المشتري.
BalootResult balootEval(
    BalootKind k, int by, int fb, TeamInput ta, TeamInput tb) {
  final c = _cfg(k);
  final pi = _pinfo(k, ta, tb);
  final cp = [0, 0];
  cp[by] = fb;
  cp[1 - by] = c.total - fb;
  if (!(cp[0] >= 0 && cp[1] >= 0)) {
    return BalootResult(outOfRange: true, total: c.total);
  }
  final infos = [pi.a, pi.b];
  final p = [
    cp[0] + pi.pp[0] + pi.a.bp,
    cp[1] + pi.pp[1] + pi.b.bp,
  ];
  final u = [0, 0];
  u[by] = balootConv(k, cp[by]);
  u[1 - by] = c.base - u[by];
  final t = [
    u[0] + pi.pu[0] + pi.a.bal,
    u[1] + pi.pu[1] + pi.b.bal,
  ];
  final m = p[by], o = p[1 - by];
  final tie = m == o, ok = m > o;
  final f = [...t];
  if (!ok && !tie) {
    final all = c.base + pi.pu[0] + pi.pu[1];
    f[by] = infos[by].bal;
    f[1 - by] = all + infos[1 - by].bal;
  }
  return BalootResult(
    outOfRange: false,
    total: pi.total,
    points: p,
    cards: cp,
    counts: t,
    tie: tie,
    ok: ok,
    fin: f,
  );
}
