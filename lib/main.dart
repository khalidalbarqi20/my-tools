import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'ads/ads.dart';
import 'billing/billing.dart';
import 'navigation/shell.dart';
import 'remote/remote_gate.dart';
import 'remote/remote_store.dart';
import 'storage/prefs.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.init();
  await RemoteStore.loadCache();
  runApp(const MyToolsApp());
  RemoteStore.refresh(); // في الخلفية
  Billing.init().then((_) => Ads.init()); // لا ننتظرها: لا نؤخر فتح التطبيق
}

class MyToolsApp extends StatelessWidget {
  const MyToolsApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([Prefs.themeMode, Prefs.colors]),
      builder: (context, child) {
        final cols = Prefs.colors.value;
        return MaterialApp(
          title: 'أدواتي اليومية',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildTheme(Brightness.light, cols),
          darkTheme: buildTheme(Brightness.dark, cols),
          themeMode: Prefs.themeMode.value,
          home: const RemoteGate(child: Shell()),
        );
      },
    );
  }
}
