import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static late SharedPreferences _p;
  static final favorites = ValueNotifier<List<String>>([]);
  static final recents = ValueNotifier<List<String>>([]);

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    favorites.value = _p.getStringList('favs') ?? [];
    recents.value = _p.getStringList('recents') ?? [];
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
}
