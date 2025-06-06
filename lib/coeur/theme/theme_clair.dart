import 'package:flutter/material.dart';

const Color bleuProfond = Color.fromARGB(255, 25, 49, 82);

final ThemeData themeClair = ThemeData(
  brightness: Brightness.light,
  primaryColor: bleuProfond,
  scaffoldBackgroundColor: Colors.white,

  // Thème AppBar
  appBarTheme: const AppBarTheme(
    backgroundColor: bleuProfond,
    foregroundColor: Colors.white,
    elevation: 1,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(
      color: Colors.white,
      size: 24,
    ),
  ),

  // Thème Drawer
  drawerTheme: const DrawerThemeData(
    backgroundColor: Colors.white, // Corps du Drawer
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
    ),
    scrimColor: Color.fromARGB(100, 25, 49, 82), // Arrière-plan semi-transparent
  ),

  // Thème ElevatedButton
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: bleuProfond,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),

  // Thème TextButton
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: bleuProfond,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),

  // Thème FloatingActionButton
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: bleuProfond,
    foregroundColor: Colors.white,
    elevation: 4,
  ),

  // Thème BottomNavigationBar
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: bleuProfond,
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white54,
    showSelectedLabels: true,
    showUnselectedLabels: false,
    selectedIconTheme: IconThemeData(size: 28),
    unselectedIconTheme: IconThemeData(size: 24),
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    
  ),

  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: bleuProfond,
    selectedIconTheme: IconThemeData(size: 32, color: Colors.white), // Icône plus grande
    unselectedIconTheme: IconThemeData(size: 24, color: Colors.white54),
    selectedLabelTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
    unselectedLabelTextStyle: TextStyle(color: Colors.white54),
    indicatorColor: Colors.black, // Arrière-plan plus visible autour de l’icône sélectionnée
    minWidth: 150,
  ),


  // Thème texte
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black87),
  ),
);

/// Thème DrawerHeader à utiliser dans le widget Drawer

final Widget themedDrawerHeader = const DrawerHeader(
  decoration: BoxDecoration(
    color: bleuProfond,
  ),
  child: Text(
    'Menu Super Admin',
    style: TextStyle(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  ),
);