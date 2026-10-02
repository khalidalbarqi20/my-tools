import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/registry.dart';

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
      theme: ThemeData(
          useMaterial3: true, colorSchemeSeed: const Color(0xFF1E6F5C)),
      darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: const Color(0xFF1E6F5C)),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final tools = allTools.where((t) => t.matches(_q)).toList();
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('أدواتي اليومية',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('كل أدواتك في مكان واحد',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              SearchBar(
                hintText: 'ابحث عن أداة...',
                leading: const Icon(Icons.search),
                onChanged: (v) => setState(() => _q = v),
              ),
            ]),
          ),
          Expanded(
            child: tools.isEmpty
                ? const Center(child: Text('ما لقينا أداة بهذا الاسم'))
                : ListView(
                    children: [
                      for (final t in tools)
                        ListTile(
                          leading: Icon(t.icon),
                          title: Text(t.nameAr),
                          subtitle: Text(t.nameEn),
                          onTap: () => Navigator.push(
                              context, MaterialPageRoute(builder: t.builder)),
                        ),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }
}
