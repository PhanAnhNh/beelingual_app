import 'package:flutter/material.dart';

class AppTheme {
  static const Color textDark = Color(0xFF4E342E);

  static const Gradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFE082),
      Color(0xFFFFFDE7),
    ],
  );

  static const List<Gradient> cardGradients = [
    LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFFF9C4)]), // Vocabulary
    LinearGradient(colors: [Color(0xFFAED581), Color(0xFFE8F5E9)]), // Grammar
    LinearGradient(colors: [Color(0xFF81D4FA), Color(0xFFE1F5FE)]), // Translation
    LinearGradient(colors: [Color(0xFFFFAB91), Color(0xFFFBE9E7)]), // Listening
  ];
}
