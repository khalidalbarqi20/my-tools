import 'package:flutter/material.dart';
import '../../core/tool.dart';
import 'countdown_page.dart';
import 'date_diff_page.dart';
import 'pomodoro_page.dart';
import 'stopwatch_page.dart';
import 'timer_page.dart';
import 'world_clock_page.dart';

final List<Tool> timeTools = [
  Tool(
    id: 'time_stopwatch',
    nameAr: 'ساعة إيقاف',
    nameEn: 'Stopwatch',
    category: 'time',
    keywords: ['ستوب واتش', 'توقيت', 'دورات', 'وقت', 'stopwatch', 'lap', 'time'],
    icon: Icons.timer_outlined,
    builder: (_) => const StopwatchPage(),
  ),
  Tool(
    id: 'time_timer',
    nameAr: 'مؤقت',
    nameEn: 'Timer',
    category: 'time',
    keywords: ['تايمر', 'عد تنازلي', 'منبه', 'وقت', 'timer', 'countdown', 'alarm'],
    icon: Icons.hourglass_bottom,
    builder: (_) => const TimerPage(),
  ),
  Tool(
    id: 'time_countdown',
    nameAr: 'عد تنازلي لمناسبة',
    nameEn: 'Event Countdown',
    category: 'time',
    keywords: ['مناسبة', 'موعد', 'باقي', 'أيام', 'عيد', 'سفر', 'countdown', 'event', 'days left'],
    icon: Icons.event_available_outlined,
    builder: (_) => const CountdownPage(),
  ),
  Tool(
    id: 'time_pomodoro',
    nameAr: 'بومودورو',
    nameEn: 'Pomodoro',
    category: 'time',
    keywords: ['تركيز', 'مذاكرة', 'دراسة', 'استراحة', 'عمل', 'pomodoro', 'focus', 'study'],
    icon: Icons.self_improvement,
    builder: (_) => const PomodoroPage(),
  ),
  Tool(
    id: 'time_world',
    nameAr: 'ساعة عالمية وفرق التوقيت',
    nameEn: 'World Clock',
    category: 'time',
    keywords: ['مدن', 'توقيت', 'فرق التوقيت', 'منطقة زمنية', 'world clock', 'time zone', 'timezone', 'time difference'],
    icon: Icons.public,
    builder: (_) => const WorldClockPage(),
  ),
  Tool(
    id: 'time_datediff',
    nameAr: 'فرق التواريخ',
    nameEn: 'Date Difference',
    category: 'time',
    keywords: ['تاريخ', 'أيام', 'بين تاريخين', 'إضافة أيام', 'date', 'difference', 'days between', 'add days'],
    icon: Icons.date_range,
    builder: (_) => const DateDiffPage(),
  ),
];
