import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'prayer_logic.dart';

const _kCity = 'prayer_city';
const _kLat = 'prayer_lat';
const _kLng = 'prayer_lng';
const _kHanafi = 'prayer_hanafi';
const _custom = -1;

class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});
  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  int _city = 0; // فهرس المدينة أو -1 للمخصص
  double _lat = 24.7136, _lng = 46.6753;
  bool _hanafi = false;
  DateTime _day = DateTime.now();
  DateTime _now = DateTime.now();
  Timer? _timer;
  final _latC = TextEditingController();
  final _lngC = TextEditingController();
  SharedPreferences? _p;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _latC.dispose();
    _lngC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _p = p;
      final c = p.getInt(_kCity) ?? 0;
      setState(() {
        _city = c < cities.length ? c : 0;
        _hanafi = p.getBool(_kHanafi) ?? false;
        if (c == _custom) {
          _city = _custom;
          _lat = p.getDouble(_kLat) ?? _lat;
          _lng = p.getDouble(_kLng) ?? _lng;
          _latC.text = '$_lat';
          _lngC.text = '$_lng';
        }
      });
    } catch (_) {}
  }

  double get _la => _city == _custom ? _lat : cities[_city].lat;
  double get _lo => _city == _custom ? _lng : cities[_city].lng;

  double _tz(DateTime d) =>
      _city == _custom ? DateTime(d.year, d.month, d.day, 12).timeZoneOffset.inMinutes / 60 : 3.0;

  void _setCity(int c) {
    setState(() => _city = c);
    _p?.setInt(_kCity, c);
  }

  void _applyCustom() {
    final la = double.tryParse(_latC.text.trim());
    final lo = double.tryParse(_lngC.text.trim());
    if (la == null || lo == null || la.abs() > 66 || lo.abs() > 180) return;
    setState(() {
      _lat = la;
      _lng = lo;
    });
    _p?.setDouble(_kLat, la);
    _p?.setDouble(_kLng, lo);
  }

  String _left(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    return '${h}س ${m}د ${s}ث';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final p = calcPrayer(_day, _la, _lo, _tz(_day), hanafi: _hanafi);
    final isToday = _day.year == _now.year && _day.month == _now.month && _day.day == _now.day;
    final nx = nextPrayer(_now, _la, _lo, _tz(_now), hanafi: _hanafi);
    final rows = [
      ('الفجر', p.fajr),
      ('الشروق', p.sunrise),
      ('الظهر', p.dhuhr),
      ('العصر', p.asr),
      ('المغرب', p.maghrib),
      ('العشاء', p.isha),
    ];
    final q = qiblaBearing(_la, _lo);
    return Scaffold(
      appBar: AppBar(title: const Text('مواقيت الصلاة')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<int>(
          initialValue: _city,
          decoration: const InputDecoration(labelText: 'المدينة'),
          items: [
            for (var i = 0; i < cities.length; i++)
              DropdownMenuItem(value: i, child: Text(cities[i].name)),
            const DropdownMenuItem(value: _custom, child: Text('إحداثيات مخصصة…')),
          ],
          onChanged: (v) {
            if (v != null) _setCity(v);
          },
        ),
        if (_city == _custom) ...[
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _latC,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  onChanged: (_) => _applyCustom(),
                  decoration: const InputDecoration(labelText: 'خط العرض'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _lngC,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  onChanged: (_) => _applyCustom(),
                  decoration: const InputDecoration(labelText: 'خط الطول'),
                ),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 16),
        Card(
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Text('الصلاة القادمة: ${nx.name}',
                  style: t.textTheme.titleMedium?.copyWith(color: cs.onPrimaryContainer)),
              const SizedBox(height: 4),
              Text(_left(nx.left),
                  style: t.textTheme.headlineSmall?.copyWith(
                      color: cs.onPrimaryContainer, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
              onPressed: () => setState(() => _day = _day.subtract(const Duration(days: 1))),
              icon: const Icon(Icons.chevron_right)),
          TextButton(
              onPressed: () => setState(() => _day = DateTime.now()),
              child: Text(isToday ? 'اليوم' : '${_day.year}/${_day.month}/${_day.day}')),
          IconButton(
              onPressed: () => setState(() => _day = _day.add(const Duration(days: 1))),
              icon: const Icon(Icons.chevron_left)),
        ]),
        Card(
          child: Column(children: [
            for (final r in rows)
              ListTile(
                dense: true,
                tileColor: isToday && r.$1 == nx.name ? cs.secondaryContainer : null,
                title: Text(r.$1),
                trailing: Text(fmtHm(r.$2),
                    style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
          ]),
        ),
        SwitchListTile(
          title: const Text('العصر بالمذهب الحنفي'),
          value: _hanafi,
          onChanged: (v) {
            setState(() => _hanafi = v);
            _p?.setBool(_kHanafi, v);
          },
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(alignment: Alignment.center, children: [
                  Container(
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, border: Border.all(color: cs.outline))),
                  Positioned(top: 2, child: Text('ش', style: t.textTheme.labelSmall)),
                  Transform.rotate(
                      angle: q * math.pi / 180,
                      child: Icon(Icons.navigation, size: 48, color: cs.primary)),
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('اتجاه القبلة', style: t.textTheme.titleSmall),
                  Text('${q.toStringAsFixed(1)}° من الشمال مع عقارب الساعة',
                      style: t.textTheme.bodyMedium),
                  Text('السهم يفترض أن أعلى الشاشة نحو الشمال. للاتجاه الحي استخدم أداة البوصلة.',
                      style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ]),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
              'الحساب فلكي محلي بدون إنترنت على طريقة أم القرى (الفجر ١٨٫٥° والعشاء بعد المغرب بـ ٩٠ دقيقة). النتيجة تقريبية وقد تختلف دقيقة أو دقيقتين عن تقويم أم القرى، وفي رمضان تُزاد ٣٠ دقيقة للعشاء. وقت الصلاة القادمة يعتمد على ساعة جهازك.',
              style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ),
      ]),
    );
  }
}
