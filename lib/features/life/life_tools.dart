import 'package:flutter/material.dart';
import '../../core/tool.dart';
import 'habits_page.dart';
import 'notes_page.dart';
import 'prayer_page.dart';
import 'tasks_page.dart';

Tool _t(String id, String ar, String en, List<String> kw, IconData icon, WidgetBuilder b) => Tool(
      id: id,
      nameAr: ar,
      nameEn: en,
      category: 'life',
      keywords: ['حياة', 'يومي', 'life', 'daily', ...kw],
      icon: icon,
      builder: b,
    );

final List<Tool> lifeTools = [
  _t('life_prayer', 'مواقيت الصلاة والقبلة', 'Prayer Times & Qibla',
      ['صلاة', 'اذان', 'أذان', 'فجر', 'قبلة', 'prayer', 'adhan', 'qibla', 'salah'],
      Icons.mosque_outlined, (_) => const PrayerPage()),
  _t('life_notes', 'ملاحظاتي', 'Notes',
      ['ملاحظة', 'مذكرة', 'كتابة', 'note', 'memo', 'notes'],
      Icons.sticky_note_2_outlined, (_) => const NotesPage()),
  _t('life_tasks', 'مهامي', 'To-do',
      ['مهمة', 'قائمة', 'todo', 'task', 'checklist', 'tasks'],
      Icons.checklist, (_) => const TasksPage()),
  _t('life_habits', 'عاداتي', 'Habit Tracker',
      ['عادة', 'تتبع', 'habit', 'streak', 'tracker', 'habits'],
      Icons.local_fire_department_outlined, (_) => const HabitsPage()),
];
