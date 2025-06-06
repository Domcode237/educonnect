import 'package:flutter/material.dart';
const Color bleuProfond = Color.fromARGB(255, 25, 49, 82);
final ThemeData themeSombre = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.white,
  scaffoldBackgroundColor: const Color(0xFF1C1C1E),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  //texteButton
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      // side: const BorderSide(
      //   color : Colors.white,
      //   width:  0.75,
      // ),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder( // Bordure arrondie
        borderRadius: BorderRadius.circular(12),
      ),
    )
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
  ),

  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: Colors.white70,
    selectedIconTheme: IconThemeData(size: 32, color: bleuProfond), // Icône plus grande
    unselectedIconTheme: IconThemeData(size: 24, color: bleuProfond),
    selectedLabelTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
    unselectedLabelTextStyle: TextStyle(color: Colors.white),
    indicatorColor: Colors.black, // Arrière-plan plus visible autour de l’icône sélectionnée
    minWidth: 150,
  ),
);
