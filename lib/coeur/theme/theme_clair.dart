import 'package:flutter/material.dart';

const Color bleuProfond = Color.fromARGB(255, 19, 51, 76);
const Color couleurTexteGlobale = Color.fromARGB(255, 19, 51, 76);
const Color fondClairAssombri = Color.fromARGB(255, 245, 245, 245);

final ThemeData themeClair = ThemeData(
  brightness: Brightness.light,
  primaryColor: bleuProfond,
  scaffoldBackgroundColor: Colors.white,

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
    backgroundColor: Colors.white,
    elevation: 10,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
    ),
    scrimColor: Color.fromARGB(120, 19, 51, 76),
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
      foregroundColor: bleuProfond,
      backgroundColor: bleuProfond.withOpacity(0.1),
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

  // BottomNavigationBar amélioré avec labels visibles et style plus moderne
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: bleuProfond,
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white70,
    showSelectedLabels: true,
    showUnselectedLabels: true, // Affiche toujours les labels
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

  // NavigationRail avec labels toujours visibles, indicateur plus doux et joli
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
    labelType: NavigationRailLabelType.all, // Affiche toujours les labels
  ),

  // Textes globaux
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: couleurTexteGlobale),
    bodyMedium: TextStyle(color: couleurTexteGlobale),
    displayLarge: TextStyle(color: couleurTexteGlobale),
    displayMedium: TextStyle(color: couleurTexteGlobale),
    displaySmall: TextStyle(color: couleurTexteGlobale),
    titleLarge: TextStyle(color: couleurTexteGlobale),
    titleMedium: TextStyle(color: couleurTexteGlobale),
    titleSmall: TextStyle(color: couleurTexteGlobale),
    labelLarge: TextStyle(color: couleurTexteGlobale),
    labelMedium: TextStyle(color: couleurTexteGlobale),
    labelSmall: TextStyle(color: couleurTexteGlobale),
    headlineMedium: TextStyle(
      color: couleurTexteGlobale,
      fontSize: 26,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.6,
    ),
  ),
);

/// DrawerHeader amélioré

final Widget themedDrawerHeader = const DrawerHeader(
  decoration: BoxDecoration(
    color: bleuProfond,
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 6,
        offset: Offset(0, 3),
      ),
    ],
  ),
  child: Align(
    alignment: Alignment.bottomLeft,
    child: Text(
      'Menu Super Admin',
      style: TextStyle(
        color: Colors.white,
        fontSize: 26,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.7,
      ),
    ),
  ),
);
