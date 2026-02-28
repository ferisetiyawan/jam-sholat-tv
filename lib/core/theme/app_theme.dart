import 'package:flutter/material.dart';

class AppTheme {
  // main colors
  static const Color primaryColor = Colors.greenAccent;
  static const Color backgroundColor = Colors.black;
  static const Color cardColor = Color.fromARGB(255, 30, 30, 30);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Roboto',

      // default text theme for the app
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 110,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
      ),

      // default icon theme for the app
      iconTheme: const IconThemeData(color: primaryColor),
    );
  }
}
