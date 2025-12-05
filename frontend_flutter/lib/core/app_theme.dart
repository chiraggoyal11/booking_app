import 'package:flutter/material.dart';

final appTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.deepPurpleAccent,
  scaffoldBackgroundColor: const Color(0xFF050816),
  cardColor: const Color(0xFF020617),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurpleAccent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
    ),
  ),
  textTheme: const TextTheme(
    headline6: TextStyle(fontWeight: FontWeight.w600),
    bodyText2: TextStyle(color: Colors.white70),
  ),
);
