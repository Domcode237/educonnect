import 'package:flutter/material.dart';

const Color bleuProfond = Color(0xFF03045F); // bleu foncé login page
const Color couleurTexteSombre = Colors.white;
const Color fondSombre = Color(0xFF1C1C1E);
const Color fondClairAssombri = Color.fromARGB(33, 253, 253, 253);

final ThemeData themeSombre = ThemeData(
  brightness: Brightness.dark,
  primaryColor: bleuProfond,
  scaffoldBackgroundColor: fondSombre,

  // AppBar
  appBarTheme: const AppBarTheme(
    backgroundColor: bleuProfond,
    foregroundColor: Colors.white,
    elevation: 2,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    ),
    iconTheme: IconThemeData(
      color: Colors.white,
      size: 26,
    ),
  ),

  // Drawer
  drawerTheme: const DrawerThemeData(
    backgroundColor: Color(0xFF121212),
    elevation: 10,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
    ),
    scrimColor: Color.fromARGB(120, 3, 4, 95), // bleu foncé avec opacité
  ),

  // ElevatedButton
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: bleuProfond,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      elevation: 4,
      shadowColor: bleuProfond.withOpacity(0.6),
    ),
  ),

  // TextButton
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: bleuProfond.withOpacity(0.9),
      backgroundColor: fondClairAssombri,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(40),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
      ),
    ),
  ),

  // FloatingActionButton
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: bleuProfond,
    foregroundColor: Colors.white,
    elevation: 6,
  ),

  // BottomNavigationBar
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: bleuProfond,
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white70,
    showSelectedLabels: true,
    showUnselectedLabels: true,
    selectedIconTheme: const IconThemeData(size: 30, color: Colors.white),
    unselectedIconTheme: const IconThemeData(size: 24, color: Colors.white70),
    selectedLabelStyle: const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      letterSpacing: 0.4,
    ),
    unselectedLabelStyle: const TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 11,
      letterSpacing: 0.2,
    ),
    type: BottomNavigationBarType.fixed,
    elevation: 12,
  ),

  // NavigationRail
  navigationRailTheme: NavigationRailThemeData(
    backgroundColor: bleuProfond,
    selectedIconTheme: const IconThemeData(size: 34, color: Colors.white),
    unselectedIconTheme: const IconThemeData(size: 26, color: Colors.white70),
    selectedLabelTextStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 16,
      letterSpacing: 0.5,
    ),
    unselectedLabelTextStyle: const TextStyle(
      color: Colors.white70,
      fontWeight: FontWeight.w400,
      fontSize: 14,
      letterSpacing: 0.3,
    ),
    indicatorColor: bleuProfond.withOpacity(0.8),
    elevation: 10,
    minWidth: 160,
    labelType: NavigationRailLabelType.all,
  ),

  // Textes globaux
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: couleurTexteSombre),
    bodyMedium: TextStyle(color: couleurTexteSombre.withOpacity(0.85)),
    displayLarge: TextStyle(color: couleurTexteSombre),
    displayMedium: TextStyle(color: couleurTexteSombre),
    displaySmall: TextStyle(color: couleurTexteSombre),
    titleLarge: TextStyle(color: couleurTexteSombre),
    titleMedium: TextStyle(color: couleurTexteSombre.withOpacity(0.85)),
    titleSmall: TextStyle(color: couleurTexteSombre.withOpacity(0.85)),
    labelLarge: TextStyle(color: couleurTexteSombre),
    labelMedium: TextStyle(color: couleurTexteSombre.withOpacity(0.85)),
    labelSmall: TextStyle(color: couleurTexteSombre.withOpacity(0.85)),
    headlineMedium: TextStyle(
      color: couleurTexteSombre,
      fontSize: 26,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.6,
    ),
  ),
);
