import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/storage/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.init();
  });
  test('المفضلة', () {
    Prefs.toggleFav('a');
    expect(Prefs.favorites.value, ['a']);
    Prefs.toggleFav('a');
    expect(Prefs.favorites.value, isEmpty);
  });
  test('آخر استخدام: ترتيب وحد أقصى', () {
    for (var i = 0; i < 12; i++) {
      Prefs.addRecent('t$i');
    }
    Prefs.addRecent('t5');
    expect(Prefs.recents.value.first, 't5');
    expect(Prefs.recents.value.length, 8);
    expect(Prefs.recents.value.where((e) => e == 't5').length, 1);
  });
}
