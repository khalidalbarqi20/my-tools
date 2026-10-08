/// أدوات لا نعرض فيها إعلانات إطلاقًا (شاشة كاملة، كاميرا، أو نقر متكرر).
const noAdTools = <String>{
  'dev_screen',
  'dev_touch',
  'qr_scan',
  'rand_counter',
};

/// سياسة الإعلان البيني: لا يظهر إلا بعد إنهاء المستخدم عدة أدوات،
/// وبعد فترة تهدئة من بداية التطبيق، وبفاصل زمني أدنى بين إعلانين.
class InterstitialPolicy {
  final DateTime start;
  int everyN;
  Duration minGap, warmup;
  InterstitialPolicy({
    required this.start,
    this.everyN = 5,
    this.minGap = const Duration(minutes: 3),
    this.warmup = const Duration(seconds: 90),
  });

  int _finished = 0;
  DateTime? _last;

  /// يُستدعى عند إغلاق المستخدم لأداة.
  void registerFinish() => _finished++;

  bool due(DateTime now) {
    if (_finished < everyN) return false;
    if (now.difference(start) < warmup) return false;
    final l = _last;
    if (l != null && now.difference(l) < minGap) return false;
    return true;
  }

  void markShown(DateTime now) {
    _last = now;
    _finished = 0;
  }
}
