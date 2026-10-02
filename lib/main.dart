import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'navigation/shell.dart';
import 'theme/app_theme.dart';

void main() => runApp(const MyToolsApp());

class MyToolsApp extends StatelessWidget {
  const MyToolsApp({super.key});
  @override
  Widget build(BuildContext context) {
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
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const Shell(),
    );
  }
}
