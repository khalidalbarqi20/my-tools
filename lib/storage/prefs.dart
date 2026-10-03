import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

class Prefs {
  static late SharedPreferences _p;
  static final favorites = ValueNotifier<List<String>>([]);
  static final recents = ValueNotifier<List<String>>([]);
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);
  static final colors = ValueNotifier<AppColors>(const AppColors());

  static Color? _color(String k) {
    final v = _p.getInt(k);
    return v == null ? null : Color(v);
  }

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    favorites.value = _p.getStringList('favs') ?? [];
    recents.value = _p.getStringList('recents') ?? [];
    final t = _p.getString('theme');
    themeMode.value = t == 'light'
        ? ThemeMode.light
        : (t == 'dark' ? ThemeMode.dark : ThemeMode.system);
    colors.value = AppColors(
        accent: _color('c_accent'), bg: _color('c_bg'), icon: _color('c_icon'));
  }

  static void toggleFav(String id) {
    final l = List<String>.from(favorites.value);
    if (l.contains(id)) {
      l.remove(id);
    } else {
      l.add(id);
    }
    favorites.value = l;
    _p.setStringList('favs', l);
  }

  static void addRecent(String id) {
    final l = List<String>.from(recents.value)
      ..remove(id)
      ..insert(0, id);
    if (l.length > 8) l.removeRange(8, l.length);
    recents.value = l;
    _p.setStringList('recents', l);
  }

  static void clearRecents() {
    recents.value = [];
    _p.setStringList('recents', []);
  }

  static void setTheme(ThemeMode m) {
    themeMode.value = m;
    _p.setString('theme',
        m == ThemeMode.light ? 'light' : (m == ThemeMode.dark ? 'dark' : 'system'));
  }

  static void _put(String k, Color? c) {
    if (c == null) {
      _p.remove(k);
    } else {
      _p.setInt(k, c.toARGB32());
    }
  }

  static void setColors(AppColors c) {
    colors.value = c;
    _put('c_accent', c.accent);
    _put('c_bg', c.bg);
    _put('c_icon', c.icon);
  }
}
