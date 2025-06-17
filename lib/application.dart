import 'package:educonnect/coeur/theme/theme_clair.dart';
import 'package:educonnect/coeur/theme/theme_sombre.dart';
import 'package:flutter/material.dart';
import 'package:educonnect/vues/commun/splash_page.dart';
import 'package:educonnect/routes/routes_application.dart';

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeClair,
      darkTheme: themeSombre,
      themeMode: ThemeMode.system,
      home: SplashPage(),
      routes: routes,
    );
  }
}