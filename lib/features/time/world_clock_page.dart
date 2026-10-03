import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../../core/display_card.dart';
import 'time_logic.dart';
import 'world_cities.dart';

bool _tzReady = false;
void _initTz() {
  if (!_tzReady) {
    tzdata.initializeTimeZones();
    _tzReady = true;
  }
}

bool _known(String id) {
  try {
    tz.getLocation(id);
    return true;
  } catch (_) {
    return false;
  }
}

class _CityPicker extends StatefulWidget {
  final Set<String> exclude;
  const _CityPicker({required this.exclude});
  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final list = [
      for (final c in worldCities)
        if (!widget.exclude.contains(c.$1) &&
            (_q.isEmpty || c.$2.contains(_q) || c.$1.toLowerCase().contains(_q.toLowerCase())))
          c
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              onChanged: (v) => setState(() => _q = v.trim()),
              decoration: const InputDecoration(
                  hintText: 'ابحث عن مدينة...', prefixIcon: Icon(Icons.search)),
            ),
          ),
          Expanded(
            child: ListView(children: [
              for (final c in list)
                ListTile(
                  title: Text(c.$2),
                  subtitle: Text(c.$1),
                  onTap: () => Navigator.pop(context, c.$1),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class WorldClockPage extends StatefulWidget {
  const WorldClockPage({super.key});
  @override
  State<WorldClockPage> createState() => _WorldClockPageState();
}

class _WorldClockPageState extends State<WorldClockPage> {
  List<String> _ids = [
    'Asia/Riyadh', 'Asia/Dubai', 'Africa/Cairo', 'Europe/London',
    'America/New_York', 'Asia/Tokyo'
  ];
  SharedPreferences? _p;
  Timer? _t;
  String _from = 'Asia/Riyadh';
  String _to = 'America/New_York';

  @override
  void initState() {
    super.initState();
    _initTz();
    SharedPreferences.getInstance().then((p) {
      _p = p;
      final l = p.getStringList('world_clock');
      if (l != null && mounted) setState(() => _ids = l.where(_known).toList());
    });
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _save() => _p?.setStringList('world_clock', _ids);

  Future<void> _add() async {
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CityPicker(exclude: _ids.toSet()),
    );
    if (id == null || !mounted) return;
    setState(() => _ids = [..._ids, id]);
    _save();
  }

  Widget _city(String id) {
    final t = Theme.of(context);
    final now = tz.TZDateTime.now(tz.getLocation(id));
    final diff = now.timeZoneOffset - DateTime.now().timeZoneOffset;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DisplayCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cityName(id),
                  style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              Text('${weekdayAr(now)} ${fmtDate(now)}',
                  style: t.textTheme.bodySmall),
              Text(offsetLabel(diff),
                  style: t.textTheme.bodySmall
                      ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            ]),
          ),
          Text(
            '${fmtTime(now)}:${p2(now.second)}',
            style: t.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          IconButton(
            tooltip: 'إزالة',
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() => _ids = _ids.where((x) => x != id).toList());
              _save();
            },
          ),
        ]),
      ),
    );
  }

  Widget _drop(String label, String value, ValueChanged<String> on) =>
      DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final c in worldCities) DropdownMenuItem(value: c.$1, child: Text(c.$2))
        ],
        onChanged: (v) => on(v ?? value),
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final a = tz.TZDateTime.now(tz.getLocation(_from)).timeZoneOffset;
    final b = tz.TZDateTime.now(tz.getLocation(_to)).timeZoneOffset;
    final d = b - a;
    final res = _from == _to || d.inMinutes == 0
        ? 'نفس التوقيت'
        : '${cityName(_to)} ${d.isNegative ? 'تتأخر عن' : 'تسبق'} ${cityName(_from)} بـ ${hoursPhrase(d)}';
    return Scaffold(
      appBar: AppBar(title: const Text('ساعة عالمية')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final id in _ids) _city(id),
          OutlinedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('إضافة مدينة')),
          const SizedBox(height: 28),
          Text('فرق التوقيت بين مدينتين',
              style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _drop('من', _from, (v) => setState(() => _from = v)),
          const SizedBox(height: 12),
          _drop('إلى', _to, (v) => setState(() => _to = v)),
          const SizedBox(height: 12),
          DisplayCard(
            child: Text(res,
                style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
